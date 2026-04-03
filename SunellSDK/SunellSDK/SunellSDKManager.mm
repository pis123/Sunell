//
//  SunellSDKManager.m
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import "SunellSDKManager.h"
#import "P2PManager.h"
#import "Sunell.h"
#import <stdlib.h>
#import "SunellSafeUtil.h"
#import "SunellDeviceModel.h"
#import "SunellChannelModel.h"
#import "SunellInnerDeviceModel.h"
NS_ASSUME_NONNULL_BEGIN
@interface SunellSDKManager()
@property(nonatomic,strong)NSMutableDictionary *handleDict;
@end
@implementation SunellSDKManager

#define HandleMinValue 1000

+ (instancetype)shared{
    static SunellSDKManager *sdkmgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sdkmgr = [[SunellSDKManager alloc]init];
        sdkmgr.handleDict = [NSMutableDictionary dictionary];
    });
    sdks_dev_init(NULL);
    return sdkmgr;
}
+ (SunellInnerDeviceModel*)getInnerDeviceModelByDeviceId:(NSString*)deviceId{
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    return dict[deviceId];
}

+ (int)getConnectHandleByDeviceId:(NSString*)deviceId{
    return [self getInnerDeviceModelByDeviceId:deviceId].connectHandle;
}
// Store connection handle after device login.
+ (void)addHandle:(int)handel device:(SunellDeviceModel*)deviceModel{
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    if ([self getConnectHandleByDeviceId:deviceModel.deviceId]) { // Replace if already connected.
        SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceModel.deviceId];
        innerDeviceModle.connectHandle = handel;
        innerDeviceModle.deviceModel = deviceModel;
        dict[deviceModel.deviceId] = innerDeviceModle;
    }else { // New device entry.
        SunellInnerDeviceModel *innerDeviceModle = [[SunellInnerDeviceModel alloc]init];
        innerDeviceModle.deviceModel = deviceModel;
        innerDeviceModle.connectHandle = handel;
        dict[deviceModel.deviceId] = innerDeviceModle;
    }
    
}
// Update cached connect handle.
+ (void)updateHandel:(int)handle deviceId:(NSString*)deviceId{
    SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceId];
    innerDeviceModle.connectHandle = handle;
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    dict[deviceId] = innerDeviceModle;
}
// Remove cached handle.
+ (void)removeHandleWithdeviceId:(NSString*)deviceId{
    SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceId];
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    [dict removeObjectForKey:deviceId];
    [SunellSDKManager shared].handleDict = dict;
}
// Store playback stream handle.
+ (void)addPlayerHandle:(int)playHandle deviceId:(NSString*)deviceId channelId:(int)channelId{
    SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceId];
    [innerDeviceModle savePlayeHandleByDeviceId:deviceId channelId:channelId playhandle:playHandle];
}

+ (int)getPlayeHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId{
    SunellInnerDeviceModel *deviceModel = [self getInnerDeviceModelByDeviceId:deviceId];
    return [deviceModel getPlayHandleByDeviceId:deviceId channelId:channelId];
}
/**
 CONN_SOCK_NONE = 0,
 CONN_SOCK_CTRL,                    // Control
 CONN_SOCK_LIVE,                    // Live
 CONN_SOCK_PB,                      // Playback
 CONN_SOCK_ALARM,                   // Alarm
 CONN_SOCK_PTZ,                     // PTZ
 CONN_SOCK_FACE,                    // NVR face DB
 CONN_SOCK_DETECT,                  // Face detection
 CONN_SOCK_THE,                     // Thermography
 CONN_SOCK_WIFI,                    // Wi-Fi
 CONN_SOCK_MICROPHONE,              // Mic (device -> SDK)
 CONN_SOCK_INTERPHONE,              // Intercom (SDK -> device)
 CONN_SOCK_UPDATE,                  // Device upgrade
 CONN_SOCK_CREAT_PASSWORD,
 CONN_SOCK_MULTI_OBJ,               // Multi-object image download
 CONN_SOCK_COMPARE,                 // NVR multi-object compare
 CONN_SOCK_GRID,
 CONN_SOCT_THE_PIC,
 CONN_SOCK_CHN_STATUS,              // NVR channel status
 CONN_SOCK_MAX
 */
