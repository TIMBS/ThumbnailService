//
//  SerialQueue.m
//  SerialQueue
//
//  Created by Aleksey Garbarev on 05.01.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import "TSBackgroundThreadQueue.h"

@protocol WorkerProvider <NSObject>

- (dispatch_block_t) nextTask;

@end


@interface Worker : NSObject

@property (nonatomic, weak) id<WorkerProvider> provider;

- (void) main;
- (void) cancel;
- (void) checkForTask;

@end


@interface TSBackgroundThreadQueue() <WorkerProvider>
@property (nonatomic, weak) NSThread *workerThread;
@end

@implementation TSBackgroundThreadQueue {
    NSMutableArray *queue;
    Worker *worker;
    
    NSString *threadName;
    CGFloat threadPriority;
}

- (id) initWithName:(NSString *)name threadPriority:(CGFloat)priority
{
    self = [super init];
    if (self) {
        worker = [[Worker alloc] init];
        worker.provider = self;
        queue = [[NSMutableArray alloc] initWithCapacity:100];
        
        threadName = name;
        threadPriority = priority;
    }
    return self;
}

- (void) dealloc
{
    [worker cancel];
}

- (void) createThreadIfNeeded
{
    if (!self.workerThread) {
        NSThread *thread = [[NSThread alloc] initWithTarget:worker selector:@selector(main) object:nil];
        [thread setThreadPriority:threadPriority];
        [thread setName:threadName];
        [thread start];
        
        self.workerThread = thread;
    }
}

- (void) addTask:(dispatch_block_t)block
{
    @synchronized(self) {
        [queue addObject:block];
    }
}

- (dispatch_block_t) nextTask
{
    @synchronized(self) {
        dispatch_block_t block = nil;
        if ([queue count] > 0) {
            block = [queue firstObject];
            [queue removeObjectAtIndex:0];
        }
        return block;
    }    
}

- (void) dispatchAsync:(dispatch_block_t)block
{
    [self createThreadIfNeeded];
    [self addTask:block];
    [worker checkForTask];
}

@end

@implementation Worker {
    BOOL isCancelled;
    dispatch_semaphore_t semaphore;
}

- (id) init
{
    self = [super init];
    if (self) {
        semaphore = dispatch_semaphore_create(0);
        isCancelled = NO;
    }
    return self;
}

- (void) main
{
    NSLog(@"Thread started %@",self);
    while (![self isCancelled]) {

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_block_t block = [self.provider nextTask];
        if (block) {
            block();
        }
    }
    
     NSLog(@"Thread stopped %@",self);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p, priority=%g, name=%@>",[self class],self,[NSThread threadPriority],[[NSThread currentThread] name]];
}

- (BOOL) isCancelled
{
    @synchronized(self) {
        return isCancelled;
    }
}

- (void) cancel
{
    @synchronized(self) {
        isCancelled = YES;
        dispatch_semaphore_signal(semaphore);
    }
}

- (void) checkForTask
{
    dispatch_semaphore_signal(semaphore);
}

@end


