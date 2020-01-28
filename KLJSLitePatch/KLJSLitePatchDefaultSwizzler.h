//
//  KLJSLitePatchDefaultSwizzler.h
//  KLJSLitePatchDemo
//
//  Created by Bill Cheng on 2020/1/28.
//  Copyright © 2020 R3 Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KLJSLitePatchProtocols.h"

#if (KLMAXSAFE == 0)

NS_ASSUME_NONNULL_BEGIN

@interface KLJSLitePatchDefaultSwizzler : NSObject<KLJSLitePatchMethodSwizzleProtocol>

@end

NS_ASSUME_NONNULL_END

#endif
