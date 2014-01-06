//
//  TSOperation.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"

@class TSOperation;
typedef void(^TSOperationCompletion)(TSOperation *operation);

@interface TSOperation : NSOperation

@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

/** Completion block is unavailable, since addCompletionBlock method available */
- (void (^)(void))completionBlock NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;
- (void)setCompletionBlock:(void (^)(void))block NS_AVAILABLE(10_6, 4_0) UNAVAILABLE_ATTRIBUTE;

/* Callbacks */
- (void) addCompleteBlock:(TSOperationCompletion)completionBlock;
- (void) addCancelBlock:(TSOperationCompletion)cancelBlock;

/** dispatch_queue on which callback being called.
 *  Default: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) */
@property (nonatomic, assign) dispatch_queue_t callbackQueue;

- (BOOL) isStarted;
- (BOOL) isExecuting;
- (BOOL) isFinished;
- (BOOL) isCancelled;

@end
