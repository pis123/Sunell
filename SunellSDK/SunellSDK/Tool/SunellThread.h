//
//  SunellThread.h
//  SunellSDK
//
//  Created by Sunell on 2026/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SunellThread : NSObject
+ (instancetype)shared;
/// 异步执行
- (void)asyncExecute:(dispatch_block_t)block;
/// 同步执行，会阻塞调用线程，慎用
- (void)syncExecute:(dispatch_block_t)block;
/// 退出播放器等场景调用：使队列中尚未执行的 async 任务在轮到执行时不再跑 block 内逻辑；已在执行的 async 无法中断，会正常跑完
- (void)invalidatePendingAsyncWork;
@end

NS_ASSUME_NONNULL_END
