//
//  SunellSafeUtil.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SunellSafeUtil : NSObject
+ (NSString *)safeStringFromCString:(const char *)cStr;
@end

NS_ASSUME_NONNULL_END
