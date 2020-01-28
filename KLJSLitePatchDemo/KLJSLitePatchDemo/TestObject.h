//
//  TestObject.h
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/27.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestObject : NSObject

@property (nonatomic, strong) NSString *string;

- (NSString *)returnValue;

- (NSInteger)returnFunction:(NSInteger)input;

- (NSString *)returnString:(NSString *)string;

- (void)pubInvFunc;

+ (void)pubClsFunc;

- (void)pubInvFuncWithParam:(NSString *)string;

- (void)pubInvFuncWithParam:(NSString *)string integer:(NSInteger)integer;

+ (void)pubClsFuncWithParam:(NSString *)string;

+ (void)pubClsFuncWithParam:(NSString *)string integer:(NSInteger)integer;

@end

NS_ASSUME_NONNULL_END
