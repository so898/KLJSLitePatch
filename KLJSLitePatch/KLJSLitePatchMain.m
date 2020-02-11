//
//  KLJSLitePatchMain.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/27.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "KLJSLitePatchMain.h"
#import <objc/runtime.h>
#import "KLJSLitePatchDefaultLogger.h"
#if (KLMAXSAFE == 0)
#import "KLJSLitePatchDefaultSwizzler.h"
#endif

@implementation KLJSLitePatchMain

static JSContext *_JSContext;
static NSString *_regexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static NSString *_replaceStr = @".__c(\"$1\")(";
static NSRegularExpression* _regex;
static NSRegularExpression *countArgRegex;
static NSRecursiveLock     *_JSMethodForwardCallLock;

static id<KLJSLitePatchLogProtocol> logInstance;
static void _KLJSAssert(BOOL condition, NSString *msg) {
    if (!logInstance){
        logInstance = [KLJSLitePatchDefaultLogger new];
    }
    [logInstance assert:condition msg:msg];
}
static void _KLJSLog(NSString *msg) {
    if (!logInstance){
        logInstance = [KLJSLitePatchDefaultLogger new];
    }
    [logInstance log:msg];
}

static id<KLJSLitePatchScriptProtocol> scriptInstance;
static id<KLJSLitePatchMethodSwizzleProtocol> swizzleInstance;

+ (void)registerLogInstance:(id<KLJSLitePatchLogProtocol>)instance
{
    logInstance = instance;
}

+ (void)registerScriptInstance:(id<KLJSLitePatchScriptProtocol>)instance
{
    scriptInstance = instance;
}

+ (void)registerSwizzleInstance:(id<KLJSLitePatchMethodSwizzleProtocol>)instance
{
    swizzleInstance = instance;
}

