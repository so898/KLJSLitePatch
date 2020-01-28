//
//  SwizzleMethodWithStinger.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/28.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "SwizzleMethodWithStinger.h"
#import "Stinger.h"
#import <objc/runtime.h>

@implementation SwizzleMethodWithStinger

- (void)swizzleClass:(NSString *)className originMethodOptions:(KLOriginMethodOptions)option isClassMethod:(BOOL)isClassMethod selectorName:(NSString *)selectorName replaceBlock:(KLJSLPSwizzleBlock)funcBlock
{
    Class cls = NSClassFromString(className);
    if (isClassMethod) {
        cls = object_getClass(cls);
    }
    SEL sel = NSSelectorFromString(selectorName);
    
    // I think Stinger process paramaters in the wrong way, I have no idea how to fix this block with Stinger
    // However, according to Eleme team, Stinger is much more faster than Aspests
    // I try to implement this function here just for speed test ^_^
    [cls st_hookClassMethod:sel option:(STOption)option usingIdentifier:[NSString stringWithFormat:@"hook_%@_%@_%ld", className, selectorName, (long)option] withBlock:^(id<StingerParams> params) {
        id ret = funcBlock(params.slf, nil, nil);
        return ret;
    }];
}

@end
