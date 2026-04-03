//
//  P2PMapAddrInfoModel.m
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import "P2PMapAddrInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation P2PMapAddrInfoModel
+ (instancetype)p2pMapAddrInfoModelWithChar:(char*)ip port:(int)port relayPort:(int)relay_port{
    P2PMapAddrInfoModel *model = [[P2PMapAddrInfoModel alloc]init];
    model.ip = [NSString stringWithUTF8String:ip];
    model.port = port;
    model.relay_port = relay_port;
    return model;
}
@end

NS_ASSUME_NONNULL_END