static void deviceDisconnectCallback(unsigned int handle, void *p_obj, int type) {
    NSString *deviceId = [NSString stringWithUTF8String:(char*)p_obj];
    if (deviceId == nil) {
        return;
    }
    __block int n_type = type;
    if (type == 0 || type == 19) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKDeviceErrorStatus:type:)] ) {
                SunellInnerDeviceModel *innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
                if (innelDeviceModel) {
                    innelDeviceModel.deviceModel.status = 0;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[SunellSDKManager shared].delegate sunellSDKDeviceErrorStatus:innelDeviceModel.deviceModel type:type];
                    });
                }
            }
        });
    }else {
       __block  SunellInnerDeviceModel *innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
        innelDeviceModel.connectHandle = 0;
        innelDeviceModel.deviceModel.status = 0;
        [SunellSDKManager updateHandel:0 deviceId:innelDeviceModel.deviceModel.deviceId];
        // Start auto reconnect.
        if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKStartAutoReconnect:)]) {
            if (innelDeviceModel) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    innelDeviceModel.deviceModel.status = false;
                    [[SunellSDKManager shared].delegate sunellSDKStartAutoReconnect:innelDeviceModel.deviceModel];
                });
            }
        }
        [SunellSDKManager reConnectWithDeviceModel:innelDeviceModel resultBlcok:^(BOOL ret) { // On success, refresh connection state.
            if (ret) {
                innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
            }
            // Reconnect finished.
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKEndtAutoReconnect:isSuccess:)]) {
                if (innelDeviceModel) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[SunellSDKManager shared].delegate sunellSDKEndtAutoReconnect:innelDeviceModel.deviceModel isSuccess:ret];
                    });
                }
            }
            int returnType = type;
            if (ret == false) { // Reconnect failed.
                innelDeviceModel.deviceModel.status = 0;
                returnType = 1;
            }
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKDeviceErrorStatus:type:)] && innelDeviceModel.deviceModel.deviceId != nil) {
                if (innelDeviceModel) {
                    dispatch_async(dispatch_get_main_queue(), ^{ // Notify delegate: device disconnected.
                        [[SunellSDKManager shared].delegate sunellSDKDeviceErrorStatus:innelDeviceModel.deviceModel type:returnType];
                    });
                }
            }
        }];
    }
    printf("SunellSDKManager deviceDisconnectCallback,handel:%d,p_obj:%s,type:%d",handle,deviceId,type);
}
+ (void)reConnectWithDeviceModel:(SunellInnerDeviceModel*)innelDeviceModel resultBlcok:(void(^)(BOOL ret))resultBlock{
    __block int handle = 0;
    __block SunellDeviceModel *deviceModel;
    dispatch_group_t group = dispatch_group_create();
    // Close previous connection handle.
    sdks_dev_conn_close(innelDeviceModel.connectHandle);
    if (innelDeviceModel.deviceModel.isP2PAdd) {
        dispatch_group_enter(group);
        [SunellSDKManager _connectDevByIp:innelDeviceModel.deviceModel.deviceUUID connectCount:3 isP2P:YES port:innelDeviceModel.deviceModel.port user:innelDeviceModel.deviceModel.userName pwd:innelDeviceModel.deviceModel.pwd reulstBlock:^(int result, SunellDeviceModel * _Nonnull device) {
            handle = result;
            deviceModel = device;
            dispatch_group_leave(group);
        }];
        
    }else {
        dispatch_group_enter(group);
        [SunellSDKManager _connectDevByIp:innelDeviceModel.deviceModel.deviceId connectCount:3 isP2P:false port:innelDeviceModel.deviceModel.port user:innelDeviceModel.deviceModel.userName pwd:innelDeviceModel.deviceModel.pwd reulstBlock:^(int result, SunellDeviceModel * _Nonnull device) {
            handle = result;
            deviceModel = device;
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (resultBlock) {
            if (handle < HandleMinValue) {
                resultBlock(false);
            }else {
                resultBlock(true);
            }
        }
    });
}

// Add device via P2P.
+ (void)connectDevByP2P:(NSString *)uuid port:(int)port user:(NSString *)user pwd:(NSString *)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock{
    __weak typeof(self)weakSelf = self;
    [P2PManager getMapAddr:uuid port:port isUpgradeP2P:NO resultBlock:^(int mapResult, P2PMapAddrInfoModel *model) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf _connectDevByIp:model.ip connectCount:5 isP2P:true port:model.relay_port user:user pwd:pwd reulstBlock:resultBlock];
    }];
}
// Add device by IP.
+ (void)connectDevByIP:(NSString*)ip port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock{
    [self _connectDevByIp:ip connectCount:5 isP2P:false port:port user:user pwd:pwd reulstBlock:resultBlock];
}
// Call sdks_dev_conn, then fetch device info.
+ (void)_connectDevByIp:(NSString*)ip connectCount:(int)connectCount isP2P:(bool)isP2P port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock{

    __block SunellDeviceModel *deviceModel;
    __weak typeof(self) weakSelf = self;
    void (^notify)(int) = ^(int code) {
       __strong typeof(weakSelf) strongSelf = weakSelf;
       if (!strongSelf || !resultBlock) return;
       if (deviceModel) {
           deviceModel.isP2PAdd = isP2P;
           deviceModel.userName = user;
           deviceModel.pwd = pwd;
           if ([deviceModel.channels isKindOfClass:[NSArray class]]) {
               for (id obj in deviceModel.channels) {
                   if ([obj isKindOfClass:[SunellChannelModel class]]) {
                       ((SunellChannelModel *)obj).deviceId = deviceModel.deviceId;
                   }
               }
           }
       }
        
        if (code >= HandleMinValue && deviceModel) {
           [strongSelf addHandle:code device:deviceModel];
        }

       dispatch_async(dispatch_get_main_queue(), ^{
           resultBlock(code, deviceModel);
       });
   };
    if (ip.length  <= 0 || port <= 0 || user.length  <= 0 || pwd.length <= 0) {
        notify(0);
        return;
    }

    // Ensure sdks_dev_init runs (+shared) before sdks_dev_conn.
    (void)[SunellSDKManager shared];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
            const char *ipC = ip.UTF8String;
            const char *userC = user.length > 0 ? user.UTF8String : "";
            const char *pwdC = pwd.length > 0 ? pwd.UTF8String : "";
        
            int handle = sdks_dev_conn(ipC, port, userC, pwdC, deviceDisconnectCallback, (void *)ipC);
            int connCount = connectCount;
            int total = connCount;
            while (total-- > 0 && handle < HandleMinValue && handle != -507 && handle != -508) {
                printf("SunellSDKManager connect attempt %d, handle:%d", (int)(connCount - total), handle);
                handle = sdks_dev_conn(ipC, port, userC, pwdC, deviceDisconnectCallback, (void *)ipC);
                sleep(5);
            }
        
           NSLog(@"SunellSDKManager handle:%d, devID:%@, dict:%@", handle,ip,[SunellSDKManager shared].handleDict);
            if (handle >= HandleMinValue) {
              
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;

                [strongSelf getDeviceInfoByHandel:handle localId:ip reulstBlock:^(SunellDeviceModel *device) {
                    device.deviceId = isP2P ? device.deviceUUID : device.deviceIp;
                    deviceModel = device;
                    deviceModel.status = device.status;
                    NSLog(@"SunellSDKManager handle:%d, devID:%@, dict:%@", handle,device.deviceId,[SunellSDKManager shared].handleDict);
//                    if (ctx) free(ctx);

                    notify(device ? handle : 0);
                }];
            } else {
//                if (ctx) free(ctx);
                notify(handle);
            }
        });
}

