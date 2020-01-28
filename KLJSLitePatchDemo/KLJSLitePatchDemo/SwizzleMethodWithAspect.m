//
//  SwizzleMethodWithAspect.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/28.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "SwizzleMethodWithAspect.h"
#import "Aspects.h"
#import <objc/runtime.h>

@implementation SwizzleMethodWithAspect

- (void)swizzleClass:(NSString *)className originMethodOptions:(KLOriginMethodOptions)option isClassMethod:(BOOL)isClassMethod selectorName:(NSString *)selectorName replaceBlock:(KLJSLPSwizzleBlock)funcBlock
{
    Class cls = NSClassFromString(className);
    if (isClassMethod) {
        cls = object_getClass(cls);
    }
    
    SEL sel = NSSelectorFromString(selectorName);
    
    [cls aspect_hookSelector:sel withOptions:(AspectOptions)option usingBlock:^(id<AspectInfo> aspectInfo){
        id ret = funcBlock(aspectInfo.instance, aspectInfo.originalInvocation, aspectInfo.arguments);
        if (ret){
            [aspectInfo.originalInvocation setReturnValue:&ret];
        }
    } error:nil];
}

@end