+ (void)injectJSFunc
{
    if (![JSContext class] || _JSContext) {
        return;
    }
    
    JSContext *context = [[JSContext alloc] init];
    
    context[@"_OC_hasClass"] = ^(NSString *className) {
        NSDictionary *dic = @{@"has": @(NSClassFromString(className) != nil)};
        return dic;
    };
    
    context[@"_OC_fixMethod"] = ^(NSString *classDeclaration, JSValue *option, JSValue *instanceMethods, JSValue *classMethods) {
        
        for (int i = 0; i < 2; i ++) {
            BOOL isInstance = i == 0;
            JSValue *jsMethods = isInstance ? instanceMethods: classMethods;
            
            NSDictionary *methodDict = [jsMethods toDictionary];
            
            for (NSString *jsMethodName in methodDict.allKeys) {
                JSValue *jsMethodArr = [jsMethods valueForProperty:jsMethodName];
                int numberOfArg = [jsMethodArr[0] toInt32];
                
                NSString *tmpJSMethodName = [jsMethodName stringByReplacingOccurrencesOfString:@"__" withString:@"-"];
                NSString *selectorName = [tmpJSMethodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
                selectorName = [selectorName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
                
                if (!countArgRegex) {
                    countArgRegex = [NSRegularExpression regularExpressionWithPattern:@":" options:NSRegularExpressionCaseInsensitive error:nil];
                }
                NSUInteger numberOfMatches = [countArgRegex numberOfMatchesInString:selectorName options:0 range:NSMakeRange(0, [selectorName length])];
                if (numberOfMatches < numberOfArg) {
                    selectorName = [selectorName stringByAppendingString:@":"];
                }
                
                JSValue *jsMethod = jsMethodArr[1];
                
                [self _fixWithInstance:classDeclaration originMethodOptions:option.toInt32 isClassMethod:!isInstance selectorName:selectorName fixImpl:jsMethod];
            }
        }
        
        return @{@"cls": classDeclaration};
    };
    
    context[@"_OC_callMethod"] = ^(id instance, NSString *methodName, NSArray *args) {
        return [self _callMethodOf:instance methodName:methodName args:args];
    };
    
    context[@"_OC_invoke"] = ^(NSInvocation *invocation) {
        [invocation invoke];
    };
    
    context[@"_OC_catch"] = ^(JSValue *msg, JSValue *stack) {
        _KLJSAssert(NO, [NSString stringWithFormat:@"js exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]]);
    };
    
    context[@"_OC_error"] = ^(JSValue *msg) {
        _KLJSAssert(NO, [NSString stringWithFormat:@"js exception, \nmsg: %@", [msg toObject]]);
    };
    
    context[@"_OC_print"] = ^(JSValue *msg) {
        _KLJSLog([NSString stringWithFormat:@"Javascript log: %@", [msg toObject]]);
    };
    
    _JSContext = context;
    
    _JSMethodForwardCallLock = [[NSRecursiveLock alloc] init];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"KLJSLitePatch" ofType:@"js"];
    _KLJSAssert(path != nil, @"can't find KLJSLitePatch.js");
    NSString *jsCore = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:path] encoding:NSUTF8StringEncoding];
    
    if ([_JSContext respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
        [_JSContext evaluateScript:jsCore withSourceURL:[NSURL URLWithString:@"KLJSLitePatch.js"]];
    } else {
        [_JSContext evaluateScript:jsCore];
    }
}

+ (JSValue *)evaluateScript:(NSString *)script
{
    return [self evaluateScript:script withSourceURL:[NSURL URLWithString:@"main.js"]];
}

+ (JSValue *)evaluateScriptWithPath:(NSString *)filePath
{
    NSArray *components = [filePath componentsSeparatedByString:@"/"];
    NSString *fileName = [components lastObject];
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    return [self evaluateScript:script withSourceURL:[NSURL URLWithString:fileName]];
}

#pragma mark - Private Functions

+ (JSValue *)evaluateScript:(NSString *)script withSourceURL:(NSURL *)resourceURL
{
    if (!script || ![JSContext class]) {
        _KLJSAssert(NO, @"Script is nil");
        return nil;
    }
    
    NSString *scriptString;
    if (scriptInstance){
        if (![scriptInstance scriptVerify:script]){
            _KLJSAssert(NO, @"Script verify fail");
            return nil;
        }
        scriptString = [scriptInstance scriptDecode:script];
    } else {
        scriptString = script;
    }
    
    if (!_regex) {
        _regex = [NSRegularExpression regularExpressionWithPattern:_regexStr options:0 error:nil];
    }
    NSString *formatedScript = [NSString stringWithFormat:@"try{%@}catch(e){_OC_catch(e.message, e.stack)}", [_regex stringByReplacingMatchesInString:scriptString options:0 range:NSMakeRange(0, scriptString.length) withTemplate:_replaceStr]];
    @try {
        if ([_JSContext respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
            return [_JSContext evaluateScript:formatedScript withSourceURL:resourceURL];
        } else {
            return [_JSContext evaluateScript:formatedScript];
        }
    }
    @catch (NSException *exception) {
        _KLJSAssert(NO, [NSString stringWithFormat:@"Regex exception: %@", exception]);
    }
    return nil;
}

+ (void)_fixWithInstance:(NSString *)instanceName originMethodOptions:(KLOriginMethodOptions)option isClassMethod:(BOOL)isClassMethod selectorName:(NSString *)selectorName fixImpl:(JSValue *)fixImpl {
#if (KLMAXSAFE == 0)
    if (!swizzleInstance){
        swizzleInstance = [KLJSLitePatchDefaultSwizzler new];
    }
#else
    if (!swizzleInstance){
        _KLJSAssert(NO, @"No swizzle method");
        return;
    }
#endif
    [swizzleInstance swizzleClass:instanceName originMethodOptions:option isClassMethod:isClassMethod selectorName:selectorName replaceBlock:^id(id instance, NSInvocation *invocation, NSArray *arguments) {
        NSMutableArray *args = [NSMutableArray new];
        [args addObject:(instance ? instance : @(0))];
        [args addObject:(invocation ? invocation : @(0))];
        [args addObject:(arguments ? arguments : @(0))];
        
        [_JSMethodForwardCallLock lock];
        id val = [fixImpl callWithArguments:args];
        [_JSMethodForwardCallLock unlock];
        
        id result = [val toObject];
        if (result == [NSNull null]
            || ([result isKindOfClass:[NSNumber class]] && strcmp([result objCType], "c") == 0 && ![result boolValue])){
            result = nil;
        }
        return result;
    }];
}

+ (id)_callMethodOf:(id)instance methodName:(NSString *)jsMethodName args:(NSArray *)args
{
    Class cls = [instance class];
        
    NSInteger numberOfArg = [args count];
    
    if (numberOfArg > 2){
        _KLJSAssert(NO, @"No support for function which paramaters is more than 2");
        return nil;
    }
    
    NSString *tmpJSMethodName = [jsMethodName stringByReplacingOccurrencesOfString:@"__" withString:@"-"];
    NSString *selectorName = [tmpJSMethodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    selectorName = [selectorName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    
    if (!countArgRegex) {
        countArgRegex = [NSRegularExpression regularExpressionWithPattern:@":" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    NSUInteger numberOfMatches = [countArgRegex numberOfMatchesInString:selectorName options:0 range:NSMakeRange(0, [selectorName length])];
    if (numberOfMatches < numberOfArg) {
        selectorName = [selectorName stringByAppendingString:@":"];
    }
    
    SEL selector = NSSelectorFromString(selectorName);
    id ret = nil;
    if (instance && [instance respondsToSelector:selector]){
        id arg1 = nil, arg2 = nil;
        for (int i = 0 ; i < numberOfArg ; i ++){
            id arg = args[i];
            (i == 0 ? (arg1 = arg) : (arg2 = arg));
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        @try {
            ret = [instance performSelector:selector withObject:arg1 withObject:arg2];
        }
        @catch (NSException *exception) {
            _KLJSAssert(NO, [NSString stringWithFormat:@"PerfromSelector exception: %@", exception]);
            return nil;
        }
#pragma clang diagnostic pop
    } else {
        _KLJSLog([NSString stringWithFormat:@"%@ of %@ not found", selectorName, NSStringFromClass(cls)]);
        return nil;
    }
    
    if ([ret isKindOfClass:[NSObject class]]) {
        if (!ret) {
            return @(0);
        }
        return ret;
    }
    
    return nil;
}

@end
