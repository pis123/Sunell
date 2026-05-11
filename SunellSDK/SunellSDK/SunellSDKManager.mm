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
#import "SunellInnerDeviceModel.h"
#import "SunellRequestInfo.h"
#import "SunellThread.h"
#import "VideoPlayConst.h"
#import <AVFoundation/AVFoundation.h>
#import "sdks.h"
NS_ASSUME_NONNULL_BEGIN
@interface SunellSDKManager()
@property(nonatomic,strong)NSMutableDictionary *handleDict;
@property(nonatomic,strong)NSMutableDictionary *requestDict; // 请求的缓存
@property(nonatomic,strong)SunellThread *sunellThread;
@end
@implementation SunellSDKManager

#define HandleMinValue 1000
#define StreamIDMinValue 0
+ (instancetype)shared{
    static SunellSDKManager *sdkmgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sdkmgr = [[SunellSDKManager alloc]init];
        sdkmgr.handleDict = [NSMutableDictionary dictionary];
        sdkmgr.sunellThread = [SunellThread shared];
        sdkmgr.requestDict = [NSMutableDictionary dictionary];
        sdks_dev_init(NULL);
    });
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
    // SDK 可对同一 p_obj 多次触发断开回调；勿用 __bridge_transfer，否则首次即释放、再次为野指针（见同文件播放时间回调注释）。
    if (p_obj == NULL) {
        return;
    }
    NSString *deviceId = (__bridge NSString *)p_obj;
    if (![deviceId isKindOfClass:[NSString class]]) {
        return;
    }
    __block int n_type = type;
    if (type == 0 || type == 19) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKDeviceErrorStatus:type:)] ) {
                SunellInnerDeviceModel *innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
                if (innelDeviceModel) {
                    innelDeviceModel.deviceModel.status = SunellDeviceStatus_offline;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[SunellSDKManager shared].delegate sunellSDKDeviceErrorStatus:innelDeviceModel.deviceModel type:type];
                    });
                }
            }
        });
    }else {
        __block  SunellInnerDeviceModel *innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
        if (!innelDeviceModel) {
            return;
        }
        innelDeviceModel.connectHandle = 0;
        innelDeviceModel.deviceModel.status = SunellDeviceStatus_offline;
        [SunellSDKManager updateHandel:0 deviceId:innelDeviceModel.deviceModel.deviceId];
        // Start auto reconnect.
        if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKStartAutoReconnect:)]) {
            if (innelDeviceModel) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    innelDeviceModel.deviceModel.status = SunellDeviceStatus_offline;
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
                innelDeviceModel.deviceModel.status = SunellDeviceStatus_offline;
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
    NSLog(@"SunellSDKManager deviceDisconnectCallback handle:%u deviceId:%@ type:%d", handle, deviceId, type);
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
        NSString *ipSafe = [ip copy];
        NSString *userSafe = [user copy];
        NSString *pwdSafe = [pwd copy];
        const char *ipC = ipSafe.UTF8String;
        const char *userC = userSafe.length > 0 ? userSafe.UTF8String : "";
        const char *pwdC = pwdSafe.length > 0 ? pwdSafe.UTF8String : "";
        void *context = (__bridge_retained void *)ipSafe;
        
        int handle = sdks_dev_conn(ipC, port, userC, pwdC, deviceDisconnectCallback, context);
        int connCount = connectCount;
        int total = connCount;
        while (total-- > 0 && handle < HandleMinValue && handle != -507 && handle != -508) {
            handle = sdks_dev_conn(ipC, port, userC, pwdC, deviceDisconnectCallback, context);
            sleep(5);
        }
        if (handle >= HandleMinValue) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf getDeviceInfoByHandel:handle localId:ip reulstBlock:^(SunellDeviceModel *device) {
                device.deviceId = isP2P ? device.deviceUUID : device.deviceIp;
                deviceModel = device;
                deviceModel.status = device.status;
                notify(device ? handle : 0);
            }];
        } else {
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
            deviceModel.status = SunellDeviceStatus_online;
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
                    chnModel.status = SunellDeviceStatus_online;
                    [chnels addObject:chnModel];
                }
                deviceModel.channels = chnels;
                deviceModel.chnNum = 2;
                deviceModel.devType = 1;
            }else if (deviceModel.devType == 5 || deviceModel.devType == 2 || deviceModel.devType == 10){ // NVR，其他的都是ipc设备
                deviceModel.devType = 2;
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
                            channelModel.status = [dictChannel[@"status"] intValue] == 1 ? SunellDeviceStatus_online : SunellDeviceStatus_offline;
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
            }else {
                deviceModel.devType = 1;
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

/// 播放时间回调；SDK 会多次调用且复用同一个 p_obj，禁止 __bridge_transfer（否则首次回调后即释放，再次回调野指针崩溃）。
void startVideoResultCb(unsigned int handle, int stream_id, void* p_obj, const char* p_time){
    if (!p_obj) {
        return;
    }
    char *cStr = (char *)p_obj;
    if (!cStr) {
        return;
    }
    NSData *data = [NSData dataWithBytes:cStr
                                  length:strlen(cStr)];

    NSString *key = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
    SunellSDKManager *mgr = [SunellSDKManager shared];
    SunellRequestInfo *info = mgr.requestDict[key];
    if (![info isKindOfClass:[SunellRequestInfo class]]) {
        return;
    }
    NSString *playTime = p_time ? [NSString stringWithUTF8String:p_time] : nil;
    if (info.isNotiback == YES) {
        return;
    }
    switch (info.requestType) {
        case SunellRequestType_openLive:
            if (!info.isNotiback) {
                info.isNotiback = YES;
                // 存在
                NSLog(@"startVideoResultCb 存在Info：%@",info.key);
                NSLog(@"startVideoResultCb:handle:%d,stream:%d,type:%d,time:%@",handle,stream_id,info.requestType,playTime);
                if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKVideoOperation:channelId:eventId:msg:playModel:)]) {
                    [[SunellSDKManager shared].delegate sunellSDKVideoOperation:info.deviceId channelId:info.channelId eventId:OPEN_VIDEO_SUCCESS msg:@"" playModel:info.requestType];
                }
            }
            break;
        case SunellRequestType_openPlayback:
            if (!info.isNotiback) {
                info.isNotiback = YES;
                // 存在
                NSLog(@"startVideoResultCb 存在Info：%@",info.key);
                NSLog(@"startVideoResultCb:handle:%d,stream:%d,type:%d,time:%@",handle,stream_id,info.requestType,playTime);
                if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKVideoOperation:channelId:eventId:msg:playModel:)]) {
                    [[SunellSDKManager shared].delegate sunellSDKVideoOperation:info.deviceId channelId:info.channelId eventId:OPEN_VIDEO_SUCCESS msg:@"" playModel:info.requestType];
                }
            }
            break;
        default:
            break;
    }
   
}
#pragma mark - Live preview start
+ (void)liveStartWithDevice:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(nonnull void (^)(int))resultBlock{
    __block int nRet = -1;
    void (^start)(void) = ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        void *pWnd = (__bridge void *)(caLayer);
        SunellRequestInfo *requestInfo = [[SunellRequestInfo alloc]init];
        requestInfo.requestType = SunellRequestType_openLive;
        SunellSDKManager *mgr = [SunellSDKManager shared];
        requestInfo.deviceId = deviceId;
        requestInfo.channelId = channelId;
        requestInfo.isNotiback = NO;
        requestInfo.streamType = streamType;
        requestInfo.isHwDec = isHwDec;
        @synchronized (mgr.requestDict) {
            mgr.requestDict[requestInfo.key] = requestInfo;
        }
        char *cStr = strdup([requestInfo.key UTF8String]);
        __block int startRet = -1;
        dispatch_sync(dispatch_get_main_queue(), ^{
            startRet = sdks_md_live_start(handle, channelId, streamType, pWnd, isHwDec, startVideoResultCb, (void*)cStr);
        });
        nRet = startRet;
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
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread invalidatePendingAsyncWork];
    [sdkMgr.sunellThread asyncExecute:^{
        start();
    }];

}

