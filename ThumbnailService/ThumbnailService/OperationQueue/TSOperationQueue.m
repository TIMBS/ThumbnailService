//
//  TSOperationQueue.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 11.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperationQueue.h"
#import "TSBackgroundThreadQueue.h"
#import "TSOperation+Private.h"
#import "TSOperationQueue_Private.h"

@implementation TSOperationQueue {
    NSMutableDictionary *operationsDictionary;
    dispatch_queue_t syncQueue;
    NSMutableDictionary *backgroundThreads;
}

- (id)init
{
    self = [super init];
    if (self) {
        syncQueue = dispatch_queue_create("TSOperationQueueSyncQueue", DISPATCH_QUEUE_SERIAL);
        
        operationsDictionary = [NSMutableDictionary new];
        backgroundThreads = [NSMutableDictionary new];
    }
    return self;
}

- (void) dealloc
{
    dispatch_release(syncQueue);
}

- (void) addOperation:(TSOperation *)operation forIdentifider:(NSString *)identifier
{
    [super addOperation:operation];
    
    operation.operationQueue = self;
    
    dispatch_async(syncQueue, ^{
        operationsDictionary[identifier] = operation;
    });

    __weak typeof (self) weakSelf = self;
    [operation addCancelBlock:^(TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
    [operation addCompleteBlock:^(TSOperation *operation) {
        [weakSelf operationDidFinishForIdentifier:identifier];
    }];
}

- (TSOperation *) operationWithIdentifier:(NSString *)identifier
{
    __block TSOperation *operation = nil;
    dispatch_sync(syncQueue, ^{
        operation = operationsDictionary[identifier];
    });
    return operation;
}

- (void) operationDidFinishForIdentifier:(NSString *)identifier
{
    dispatch_async(syncQueue, ^{
        [operationsDictionary removeObjectForKey:identifier];
    });
}

- (void) enqueueBlock:(dispatch_block_t)block onPriority:(TSOperationDispatchQueuePriority)priority
{
    [[self queueForPriority:priority] dispatchAsync:block];
}

- (TSBackgroundThreadQueue *) queueForPriority:(TSOperationDispatchQueuePriority)priority
{
    CGFloat threadPriority = ThreadPriorityFromDispatchQueuePriority(priority);
    TSBackgroundThreadQueue *queue = backgroundThreads[@(threadPriority)];
    
    if (!queue) {
        queue = [[TSBackgroundThreadQueue alloc] initWithName:@"TSOperationQueueWorkingThread" threadPriority:threadPriority];
        backgroundThreads[@(threadPriority)] = queue;
    }
    
    return queue;
}

static CGFloat ThreadPriorityFromDispatchQueuePriority(TSOperationDispatchQueuePriority priority)
{
    switch (priority) {
        case TSOperationDispatchQueuePriorityBackground:
            return 0;
        default:
        case TSOperationDispatchQueuePriorityLow:
            return 0.3;
        case TSOperationDispatchQueuePriorityNormal:
            return 0.5;
        case TSOperationDispatchQueuePriorityHight:
            return 0.6;
    }
}

@end
