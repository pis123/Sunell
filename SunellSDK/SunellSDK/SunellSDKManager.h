//
//  SunellSDKManager.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    SunellSpeed_1,    // 1倍
    SunellSpeed_2,    // 2倍
}SunellSpeedType;

@class SunellDeviceModel,SunellChannelModel;

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
// device channel online /offline
- (void)sunellSDKChannelStatusChangeNotiWithChannelModel:(SunellChannelModel*)channelModel;
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
+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId;
+ (void)stopDeviceChannelStatusMonitoring:(NSString*)deviceId;
/**
 * Alarm monitoring (optional).
 */
//+ (void)startDeviceChannelAlarmMonitoring:(NSString*)deviceId;
//+ (void)stopDeviceChannelAlarmMonitoring:(NSString *)deviceId;

/**
 * capture
 */
+ (void)captureImageWithDeviceId:(NSString*)deviceId channelId:(int)channelId path:(NSString*)path resultBlock:(void(^)(int result))resultBlock;
/**
 * switch audio
 */
+ (void)audioSwitchWithDeviceId:(NSString*)deviceId channelId:(int)channelId isOpen:(BOOL)isOpen resultBlock:(void(^)(int result))resultBlock;
/**
 * switch talk
 */
+ (void)talkSwitchWithDeviceId:(NSString*)deviceId channelId:(int)channelId isOpen:(BOOL)isOpen resultBlock:(void(^)(int result))resultBlock;
/**
 * SD / HD Switch
 * qualityType: 1  HD
 * qualityType: 2  SD
 */
+ (void)qualityAdjustmentWithDeviceId:(NSString*)deviceId channelId:(int)channelId type:(int)qualityType resultBlock:(void(^)(int result))resultBlock;
/**
 * 获取设备能力
 * ptz能力
 * 对讲能力
 */
+ (void)getDeviceCapacityWithDeviceId:(NSString*)deviceId channelId:(int)channelId reulstBlock:(void (^)(int result, SunellChannelModel * _Nullable channelModel))resultBlock;

/**
 * 打开ptz
 */
+ (void)openPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;
/**
 * 关闭ptz
 */
+ (void)closePTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

/**
 * operation PTZ
 * arrowType:
 * PTZ_UP = 1,        //向上
   PTZ_DOWN = 2,      //向下
   PTZ_LEFT = 3,      //左
   PTZ_RIGHT = 4,     //右
   PTZ_LEFT_UP = 5,   //左上
   PTZ_LEFT_DOWN = 6, //左下
   PTZ_RIGHT_UP = 7,  //右上
   PTZ_RIGHT_DOWN = 8, //右下
 */
+ (void)operationPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId arrowType:(int)arrowType resultBlock:(void(^)(int result))resultBlock;

+ (void)stopPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

/**
 * 获取白光灯能力
 */
+ (void)getWhiteLightAbilityWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString* _Nullable jsonStr))resultBlock;

/// 读取白光灯当前参数（JSON 字符串，由设备定义）。
+ (void)getWhiteLightSwitchParamWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result, NSString * _Nullable jsonStr))resultBlock;
/// 下发白光灯参数 JSON（方法名避免 `set` 前缀，否则 Swift 会按属性 setter 导入导致无对应成员）。
+ (void)applyWhiteLightSwitchParamWithDeviceId:(NSString*)deviceId channelId:(int)channelId paramJson:(NSString*)paramJson resultBlock:(void(^)(int result))resultBlock;
// 获取报警音频数据
+ (void)getAudioAlarmInfoWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString * _Nullable jsonStr))resultBlock;
/**
 * displayId：音频id (+ (void)getAudioAlarmInfoWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString * _Nullable jsonStr))resultBlock)中获取
 * playNum:播放几次，0无限播放
 *
 */
+ (void)playAudioAlarmWithDeviceId:(NSString*)deviceId channelId:(int)channelId displayId:(int)displayId playNum:(int)playNum resultBlock:(void(^)(int result))resultBlock;

// 打开回放
+ (void)playbackStartWithDeviceId:(NSString*)deviceId channelId:(int)channelId startTimeStr:(NSString*)startTimeStr streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(void(^)(int result))resultBlock;
// 关闭回放
+ (void)playBackStopWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

// 暂停回放
+ (void)playBackPauseWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

// 继续回放
+ (void)playBackResumeWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

// seek
+ (void)playBackSeekWithDeviceId:(NSString*)deviceId channelId:(int)channelId startTimeStr:(NSString*)startTimeStr resultBlock:(void(^)(int result))resultBlock;

// speed
+ (void)playBackSetSpeedWithDeviceId:(NSString*)deviceId channelId:(int)channelId speed:(SunellSpeedType)speedType resultBlock:(void(^)(int result))resultBlock;

// 获取某天的回放记录
+ (void)getPlayBackOneDayRecordListWithDeviceId:(NSString*)deviceId channelId:(int)channelId dayStr:(NSString*)dayStr resultBlock:(void(^)(int result,NSString * jsonStr))resultBlock;
// 获取某段时间内的回放记录
+ (void)getPlayBackRecordWithinACertainPeriodOfTimeWithDeviceId:(NSString*)deviceId channelId:(int)channelId startDateStr:(NSString*)startDateStr endDateStr:(NSString*)endDateStr resultBlock:(void(^)(int result,NSString * jsonStr))resultBlock;
// 获取时间段内那些day有回放记录
+ (void)getWhichDaysWithinTheTimePeriodHavePlaybackRecordsWithDeviceId:(NSString*)deviceId channelId:(int)channelId startDayStr:(NSString*)startDayStr endDayStr:(NSString*)endDayStr resultBlock:(void(^)(int result,NSString* jsonStr))resultBlock;
+ (void)closeGL;
@end

NS_ASSUME_NONNULL_END
