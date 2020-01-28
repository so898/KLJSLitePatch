//
//  TestObject.m
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/27.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import "TestObject.h"

@interface TestObject()

@end

@implementation TestObject

- (NSString *)returnValue
{
    return @"ABC";
}

- (NSInteger)returnFunction:(NSInteger)input
{
    return input + 12;
}

- (NSString *)returnString:(NSString *)string
{
    return [NSString stringWithFormat:@"[%@]", string];
}

- (void)pubInvFunc
{
    NSLog(@"OLD - pubInvFunc");
}

+ (void)pubClsFunc
{
    NSLog(@"OLD - pubClsFunc");
}

- (void)priInvFunc
{
    NSLog(@"OLD - priInvFunc");
}

+ (void)priClsFunc
{
    NSLog(@"OLD - priClsFunc");
}

- (void)pubInvFuncWithParam:(NSString *)string
{
    NSLog(@"OLD - pubInvFuncWithParam: - %@", string);
}

- (void)pubInvFuncWithParam:(NSString *)string integer:(NSInteger)integer
{
    NSLog(@"OLD - pubInvFuncWithParam:integer: - %@ - %ld", string, integer);
    NSLog(@"OLD - INTERNAL: - %@", self.string);
}

+ (void)pubClsFuncWithParam:(NSString *)string
{
    NSLog(@"OLD - pubClsFuncWithParam: - %@", string);
}

+ (void)pubClsFuncWithParam:(NSString *)string integer:(NSInteger)integer
{
    NSLog(@"OLD - pubClsFuncWithParam:integer: - %@ - %ld", string, integer);
}

@end