#pragma mark - Live preview stop
+ (void)liveStopWithDevice:(NSString*)deviceId channelId:(int)channelId resultBlock:(nonnull void (^)(int))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        __block int nRet = -1;
        dispatch_sync(dispatch_get_main_queue(), ^{
            nRet = sdks_md_live_stop(handle, playerHandle);
            // `liveStop` 之后会立刻从 `playerHandleDictionary` 移除句柄，而 `closeGL` 依赖该字典调用
            // `sdks_md_glconsumer_stop`，导致 GL/显存路径往往从未执行，退出预览后仍占用大量内存。
            // 在此处与 live_stop 同一主线程串行调用，确保 GL consumer 与解码表面被释放。
            if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
                sdks_md_glconsumer_stop(handle, playerHandle);
            }
        });
        SunellSDKManager *mgr = [SunellSDKManager shared];
        NSString *prefix = [NSString stringWithFormat:@"%@_%d_", deviceId, channelId];
        @synchronized (mgr.requestDict) {
            for (NSString *key in [mgr.requestDict.allKeys copy]) {
                if ([key hasPrefix:prefix]) {
                    [mgr.requestDict removeObjectForKey:key];
                }
            }
        }
        SunellInnerDeviceModel *inner = [self getInnerDeviceModelByDeviceId:deviceId];
        if (inner) {
            [inner removePlayerHandleForDeviceId:deviceId channelId:channelId];
        }
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
            
        }
    }];
}

