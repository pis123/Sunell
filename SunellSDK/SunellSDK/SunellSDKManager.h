//
//  SunellSDKManager.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class SunellDeviceModel;

@protocol SunellSDKManagerDelegate <NSObject>
@optional;
// Device error / offline callback.
- (void)sunellSDKDeviceErrorStatus:(SunellDeviceModel*)deviceModel type:(int)type;
// Auto reconnect started after abnormal disconnect.
- (void)sunellSDKStartAutoReconnect:(SunellDeviceModel*)deviceModel;
// Auto reconnect finished.
- (void)sunellSDKEndtAutoReconnect:(SunellDeviceModel *)deviceModel isSuccess:(BOOL)isSuccess;
// Alarm payload.
- (void)sunellSDKAlarmInfo:(SunellDeviceModel*)deviceModel alarmInfo:(NSString*)alarmInfo;
// Video operation callback.
- (void)sunellSDKVideoOperation:(NSString*)deviceId channelId:(int)channelId eventId:(int)eventId msg:(NSString*)msg playModel:(int)playModel;

@end

@interface SunellSDKManager : NSObject
@property(nonatomic,weak)id<SunellSDKManagerDelegate>delegate;
+ (instancetype)shared;

/**
 * P2P connect result code.
 * result >= 1000: success.
 * result == -507: wrong username.
 * result == -508: wrong password.
 */
+ (void)connectDevByP2P:(NSString *)uuid port:(int)port user:(NSString *)user pwd:(NSString *)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock;

/**
 * Connect by IP / host.
 */
+ (void)connectDevByIP:(NSString*)ip port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock;
/**
 * Disconnect device.
 */
+ (void)disConnectDevByDeviceId:(NSString*)deviceId;
/**
 * Start live preview.
 * Return value > 0 usually means success (stream id per native SDK).
 */
+ (void)liveStartWithDevice:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(void(^)(int result))resultBlock;
/**
 * Stop live preview.
 */
+ (void)liveStopWithDevice:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;
/**
 * Channel online/offline monitoring (optional).
 */
//+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId;
//+ (void)stopDeviceChannelStatusMonitoring:(NSString*)deviceId;
/**
 * Alarm monitoring (optional).
 */
//+ (void)startDeviceChannelAlarmMonitoring:(NSString*)deviceId;
//+ (void)stopDeviceChannelAlarmMonitoring:(NSString *)deviceId;
+ (void)closeGL;
@end

NS_ASSUME_NONNULL_END
