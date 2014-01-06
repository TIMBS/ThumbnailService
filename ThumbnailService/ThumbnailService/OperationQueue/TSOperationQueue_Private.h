//
//  TSOperationQueue_Private.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 05.01.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import "TSOperationQueue.h"
#import "TSOperation.h"

@interface TSOperationQueue ()

- (void) enqueueBlock:(dispatch_block_t)block onPriority:(TSOperationDispatchQueuePriority)priority;

@end