/**
 *
 IPCAMERA        = 1,    //Õ¯¬Á…„œÒª˙…Ë±∏
 DVR                = 2,    // ˝◊÷ ”∆µ¬ºœÒª˙…Ë±∏
 DVS                = 3,    // ˝◊÷ ”∆µ∑˛ŒÒ∆˜…Ë±∏
 IPDOME            = 4,    //Õ¯¬Á∏ﬂÀŸ«Ú
 NVR                = 5,    //NVR
 ONVIF_DEVICE    = 6,    //Onvif …Ë±∏
 DECODER            = 7,    //Ω‚¬Î∆˜
 LPR                = 8,    //≥µ≈∆ ∂±…„œÒª˙
 FISHEYE         = 9,    //”„—€…Ë±∏¿‡–Õ°£
 NVR_2            = 10,   //±Í æ4.0µƒNVR
 HK_DVR            = 100,    //HK DVR
 RS_DVR            = 101,    //∞≤¡™DVR
 DH_DVR            = 102,    //¥Ûª™DVR
 VIRTUAL_NVR        = 103   //”√”⁄ºÊ»›NVRøÕªß∂ÀÀ˘ π”√µƒ±æµÿServer
};
 */

void deviceChannelStateCallBack(unsigned int handle, void **p_data, void *p_obj){
    
    if (!p_obj) {
        return;
    }
    char *cStr = (char *)p_obj;
    if (!cStr) {
        return;
    }
    NSData *deviceData = [NSData dataWithBytes:cStr
                                  length:strlen(cStr)];

    NSString *deviceId = [[NSString alloc] initWithData:deviceData
                                          encoding:NSUTF8StringEncoding];
   
    NSString *resultStr = [NSString stringWithUTF8String:(char *)*p_data];
    
    NSData *jsonData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];

    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error) {
        return;
    }
    NSDictionary *dataDict = dict[@"data"];
    NSNumber *channelid = dataDict[@"chn_id"];
    NSString *channelName = dataDict[@"name"];
    NSNumber *state = dataDict[@"state"];
    SunellChannelModel *model = [[SunellChannelModel alloc]init];
    model.deviceId = deviceId;
    model.channelId = channelid.intValue;
    model.status = state.intValue == 1 ? SunellDeviceStatus_online : SunellDeviceStatus_offline;
    model.channleName = channelName;
    if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKChannelStatusChangeNotiWithChannelModel:)]) {
        [[SunellSDKManager shared].delegate sunellSDKChannelStatusChangeNotiWithChannelModel:model];
    }
//    printf("SunellSDKManager deviceChannelStateCallBack:handle:%d,deviceId:%s,resultStr:%s",handle,deviceId,resultStr);
}

/**
 * Channel online/offline monitoring (optional API).
 */
+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            char *cStr = strdup([deviceId UTF8String]);
           int ret = sdks_dev_start_chn_status(handle, deviceChannelStateCallBack, (void*)cStr);
            printf("结果:ret",ret);
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
 * capture
 */
+ (void)captureImageWithDeviceId:(NSString*)deviceId channelId:(int)channelId path:(NSString*)path resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0 || !path) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
            int result = sdks_md_capture(handle, playerHandle, path.UTF8String);
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(result);
                });
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        if (!deviceId || channelId <= 0 || !path) {
//            if (resultBlock) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    resultBlock(-1);
//                });
//            }
//            return;
//        }
//        int handle = [self getConnectHandleByDeviceId:deviceId];
//        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
//        if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
//            int result = sdks_md_capture(handle, playerHandle, path.UTF8String);
//            if (resultBlock) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    resultBlock(result);
//                });
//            }
//        }else {
//            if (resultBlock) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    resultBlock(-1);
//                });
//            }
//        }
//    });
}

