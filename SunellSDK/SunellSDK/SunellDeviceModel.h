//
//  SunellDeviceModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SunellChannelModel;
@interface SunellDeviceModel : NSObject
@property(nonatomic,strong)NSString *deviceUUID; // Device UUID
@property(nonatomic,strong)NSString *deviceName; // Display name
@property(nonatomic,strong)NSString *userName; // Login username
@property(nonatomic,strong)NSString *pwd; // Login password
@property(nonatomic,strong)NSString *deviceStyle; // Device style string
@property(nonatomic,strong)NSString *deviceIp; // Device IP
@property(nonatomic,strong)NSString *deviceMac; // MAC address
@property(nonatomic,strong)NSString *productModel; // Product module / model
@property(nonatomic,strong)NSString *deviceSN; // SN
@property(nonatomic,strong)NSString *swInfo; // Firmware / software info
@property(nonatomic,strong)NSString *hwInfo; // Hardware info
@property(nonatomic,strong)NSString *deviceId;
@property(nonatomic,assign)int devType; // Device type id
@property(nonatomic,assign)int port; // Port
@property(nonatomic,assign)int chnNum; // Channel count
@property(nonatomic,strong)NSArray<SunellChannelModel*> *channels;// Channel list
@property(nonatomic,assign)NSInteger status; // 1: online, 0: offline
@property(nonatomic,assign)BOOL isP2PAdd;// Added via P2P
@end

NS_ASSUME_NONNULL_END
