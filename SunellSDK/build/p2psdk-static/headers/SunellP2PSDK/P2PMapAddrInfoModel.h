//
//  P2PMapAddrInfoModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface P2PMapAddrInfoModel : NSObject
@property(nonatomic,strong)NSString *ip;
@property(nonatomic,assign)int port;
@property(nonatomic,assign)int relay_port;
+ (instancetype)p2pMapAddrInfoModelWithChar:(char*)ip port:(int)port relayPort:(int)relay_port;
@end

NS_ASSUME_NONNULL_END