/**
 * switch voice
 */
+ (void)audioSwitchWithDeviceId:(NSString*)deviceId channelId:(int)channelId isOpen:(BOOL)isOpen resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
            int result = -1;
            if (isOpen) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = nil;
                    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                    // 配置音频会话类别和选项
                    BOOL setCategorySuccess = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                                             withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker
                                                                   error:&error];
                    if (!setCategorySuccess || error) {
                       
                    }
                    
                    // 激活音频会话
                    BOOL setActiveSuccess = [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
                    if (!setActiveSuccess || error) {
                        
                    }
                    
                    // 设置缓冲区时长，减少延迟
                    [audioSession setPreferredIOBufferDuration:0.1 error:&error];
                    if (error) {
                       
                    }
                });
                
                 result = sdks_md_audio_start(handle, playerHandle);
            }else {
                 result = sdks_md_audio_stop(handle, playerHandle);
            }
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(result);
                });
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}

void talkOpenIntercomDbCb(unsigned int db,void *p_obj){
    SunellRequestInfo *requestInfo = (__bridge SunellRequestInfo*)p_obj;
    if (!requestInfo) {
        return;
    }
    if (![requestInfo isKindOfClass:[SunellRequestInfo class]]) {
        return;
    }
    if (requestInfo.isNotiback) {
        return;
    }
    if (requestInfo.requestType == SunellRequestType_openTalk) {
        requestInfo.isNotiback = YES;
        NSLog(@"打开对讲");
    }
}
/**
 * switch talk
 */
+ (void)talkSwitchWithDeviceId:(NSString*)deviceId channelId:(int)channelId isOpen:(BOOL)isOpen resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
            int result = -1;
            if (isOpen) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    AVAudioSession *audioSession= [AVAudioSession sharedInstance];
                    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
                    [audioSession setActive:YES error:nil];
                    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                        if (granted) {
                            SunellRequestInfo *requestInfo = [[SunellRequestInfo alloc]init];
                            requestInfo.requestType = SunellRequestType_openTalk;
                            SunellSDKManager *mgr = [SunellSDKManager shared];
                            requestInfo.deviceId = deviceId;
                            requestInfo.channelId = channelId;
                            requestInfo.isNotiback = NO;
                            @synchronized (mgr.requestDict) {
                                mgr.requestDict[requestInfo.key] = requestInfo;
                            }
                           int ret = sdks_md_talk_start(handle, channelId, talkOpenIntercomDbCb, (__bridge void*)requestInfo);
                            
                            if (resultBlock) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    resultBlock(ret);
                                });
                                
                            }
                        }else {
                            if (resultBlock) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    resultBlock(-1);
                                });
                                
                            }
                        }
                    }];
                });
            
            }else {
                result = sdks_md_talk_stop(handle, channelId);
                if (resultBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        resultBlock(result);
                    });
                }
            }
            
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}
/**
 * SD / HD Switch
 * qualityType: 1  SD
 * qualityType: 2  HD
 */
+ (void)qualityAdjustmentWithDeviceId:(NSString*)deviceId channelId:(int)channelId type:(int)qualityType resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0 || qualityType > 2 || qualityType < 1) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
            int result = -1;
            int ret = sdks_md_chg_stream(handle, playerHandle, qualityType);
             if (resultBlock) {
                 resultBlock(ret);
             }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}
/**
 * 获取设备能力
 */