#pragma mark - Disconnect device
+ (void)disConnectDevByDeviceId:(NSString*)deviceId{
    int handle = [SunellSDKManager getConnectHandleByDeviceId:deviceId];
    sdks_dev_conn_close(handle);
    [self removeHandleWithdeviceId:deviceId];
}
#pragma mark - Fetch device info by handle
+ (void)getDeviceInfoByHandel:(int)handle localId:(NSString*)devID reulstBlock:(void (^)(SunellDeviceModel *device))resultBlock{
    SunellDeviceModel *deviceModel = nil;
    if (handle >= HandleMinValue) {
        // Query device general info.
        dev_general_info_t info = dev_general_info_t{0};
        int nRet = sdks_dev_get_general_info(handle, &info);
        if (nRet == 0){
            // Success.
            deviceModel = [[SunellDeviceModel alloc]init];
            deviceModel.deviceId = devID;
            deviceModel.status = 1;
            deviceModel.deviceUUID = [SunellSafeUtil safeStringFromCString:info.dev_id];
            deviceModel.deviceName = [SunellSafeUtil safeStringFromCString:info.dev_name];
            deviceModel.deviceStyle = [SunellSafeUtil safeStringFromCString:info.dev_style];
            deviceModel.deviceIp = [SunellSafeUtil safeStringFromCString:info.dev_ip];
            deviceModel.deviceMac = [SunellSafeUtil safeStringFromCString:info.dev_mac];
            deviceModel.productModel = [SunellSafeUtil safeStringFromCString:info.prod_model];
            deviceModel.deviceSN = [SunellSafeUtil safeStringFromCString:info.dev_sn];
            deviceModel.swInfo =  [SunellSafeUtil safeStringFromCString:info.sw_info];
            deviceModel.hwInfo =  [SunellSafeUtil safeStringFromCString:info.hw_info];
            deviceModel.devType =  info.dev_type;
            deviceModel.port = info.dev_port;
            if (deviceModel.devType == 14 || deviceModel.devType == 17) {
                NSMutableArray *chnels = [NSMutableArray array];
                for (int i = 0; i < 2; i++) {
                    SunellChannelModel *chnModel = [[SunellChannelModel alloc]init];
                    chnModel.channelId = i + 1;
                    chnModel.status = 1;
                    [chnels addObject:chnModel];
                }
                deviceModel.channels = chnels;
                deviceModel.chnNum = 2;
            }else if (deviceModel.devType == 5 || deviceModel.devType == 2 || deviceModel.devType == 10){
                char *szList = NULL;
                int ret = sdks_dev_get_chn_info(handle, &szList);
                if (ret == 0 && szList != NULL) {
                    NSString *chnsInfo = [NSString stringWithUTF8String:szList];
                    NSError *error;
                    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[chnsInfo dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
                    if (data && data[@"data"]) {
                        NSArray *dictArray = data[@"data"];
                        NSMutableArray *channels = [NSMutableArray array];
                        for (NSDictionary *dictChannel in dictArray) {
                            SunellChannelModel *channelModel = [[SunellChannelModel alloc]init];
                            channelModel.channelId = [dictChannel[@"chn"] intValue];
                            channelModel.deviceId = deviceModel.deviceId;
                            channelModel.status = [dictChannel[@"status"] intValue];
                            channelModel.channleName = dictChannel[@"name"];
                            [channels addObject:channelModel];
                        }
                        deviceModel.channels = channels;
                        deviceModel.chnNum = (int)channels.count;
                    }else {
                        // Failed to parse szList JSON.
                        deviceModel = nil;
                    }
                }else {
                    // sdks_dev_get_chn_info failed.
                    deviceModel = nil;
                }
            }
        }else {
            // sdks_dev_get_general_info failed.
            deviceModel = nil;
        }
    }
    if (resultBlock) {
        resultBlock(deviceModel);
    }
}

void startVideoResultCb(unsigned int handle, int stream_id, void* p_obj, const char* p_time){
    char * p_objChar = (char *)p_obj;
    NSString *p_timeStr = [NSString stringWithUTF8String:(char *)p_time];
    NSString *deviceId = [NSString stringWithUTF8String:p_objChar];
    NSLog(@"SunellSDKManager startVideoResultCb:handle:%d ,streamId:%d,deviceId:%@,p_timeStr:%@",handle,stream_id,deviceId,p_timeStr);
}
#pragma mark - Live preview start
+ (void)liveStartWithDevice:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(nonnull void (^)(int))resultBlock{
    __block int nRet = -1;
    void (^start)(void) = ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        void *pWnd = (__bridge void *)(caLayer);
         nRet = sdks_md_live_start(handle, channelId, streamType, pWnd, isHwDec, startVideoResultCb, (char *)deviceId.UTF8String);
        NSLog(@"SunellSDKManager liveStartWithDevice handle:%d, nRet:%d, chanelId:%d, devID:%@, dict:%@", handle,nRet,channelId,deviceId,[SunellSDKManager shared].handleDict);
        if (nRet >= 0) { // nRet is live stream id; store for later video ops.
            // sdks_md_live_start succeeded.
            [self addPlayerHandle:nRet deviceId:deviceId channelId:channelId];
//            [self addPlayerHandle:nRet deviceId:deviceId];
        }
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
            
        }
        
    };
    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            start();
        });
    } else {
        dispatch_sync(dispatch_get_global_queue(0, 0), start);
    }
   
}

