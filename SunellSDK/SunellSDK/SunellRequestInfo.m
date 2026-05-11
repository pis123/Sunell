//
//  SunellRequestInfo.m
//  SunellSDK
//
//  Created by Sunell on 2026/4/24.
//

#import "SunellRequestInfo.h"

@implementation SunellRequestInfo
- (NSString*)getSunellRequestKey{
    NSString *str = [NSString stringWithFormat:@"%@_%d_%d_%d_%d",self.deviceId,self.channelId,self.requestType,self.isHwDec,self.streamType];
    return str;
}
- (NSString *)key{
    return [self getSunellRequestKey];
}
@end
