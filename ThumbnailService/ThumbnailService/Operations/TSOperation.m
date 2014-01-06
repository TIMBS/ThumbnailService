//
//  TSOperation.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"
#import "TSOperation+Private.h"

@interface TSOperation ()

@property (nonatomic, strong) NSMutableSet *completionBlocks;
@property (nonatomic, strong) NSMutableSet *cancelBlocks;

@property (nonatomic, getter = isFinished)  BOOL finished;
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isStarted)   BOOL started;

@end

@implementation TSOperation

@synthesize completionBlocks = _completionBlocks;
@synthesize cancelBlocks = _cancelBlocks;

- (id) init
{
    self = [super init];
    if (self) {
        self.completionBlocks = [NSMutableSet new];
        self.cancelBlocks = [NSMutableSet new];
               
        self.callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __weak typeof (self) weakSelf = self;
        [super setCompletionBlock:^{
            [weakSelf onComplete];
        }];
    }
    return self;
}

#pragma mark - NSOperation cuncurrent support

- (void) start
{
    self.started = YES;
    if (![self isCancelled]) {
        self.executing = YES;
        
        [self.worker enqueueBlock:^{
            [self main];
            self.executing = NO;
            self.finished = YES;
        } onThreadPriority:self.threadPriority];
        
    } else {
        self.finished = YES;
    }
}

- (BOOL) isConcurrent
{
    return YES;
}

- (BOOL) isCancelled
{
    return [super isCancelled];
}

- (void) cancel
{
    [self onCancel];
    [super cancel];
}

#pragma mark - Operation termination

- (void) onComplete
{
    if (![self isCancelled]) {
        [self callCompleteBlocks];
    }
}

- (void) onCancel
{
    [self callCancelBlocks];
}

#pragma mark - KVO notifications

- (void) setExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void) setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Callbacks

- (void) addCompleteBlock:(TSOperationCompletion)completionBlock
{
    @synchronized(self) {
        [_completionBlocks addObject:completionBlock];
    }
}

- (void) addCancelBlock:(TSOperationCompletion)cancelBlock
{
    @synchronized(self) {
        [_cancelBlocks addObject:cancelBlock];
    }
}

- (NSMutableSet *) completionBlocks
{
    __block NSMutableSet *set;
    @synchronized(self) {
        set = _completionBlocks;
    }
    return set;
}

- (NSMutableSet *) cancelBlocks
{
    __block NSMutableSet *set;
    @synchronized(self) {
        set = _cancelBlocks;
    }
    return set;
}

- (void) callCancelBlocks
{
    dispatch_async(self.callbackQueue, ^{
        for (TSOperationCompletion cancel in self.cancelBlocks) {
            cancel(self);
        }
    });
}

- (void) callCompleteBlocks
{
    dispatch_async(self.callbackQueue, ^{
        for (TSOperationCompletion complete in self.completionBlocks) {
            complete(self);
        }
    });
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@ %p. Cancelled=%d, Finished=%d, Started=%d, Executing=%d>",[self class], self,[self isCancelled], [self isFinished], [self isStarted], [self isExecuting]];
}

@end
