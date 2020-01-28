//
//  KLJSLitePatchDefaultLogger.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/28.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "KLJSLitePatchDefaultLogger.h"

@implementation KLJSLitePatchDefaultLogger

- (void)log:(NSString *)msg
{
    NSLog(@"%@", msg);
}

- (void)assert:(BOOL)condition msg:(NSString *)msg
{
    NSAssert(condition, msg);
}

@end