+ (void)getDeviceCapacityWithDeviceId:(NSString*)deviceId channelId:(int)channelId reulstBlock:(void (^)(int result, SunellChannelModel * _Nullable channelModel))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    
    
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1,nil);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
            char * resultStr = nil;
            int ret = sdks_dev_json_get_hw_cap_by_chn(handle, channelId, &resultStr);
            if (ret == 0) {
                NSString  *jsonStr = [NSString stringWithCString:resultStr encoding:NSUTF8StringEncoding];
                NSLog(@"能力channelId:%d,结果:%@,",channelId,jsonStr);
                NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error) {
                    if (resultBlock) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            resultBlock(-1,nil);
                        });
                    }
                }else {
                    SunellInnerDeviceModel *innerDeviceModel = [self getInnerDeviceModelByDeviceId:deviceId];
                    SunellChannelModel *selModel = nil;
                    if (innerDeviceModel.deviceModel.channels.count > 0) {
                        for (SunellChannelModel *channelModel in innerDeviceModel.deviceModel.channels) {
                            if (channelModel.channelId == channelId) {
                                selModel = channelModel;
                            }
                        }
                    }else {
                        selModel = [[SunellChannelModel alloc]init];
                        selModel.deviceId = innerDeviceModel.deviceModel.deviceId;
                        selModel.channleName = innerDeviceModel.deviceModel.deviceName;
                        selModel.channelId = 1;
                        selModel.status = innerDeviceModel.deviceModel.status;
                    }
                    
                    // PTZ能力
                    if ([dict.allKeys containsObject:@"RS485Num"]) {
                        int ptzAble = [dict[@"RS485Num"] intValue];
                        int interPTZAble = [dict[@"InternalPTZEnable"] intValue];
                        if (ptzAble == 1 || interPTZAble == 1) {
                            selModel.ptzCapacity = SunellDeviceCapacityType_capable;
                        }else {
                            selModel.ptzCapacity = SunellDeviceCapacityType_not_capable;
                        }
                         
                    }
                    // 对讲能力
                    if ([dict.allKeys containsObject:@"AudioOutNum"]) {
                        int talkAble = [dict[@"AudioOutNum"] intValue];
                        if (talkAble > 0) {
                            selModel.talkCapacity = SunellDeviceCapacityType_capable;
                        }else {
                            selModel.talkCapacity = SunellDeviceCapacityType_not_capable;
                        }
                    }
                    if (resultBlock) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            resultBlock(0,selModel);
                        });
                    }
                    
                }
                
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1,nil);
                });
            }
        }
    }];
}
/**
 * 获取白光灯能力
 */
+ (void)getWhiteLightAbilityWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString* _Nullable jsonStr))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        char * resultStr = nil;
        int ret = sdks_get_white_light_switch_ability(handle, channelId, &resultStr);
        if (ret == 0) {
            if (resultBlock) {
                NSString  *jsonStr = [NSString stringWithCString:resultStr encoding:NSUTF8StringEncoding];
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret,jsonStr);
                });
               
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1,@"");
                });
            }
        }
        
    }];
}



/**
 * 打开ptz
 */
+ (void)openPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue ) {
            int nRet = sdks_dev_open_ptz(handle);
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(nRet);
                });
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}
/**
 * 关闭ptz
 */
+ (void)closePTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue ) {
            int nRet = sdks_dev_close_ptz(handle);
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(nRet);
                });
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}
// 开启ptz操作
+ (void)operationPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId arrowType:(int)arrowType resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0 || arrowType < 1 || arrowType > 8) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue ) {
            int nRet = sdks_dev_ptz_rotate(handle, channelId, arrowType, 32);
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(nRet);
                });
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}
// 停止ptz操作
+ (void)stopPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0 ) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue ) {
            int nRet = sdks_dev_ptz_stop(handle, channelId);
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(nRet);
                });
            }
        }else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
        }
    }];
}
// 获取白光灯数据
+ (void)getWhiteLightSwitchParamWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result, NSString * _Nullable jsonStr))resultBlock {
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, nil);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, nil);
                });
            }
            return;
        }
        char *resultStr = NULL;
        int ret = sdks_get_white_light_switch_param(handle, channelId, &resultStr);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, jsonStr);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, nil);
                });
            }
        }
    }];
}

// 设置白光灯数据
+ (void)applyWhiteLightSwitchParamWithDeviceId:(NSString*)deviceId channelId:(int)channelId paramJson:(NSString*)paramJson resultBlock:(void(^)(int result))resultBlock;{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0 || !paramJson.length) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        char *buf = (char *)[paramJson UTF8String];
        int ret = sdks_set_white_light_switch_param(handle, channelId, buf);
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(ret);
            });
        }
    }];
}
// 获取报警音频数据
+ (void)getAudioAlarmInfoWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString * _Nullable jsonStr))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, nil);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, nil);
                });
            }
            return;
        }
        char *resultStr = NULL;
        int ret = sdks_dev_get_audio_alarm_event(handle, channelId, &resultStr);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, jsonStr);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, nil);
                });
            }
        }
    }];
}

