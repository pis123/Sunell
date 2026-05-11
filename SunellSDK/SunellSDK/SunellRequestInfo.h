//
//  SunellRequestInfo.h
//  SunellSDK
//
//  Created by Sunell on 2026/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : int {
    SunellRequestType_openLive,
    SunellRequestType_openPlayback,
    SunellRequestType_openTalk
} SunellRequestType;
@interface SunellRequestInfo : NSObject
/**
 * Device:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec
 */
@property(nonatomic,assign)SunellRequestType requestType;
@property(nonatomic,strong)NSString *deviceId;
@property(nonatomic,assign)int channelId;
@property(nonatomic,assign)int streamType;
@property(nonatomic,assign)bool isHwDec;
@property(nonatomic,strong)NSString *key;
@property(nonatomic,assign)BOOL isNotiback;
- (NSString*)getSunellRequestKey;
@end

NS_ASSUME_NONNULL_END
