//
//  SunellSafeUtil.m
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import "SunellSafeUtil.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SunellSafeUtil
+ (NSString *)safeStringFromCString:(const char *)cStr {
    if (cStr == NULL) return nil;
    
    size_t len = strnlen(cStr, 1024);
    if (len == 0 || len >= 1024) return nil;
    
    NSString *str = [[NSString alloc] initWithBytes:cStr
                                             length:len
                                           encoding:NSUTF8StringEncoding];
    return str;
}
@end

NS_ASSUME_NONNULL_END