/// 播放报警音频数据；
+ (void)playAudioAlarmWithDeviceId:(NSString*)deviceId channelId:(int)channelId displayId:(int)displayId playNum:(int)playNum resultBlock:(void(^)(int result))resultBlock {
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        SunellInnerDeviceModel *innerDeviceModel = [self getInnerDeviceModelByDeviceId:deviceId];
        if (!innerDeviceModel.deviceModel) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int ret = -1;
        if (innerDeviceModel.deviceModel.devType == 1) {
            // handle:设备连接的结果
            // chn：音频id
            // play_num：播放次数
            ret = sdks_dev_play_audio_alarm(handle, displayId, playNum);
        }else {
            // NVR
            ret = sdks_dev_nvr_play_audio_alarm(handle, channelId, displayId, playNum);
        }
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(ret);
            });
        }
    }];
}
// 打开回放
+ (void)playbackStartWithDeviceId:(NSString*)deviceId channelId:(int)channelId startTimeStr:(NSString*)startTimeStr streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(void(^)(int result))resultBlock{
    
    __block int nRet = -1;
    void (^start)(void) = ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        void *pWnd = (__bridge void *)(caLayer);
        SunellRequestInfo *requestInfo = [[SunellRequestInfo alloc]init];
        requestInfo.requestType = SunellRequestType_openPlayback;
        SunellSDKManager *mgr = [SunellSDKManager shared];
        requestInfo.deviceId = deviceId;
        requestInfo.channelId = channelId;
        requestInfo.isNotiback = NO;
        requestInfo.streamType = streamType;
        requestInfo.isHwDec = isHwDec;
        @synchronized (mgr.requestDict) {
            mgr.requestDict[requestInfo.key] = requestInfo;
        }
        char *cStr = strdup([requestInfo.key UTF8String]);
        // CAEAGLLayer 属于 UIKit 视图层级：绑定 drawable / GL 初始化必须在主线程，否则触发
        // "Modifying properties of a view's layer off the main thread"（SDK 渲染线程也会触碰 layer）。
        __block int startRet = -1;
        dispatch_sync(dispatch_get_main_queue(), ^{
            // startRet = sdks_md_live_start(handle, channelId, streamType, pWnd, isHwDec, startVideoResultCb, (__bridge void *)requestInfo);
            startRet = sdks_md_pb_start(handle, channelId, streamType, startTimeStr.UTF8String, pWnd, isHwDec,startVideoResultCb, (void *)cStr);
        });
        nRet = startRet;
        NSLog(@"SunellSDKManager sdks_md_pb_start handle:%d, nRet:%d, chanelId:%d, devID:%@, dict:%@", handle,nRet,channelId,deviceId,[SunellSDKManager shared].handleDict);
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
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread invalidatePendingAsyncWork];
    [sdkMgr.sunellThread asyncExecute:^{
        start();
    }]; 
}
// 关闭回放
+ (void)playBackStopWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        __block int nRet = -1;
        dispatch_sync(dispatch_get_main_queue(), ^{
            nRet = sdks_md_pb_stop(handle, playerHandle);
            if (handle >= HandleMinValue && playerHandle >= StreamIDMinValue) {
                sdks_md_glconsumer_stop(handle, playerHandle);
            }
        });
        SunellSDKManager *mgr = [SunellSDKManager shared];
        NSString *prefix = [NSString stringWithFormat:@"%@_%d_", deviceId, channelId];
        @synchronized (mgr.requestDict) {
            for (NSString *key in [mgr.requestDict.allKeys copy]) {
                if ([key hasPrefix:prefix]) {
                    [mgr.requestDict removeObjectForKey:key];
                }
            }
        }
        SunellInnerDeviceModel *inner = [self getInnerDeviceModelByDeviceId:deviceId];
        if (inner) {
            [inner removePlayerHandleForDeviceId:deviceId channelId:channelId];
        }
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
        }
    }];
}

// 暂停回放
+ (void)playBackPauseWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{ resultBlock(-1); });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle < HandleMinValue || playerHandle < StreamIDMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{ resultBlock(-1); });
            }
            return;
        }
        __block int nRet = -1;
        dispatch_sync(dispatch_get_main_queue(), ^{
            nRet = sdks_md_pb_pause(handle, playerHandle);
        });
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
        }
    }];
}

