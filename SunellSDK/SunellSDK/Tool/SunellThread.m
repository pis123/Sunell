//
//  SunellThread.m
//  SunellSDK
//
//  Created by Sunell on 2026/4/24.
//

#import "SunellThread.h"
#import <stdatomic.h>

static const void *kSunellSDKSerialQueueKey = &kSunellSDKSerialQueueKey;

@interface SunellThread ()
@property (nonatomic) dispatch_queue_t sdkQueue;
@end

@implementation SunellThread {
    atomic_uint_fast64_t _asyncEpoch;
}

+ (instancetype)shared {
    static SunellThread *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SunellThread alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _sdkQueue = dispatch_queue_create("com.sunell.sdk.serial", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_sdkQueue, kSunellSDKSerialQueueKey, (void *)1, NULL);
        atomic_store_explicit(&_asyncEpoch, 0, memory_order_relaxed);
    }
    return self;
}

- (void)asyncExecute:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    uint_fast64_t token = atomic_load_explicit(&_asyncEpoch, memory_order_relaxed);
    dispatch_async(self.sdkQueue, ^{
        if (atomic_load_explicit(&self->_asyncEpoch, memory_order_acquire) != token) {
            return;
        }
        block();
        
    });
}

- (void)invalidatePendingAsyncWork {
    atomic_fetch_add_explicit(&_asyncEpoch, 1, memory_order_acq_rel);
}

- (void)syncExecute:(dispatch_block_t)block {
    if (!block) {
        return;
    }
    if (dispatch_get_specific(kSunellSDKSerialQueueKey)) {
        block();
        return;
    }
    dispatch_sync(self.sdkQueue, block);
}

@end
