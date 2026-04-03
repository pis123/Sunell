//
//  P2PManager.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>
#import "P2PMapAddrInfoModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface P2PManager : NSObject
//+ (instancetype)shared;
//- (void)initP2P;
//- (NSDictionary *_Nullable)getMapAddr:(NSString *)uuid  isUpgradeP2P:(BOOL)isUpgrade;
/**
 * result
 * 0:正常
 * 其他：失败
 */
+ (void)getMapAddr:(NSString *)uuid port:(int)port isUpgradeP2P:(BOOL)isUpgrade resultBlock:(void(^)(int result, P2PMapAddrInfoModel* model))resultBlock;
@end

NS_ASSUME_NONNULL_END
