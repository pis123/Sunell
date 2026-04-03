//
//  SunellInnerDeviceModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/26.
//

#import <SunellSDK/SunellSDK.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * Internal helper for SDK state; not part of public API.
 */
@class SunellDeviceModel;
@interface SunellInnerDeviceModel : NSObject
@property(nonatomic,assign)int connectHandle;
@property(nonatomic,strong)NSMutableDictionary *playerHandleDictionary;
@property(nonatomic,strong)SunellDeviceModel *deviceModel;
- (void)savePlayeHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId playhandle:(int)playHandle;
- (int)getPlayHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId;
@end

NS_ASSUME_NONNULL_END