#pragma mark - Live preview stop
+ (void)liveStopWithDevice:(NSString*)deviceId channelId:(int)channelId resultBlock:(nonnull void (^)(int))resultBlock{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        int nRet = sdks_md_live_stop(handle, playerHandle);
        NSLog(@"SunellSDKManager liveStopWithDevice handle:%d, nRet:%d, playHandle:%d, channelId:%d, deviceId:%@, dict:%@", handle,nRet,playerHandle,channelId,deviceId,[SunellSDKManager shared].handleDict);
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
            
        }
    });
   
//    return nRet;
}



void deviceChannelStateCallBack(unsigned int handle, void **p_data, void *p_obj){
    char *m_data = (char *)*p_data;
    NSString *data = [NSString stringWithUTF8String:(char *)*p_data];
    NSString *obj = [NSString stringWithUTF8String:(char *)p_obj];
    printf("SunellSDKManager deviceChannelStateCallBack:handle:%d,m_data:%s,obj:%s",handle,data,obj);
}

/**
 * Channel online/offline monitoring (optional API).
 */
+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
         sdks_dev_start_chn_status(handle, deviceChannelStateCallBack, (char *)deviceId.UTF8String);
        }
    });
}
/**
 * Stop channel status monitoring.
 */
+ (void)stopDeviceChannelStatusMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            sdks_dev_stop_chn_status(handle);
        }
    });
}

