//
//  AppDelegate.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/27.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "AppDelegate.h"
#import "TestObject.h"

#import "KLJSLitePatchMain.h"
#import "SwizzleMethodWithAspect.h"
#import "SwizzleMethodWithStinger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {    
    // Before Fix
    [[TestObject new] pubInvFuncWithParam:@"test" integer:2];
    TestObject *objc = [TestObject new];
    objc.string = @"test";
    NSLog(@"RR: %@", [objc returnValue]);
    NSLog(@"%ld", (long)[objc returnFunction:2]);
    
    // 1. CHANGE LOGGER
    // You could change Logger of KLJSLitePatch to your own implementation
//    [KLJSLitePatchMain registerLogInstance:[Logger new]];
    
    // 2. CHANGE SWIZZLE METHOD IMPLEMENTATION
    // Swizzle Method Must Be Change Before Injection
    // By default, KLJSLitePatch will use self-implemented swizzle method funtions
    // My functions is based on JSPatch, so I have no idea this implementation could pass App Store Review or not
    // You can use Aspects or Stinger to replace my implementation or do it by yourself
    // If you use your own implementation, plaese change KLMAXSAFE in KLJSLitePatchProtocols.h to 1 before complie
    // KLMAXSAFE will comment my implementation of swizzle method, NO CODE will be cmoplied in your application, so it is very safe for App Store
    
    // This is an example of using Aspect as swizzle method library
//    [KLJSLitePatchMain registerSwizzleInstance:[SwizzleMethodWithAspect new]];
    
    // This is an example of using Stinger as swizzle method library
    // This one is not work with arguments due to API problem, see .m for detail
//    [KLJSLitePatchMain registerSwizzleInstance:[SwizzleMethodWithStinger new]];
    
    // 3. CHANGE SCRIPT VERIFICATION & SCRIPT DECODE
    // If you want to implement your own script verification function and scripte decode function
    // you could register your implementation here
//    [KLJSLitePatchMain registerScriptInstance:[Script new]];
    
    // Inject Fix JS Methods
    [KLJSLitePatchMain injectJSFunc];
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"fix" ofType:@"js"];
    NSAssert(path, @"can't find fix.js");
    [KLJSLitePatchMain evaluateScriptWithPath:path];
    
    // After fix
    [objc pubInvFunc];
    [objc pubInvFuncWithParam:@"test" integer:2];
    NSLog(@"CC: %@", [objc returnValue]);
    [TestObject pubClsFuncWithParam:@"asdas"];
    [objc pubInvFuncWithParam:@"asasdads"];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
