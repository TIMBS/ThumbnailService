//
//  TSOperationQueueWorker.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 06.01.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import "TSOperationQueueWorker.h"
#import "TSBackgroundThreadQueue.h"

@implementation TSOperationQueueWorker {
    NSMutableDictionary *threadsDictionary;
}

- (id) init
{
    self = [super init];
    if (self) {
        threadsDictionary = [NSMutableDictionary new];
    }
    return self;
}

- (void) enqueueBlock:(dispatch_block_t)block onThreadPriority:(double)priority
{
    [[self queueForPriority:priority] dispatchAsync:block];
}

- (TSBackgroundThreadQueue *) queueForPriority:(double)priority
{
    TSBackgroundThreadQueue *queue = threadsDictionary[@(priority)];
    
    if (!queue) {
        queue = [[TSBackgroundThreadQueue alloc] initWithName:@"TSOperationQueueWorkingThread" threadPriority:priority];
        threadsDictionary[@(priority)] = queue;
    }
    
    return queue;
}

@end
