//
//  TSOperationQueueWorker.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 06.01.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>

/** TSOperationQueueWorker - object which can perform block on specified thread priority */
@interface TSOperationQueueWorker : NSObject

/** Enqueue block to perform on specified thread priority. If thread with this priority is not exists - creates new thread for this priority.
  * @b Important Useful to run blocks on small set of priorities. Useless to run blocks on a lot of different priorities because threads will be created for each prioritet */
- (void) enqueueBlock:(dispatch_block_t)block onThreadPriority:(double)priority;

@end
