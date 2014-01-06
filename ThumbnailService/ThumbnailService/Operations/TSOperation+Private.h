//
//  TSOperation+Private.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 18.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSOperation.h"
#import "TSOperationQueueWorker.h"

@interface TSOperation ()

@property (nonatomic, weak) TSOperationQueueWorker *worker;

- (void) onComplete;
- (void) onCancel;

@end