void alarmCallBack(unsigned int handle, void** p_data, void* p_obj)
{
    char *m_data = (char *)*p_data;
    NSString *data = [NSString stringWithUTF8String:(char *)*p_data];
    NSString *obj = [NSString stringWithUTF8String:(char *)p_obj];
    printf("SunellSDKManager alarmCallBack:handle:%d,m_data:%s",handle,m_data);
//    if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKAlarmInfo:alarmInfo:)]) {
//
//    }
}
/**
 * Alarm monitoring.
 */
+ (void)startDeviceChannelAlarmMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            sdks_dev_start_alarm(handle, (SDK_ALARM_CB)alarmCallBack, NULL);
        }
    });
}
/**
 * Stop alarm monitoring.
 */
+ (void)stopDeviceChannelAlarmMonitoring:(NSString *)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            sdks_dev_stop_alarm(handle);
        }
    });
}
/**
 * Stop all video / GL consumers.
 */
+ (void)closeGL{
    NSDictionary *dict = [SunellSDKManager shared].handleDict;
    NSArray *allValues = dict.allValues;
    NSMutableSet *seenInners = [NSMutableSet set];
    for (SunellInnerDeviceModel *model in allValues) {
        if (!model || [seenInners containsObject:model]) { continue; }
        [seenInners addObject:model];
        int connecthandle = model.connectHandle;
        NSArray *allPlayerHandles = model.playerHandleDictionary.allValues;
        for ( NSNumber *playHandleNumber in allPlayerHandles) {
            int playHandle = [playHandleNumber intValue];
            if (playHandle >= 0 && connecthandle >= HandleMinValue) {
                sdks_md_glconsumer_stop(connecthandle, playHandle);
            }
        }
    }

}

@end

NS_ASSUME_NONNULL_END
