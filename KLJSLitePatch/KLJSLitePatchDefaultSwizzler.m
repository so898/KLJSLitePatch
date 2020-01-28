//
//  KLJSLitePatchDefaultSwizzler.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/28.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "KLJSLitePatchDefaultSwizzler.h"

#if (KLMAXSAFE == 0)

#import <objc/runtime.h>
#import <objc/message.h>

@implementation KLJSLitePatchDefaultSwizzler

static NSMutableDictionary *_overideMethods;

static void _initOverideMethods(Class cls) {
    if (!_overideMethods) {
        _overideMethods = [[NSMutableDictionary alloc] init];
    }
    if (!_overideMethods[cls]) {
        _overideMethods[(id<NSCopying>)cls] = [[NSMutableDictionary alloc] init];
    }
}

static void JSLPForwardInvocation(id slf, SEL selector, NSInvocation *invocation)
{
    Class cls = object_getClass(slf);
    
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    NSString *newSelectorName = [NSString stringWithFormat:@"_JSLP%@", selectorName];
    SEL newSelector = NSSelectorFromString(newSelectorName);
    
    NSString *originalSelectorName = [NSString stringWithFormat:@"ORIG%@", selectorName];
    SEL originalSelector = NSSelectorFromString(originalSelectorName);
    [invocation setSelector:originalSelector];
    
    NSDictionary *dic = _overideMethods[cls][newSelectorName];
    KLOriginMethodOptions option = (KLOriginMethodOptions)[dic[@"o"] integerValue];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (!class_respondsToSelector(object_getClass(slf), newSelector)) {
        SEL origForwardSelector = @selector(ORIGforwardInvocation:);
        NSMethodSignature *methodSignature = [slf methodSignatureForSelector:origForwardSelector];
        NSInvocation *forwardInv= [NSInvocation invocationWithMethodSignature:methodSignature];
        [forwardInv setTarget:slf];
        [forwardInv setSelector:origForwardSelector];
        [forwardInv setArgument:&invocation atIndex:2];
        [forwardInv invoke];
        return;
    }
#pragma clang diagnostic pop

    if (option == KLOriginMethodBefore){
        [invocation invoke];
    }
    
    NSMutableArray *argList = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        switch(argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
#define JSLP_FWD_ARG_CASE(_typeChar, _type) \
case _typeChar: {   \
_type arg;  \
[invocation getArgument:&arg atIndex:i];    \
[argList addObject:@(arg)]; \
break;  \
}
                JSLP_FWD_ARG_CASE('c', char)
                JSLP_FWD_ARG_CASE('C', unsigned char)
                JSLP_FWD_ARG_CASE('s', short)
                JSLP_FWD_ARG_CASE('S', unsigned short)
                JSLP_FWD_ARG_CASE('i', int)
                JSLP_FWD_ARG_CASE('I', unsigned int)
                JSLP_FWD_ARG_CASE('l', long)
                JSLP_FWD_ARG_CASE('L', unsigned long)
                JSLP_FWD_ARG_CASE('q', long long)
                JSLP_FWD_ARG_CASE('Q', unsigned long long)
                JSLP_FWD_ARG_CASE('f', float)
                JSLP_FWD_ARG_CASE('d', double)
                JSLP_FWD_ARG_CASE('B', BOOL)
            case '@': {
                __unsafe_unretained id arg;
                [invocation getArgument:&arg atIndex:i];
                if ([arg isKindOfClass:NSClassFromString(@"NSBlock")]) {
                    [argList addObject:(arg ? [arg copy]: @(0))];
                } else {
                    [argList addObject:(arg ? arg: @(0))];
                }
                break;
            }
            case '{':
            case ':':
            case '^':
            case '*':
            case '#': {
                [argList addObject:@(0)];
                break;
            }
            default: {
                NSLog(@"error type %s", argumentType);
                break;
            }
        }
    }
    
    const char *returnType = [methodSignature methodReturnType];
    
    switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
#define JSLP_FWD_RET_CALL_BLOCK \
KLJSLPSwizzleBlock funcBlock = dic[@"f"];\
id result = funcBlock(slf, invocation, argList);

#define JSLP_FWD_RET_CASE_RET(_typeChar, _type, _retCode)   \
case _typeChar : { \
JSLP_FWD_RET_CALL_BLOCK \
_retCode\
[invocation setReturnValue:&ret];\
break;  \
}
            
