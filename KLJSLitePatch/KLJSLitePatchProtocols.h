//
//  KLJSLitePatchProtocols.h
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/28.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#ifndef KLJSLitePatchProtocol_h
#define KLJSLitePatchProtocol_h

#import <Foundation/Foundation.h>

#ifndef KLMAXSAFE
#define KLMAXSAFE 0
#endif

typedef id (^KLJSLPSwizzleBlock)(id instance, NSInvocation *invocation, NSArray *arguments);

typedef enum : NSUInteger {
    KLOriginMethodAfter = 0, // Called after the original implementation (default)
    KLOriginMethodInstead = 1, // Will replace the original implementation.
    KLOriginMethodBefore = 2, // Called before the original implementation.
} KLOriginMethodOptions;

@protocol KLJSLitePatchLogProtocol <NSObject>

- (void)log:(NSString *)msg;
- (void)assert:(BOOL)condition msg:(NSString *)msg;

@end

@protocol KLJSLitePatchScriptProtocol <NSObject>

- (BOOL)scriptVerify:(NSString *)script;
- (NSString *)scriptDecode:(NSString *)encode;

@end

@protocol KLJSLitePatchMethodSwizzleProtocol <NSObject>

- (void)swizzleClass:(NSString *)className originMethodOptions:(KLOriginMethodOptions)option isClassMethod:(BOOL)isClassMethod selectorName:(NSString *)selectorName replaceBlock:(KLJSLPSwizzleBlock)funcBlock;

@end


#endif /* KLJSLitePatchProtocol_h */
