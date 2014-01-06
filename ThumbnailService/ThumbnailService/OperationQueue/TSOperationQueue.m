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

@implementation TSOperationQueue {
    NSMutableDictionary *operationsDictionary;
    dispatch_queue_t syncQueue;
    TSOperationQueueWorker *worker;
}

- (id)init
{
    self = [super init];
    if (self) {
        syncQueue = dispatch_queue_create("TSOperationQueueSyncQueue", DISPATCH_QUEUE_SERIAL);
        
        operationsDictionary = [NSMutableDictionary new];
        worker = [TSOperationQueueWorker new];
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
    
    operation.worker = worker;
    
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


@end
