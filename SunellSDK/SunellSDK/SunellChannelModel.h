//
//  SunellChannelModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    SunellDeviceCapacityType_normal, // No request interface,or request failed
    SunellDeviceCapacityType_capable,
    SunellDeviceCapacityType_not_capable,
} SunellDeviceCapacityType;
typedef enum : NSInteger {
    SunellDeviceStatus_unknown = 0,
    SunellDeviceStatus_online,
    SunellDeviceStatus_offline
}SunellDeviceStatus;

@interface SunellChannelModel : NSObject
@property(nonatomic,assign)int channelId;
@property(nonatomic,strong)NSString *deviceId;
@property(nonatomic,assign)SunellDeviceStatus status;// 4098: online; 0: no device; other: offline
@property(nonatomic,strong)NSString *channleName;
@property(nonatomic,assign)SunellDeviceCapacityType ptzCapacity;
@property(nonatomic,assign)SunellDeviceCapacityType talkCapacity;
@end

NS_ASSUME_NONNULL_END
