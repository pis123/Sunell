//
//  P2PManager.m
//  Sunell_Demo_iOS
//
//  Created by Sunell on 2023/6/28.
//

#import "P2PManager.h"
#include "new_sdks_nat.h"
@interface P2PManager ()
@end

@implementation P2PManager

static _p2p_sdk_dtls::nat_cli_man_h s_natMan = NULL;

+ (void)initP2P {
    if (s_natMan == NULL) {
        s_natMan = _p2p_sdk_dtls::sdks_create_nat_man(true);
    }
}

+ (void)getMapAddr:(NSString *)uuid port:(int)port isUpgradeP2P:(BOOL)isUpgrade resultBlock:(void (^)(int result, P2PMapAddrInfoModel *model))resultBlock {
    if (s_natMan == NULL) {
        [self initP2P];
    }
    P2PMapAddrInfoModel *model = nil;
    int localPort = port;
    int ret = -1;
    if (localPort > 0) {
        _p2p_sdk_dtls::map_addr_info_t nat_addr = {};
        ret = _p2p_sdk_dtls::sdks_man_get_map_addr(s_natMan, uuid.UTF8String, &nat_addr, (unsigned short)localPort, true);
        if (ret == 0) {
            model = [P2PMapAddrInfoModel p2pMapAddrInfoModelWithChar:nat_addr.ip port:nat_addr.port relayPort:nat_addr.relay_port];
        }
    }
    if (resultBlock) {
        resultBlock(ret, model);
    }
}

@end
