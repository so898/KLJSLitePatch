//
//  KLJSLitePatchMain.h
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/27.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "KLJSLitePatchProtocols.h"

NS_ASSUME_NONNULL_BEGIN

@interface KLJSLitePatchMain : NSObject

+ (void)registerLogInstance:(id<KLJSLitePatchLogProtocol>)instance;
+ (void)registerScriptInstance:(id<KLJSLitePatchScriptProtocol>)instance;
+ (void)registerSwizzleInstance:(id<KLJSLitePatchMethodSwizzleProtocol>)instance;

+ (void)injectJSFunc;

+ (JSValue *)evaluateScript:(NSString *)script;
+ (JSValue *)evaluateScriptWithPath:(NSString *)filePath;
+ (JSValue *)evaluateScript:(NSString *)script withSourceURL:(NSURL *)resourceURL;

@end

NS_ASSUME_NONNULL_END