// 继续回放
+ (void)playBackResumeWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{ resultBlock(-1); });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle < HandleMinValue || playerHandle < StreamIDMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{ resultBlock(-1); });
            }
            return;
        }
        __block int nRet = -1;
        dispatch_sync(dispatch_get_main_queue(), ^{
            nRet = sdks_md_pb_resume(handle, playerHandle);
        });
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
        }
    }];
}

// seek
+ (void)playBackSeekWithDeviceId:(NSString*)deviceId channelId:(int)channelId startTimeStr:(NSString*)startTimeStr resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        
        if (!deviceId || channelId <= 0 || startTimeStr.length <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        char *resultStr = NULL;
        int ret = sdks_dev_pb_seek(handle, playHandle, startTimeStr.UTF8String);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret);
                });
            }
        }
    }];
    
}

// speed
+ (void)playBackSetSpeedWithDeviceId:(NSString*)deviceId channelId:(int)channelId speed:(SunellSpeedType)speedType resultBlock:(void(^)(int result))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    
    [sdkMgr.sunellThread asyncExecute:^{
        if (!deviceId || channelId <= 0 ) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        if (handle < HandleMinValue || playHandle < StreamIDMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1);
                });
            }
            return;
        }
       char *resultStr = NULL;
       int speed = speedType == SunellSpeed_1 ? 1 : 2;
       int ret = sdks_md_set_pb_speed(handle, playHandle, speed);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret);
                });
            }
        }
    }];
}


// 获取某天的回放记录
+ (void)getPlayBackOneDayRecordListWithDeviceId:(NSString*)deviceId channelId:(int)channelId dayStr:(NSString*)dayStr resultBlock:(void(^)(int result,NSString * jsonStr))resultBlock{
    
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        
        if (!deviceId || channelId <= 0 || dayStr.length <= 0 || dayStr.length > 10) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, @"");
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, @"");
                });
            }
            return;
        }
        char *resultStr = NULL;
        int ret = sdks_dev_pb_get_rec_list(handle, channelId, 1, dayStr.UTF8String, &resultStr);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, jsonStr);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, @"");
                });
            }
        }
    }];
}
// 获取某段时间内的回放记录
+ (void)getPlayBackRecordWithinACertainPeriodOfTimeWithDeviceId:(NSString*)deviceId channelId:(int)channelId startDateStr:(NSString*)startDateStr endDateStr:(NSString*)endDateStr resultBlock:(void(^)(int result,NSString * jsonStr))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        
        if (!deviceId || channelId <= 0 || startDateStr.length <= 0 || endDateStr.length <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, @"");
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, @"");
                });
            }
            return;
        }
        char *resultStr = NULL;
        int ret = sdks_dev_pb_get_rec_date_list(handle, channelId, 1, startDateStr.UTF8String, endDateStr.UTF8String, &resultStr);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, jsonStr);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, @"");
                });
            }
        }
    }];
}
// 获取时间段内那些day有回放记录
+ (void)getWhichDaysWithinTheTimePeriodHavePlaybackRecordsWithDeviceId:(NSString*)deviceId channelId:(int)channelId startDayStr:(NSString*)startDayStr endDayStr:(NSString*)endDayStr resultBlock:(void(^)(int result,NSString* jsonStr))resultBlock{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread asyncExecute:^{
        
        if (!deviceId || channelId <= 0 || startDayStr.length <= 0 || endDayStr.length <= 0) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, @"");
                });
            }
            return;
        }
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle < HandleMinValue) {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(-1, @"");
                });
            }
            return;
        }
        char *resultStr = NULL;
        int ret = sdks_dev_pb_date_list(handle, channelId, 1, startDayStr.UTF8String, endDayStr.UTF8String, &resultStr);
        if (ret == 0 && resultStr != NULL) {
            NSString *jsonStr = [NSString stringWithUTF8String:resultStr];
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, jsonStr);
                });
            }
        } else {
            if (resultBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultBlock(ret, @"");
                });
            }
        }
    }];
}

/**
 * Stop all video / GL consumers.
 */
+ (void)closeGL{
    SunellSDKManager *sdkMgr = [SunellSDKManager shared];
    [sdkMgr.sunellThread invalidatePendingAsyncWork];
    NSDictionary *dict = sdkMgr.handleDict;
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

#pragma mark - private
+ (NSString*)s_dictToJsonStr:(NSDictionary*)dict{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    NSString *jsonString = @"";
    if (!error && jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

@end

NS_ASSUME_NONNULL_END
