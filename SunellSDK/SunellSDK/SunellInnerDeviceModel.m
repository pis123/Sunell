//
//  SunellInnerDeviceModel.m
//  SunellSDK
//
//  Created by Sunell on 2026/3/26.
//

#import "SunellInnerDeviceModel.h"

@implementation SunellInnerDeviceModel
- (instancetype)init{
    if (self = [super init]) {
        self.playerHandleDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)savePlayeHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId playhandle:(int)playHandle{
    NSString *keyValue = [NSString stringWithFormat:@"%@%d",deviceId,channelId];
    self.playerHandleDictionary[keyValue] = @(playHandle);
    
}
- (int)getPlayHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId{
    NSString *keyValue = [NSString stringWithFormat:@"%@%d",deviceId,channelId];
    return  [self.playerHandleDictionary[keyValue] intValue];
}
@end