#define JP_FWD_RET_CODE_ID \
id ret = result;
            
#define JSLP_FWD_STRING_RET_CASE(_typeChar, _type, _typeSelector)   \
JSLP_FWD_RET_CASE_RET(_typeChar, _type, _type ret = *[(NSString *)result _typeSelector];) \

#define JSLP_FWD_NUM_RET_CASE(_typeChar, _type, _typeSelector)   \
JSLP_FWD_RET_CASE_RET(_typeChar, _type, _type ret = [(NSNumber *)result _typeSelector];) \
            
            JSLP_FWD_RET_CASE_RET('@', id, JP_FWD_RET_CODE_ID)
            JSLP_FWD_STRING_RET_CASE('c', char, UTF8String)
            JSLP_FWD_STRING_RET_CASE('C', unsigned char, UTF8String)
            JSLP_FWD_NUM_RET_CASE('s', short, shortValue)
            JSLP_FWD_NUM_RET_CASE('S', unsigned short, unsignedShortValue)
            JSLP_FWD_NUM_RET_CASE('i', int, intValue)
            JSLP_FWD_NUM_RET_CASE('I', unsigned int, unsignedIntValue)
            JSLP_FWD_NUM_RET_CASE('l', long, longValue)
            JSLP_FWD_NUM_RET_CASE('L', unsigned long, unsignedLongValue)
            JSLP_FWD_NUM_RET_CASE('q', long long, longLongValue)
            JSLP_FWD_NUM_RET_CASE('Q', unsigned long long, unsignedLongLongValue)
            JSLP_FWD_NUM_RET_CASE('f', float, floatValue)
            JSLP_FWD_NUM_RET_CASE('d', double, doubleValue)
            JSLP_FWD_NUM_RET_CASE('B', BOOL, boolValue)
            
        case '^':
        case '*':
        case '#':
        case ':':
        case 'v':
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
            JSLP_FWD_RET_CALL_BLOCK
#pragma clang diagnostic pop
            break;
        }
    }
    
    if (option == KLOriginMethodAfter) {
        [invocation invoke];
    }
}

- (void)swizzleClass:(NSString *)className originMethodOptions:(KLOriginMethodOptions)option isClassMethod:(BOOL)isClassMethod selectorName:(NSString *)selectorName replaceBlock:(KLJSLPSwizzleBlock)funcBlock
{
    Class cls = isClassMethod ? objc_getMetaClass(className.UTF8String) : NSClassFromString(className);
    
    SEL selector = NSSelectorFromString(selectorName);
    
    Method method = class_getInstanceMethod(cls, selector);
    char *typeDescription = (char *)method_getTypeEncoding(method);
    
    IMP originalImp = class_respondsToSelector(cls, selector) ? class_getMethodImplementation(cls, selector) : NULL;
    
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    if (typeDescription[0] == '{') {
        //In some cases that returns struct, we should use the '_stret' API:
        //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
        //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeDescription];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    
    class_replaceMethod(cls, selector, msgForwardIMP, typeDescription);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (class_getMethodImplementation(cls, @selector(forwardInvocation:)) != (IMP)JSLPForwardInvocation) {
        IMP originalForwardImp = class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)JSLPForwardInvocation, "v@:@");
        class_addMethod(cls, @selector(ORIGforwardInvocation:), originalForwardImp, "v@:@");
    }
#pragma clang diagnostic pop
    
    if (class_respondsToSelector(cls, selector)) {
        NSString *originalSelectorName = [NSString stringWithFormat:@"ORIG%@", selectorName];
        SEL originalSelector = NSSelectorFromString(originalSelectorName);
        if(!class_respondsToSelector(cls, originalSelector)) {
            class_addMethod(cls, originalSelector, originalImp, typeDescription);
        }
    }
    
    NSString *newSelectorName = [NSString stringWithFormat:@"_JSLP%@", selectorName];
    SEL newSelector = NSSelectorFromString(newSelectorName);
    
    _initOverideMethods(cls);
    _overideMethods[cls][newSelectorName] = @{@"f": funcBlock, @"o":@(option)};

    class_addMethod(cls, newSelector, msgForwardIMP, typeDescription);
}

@end

#endif
