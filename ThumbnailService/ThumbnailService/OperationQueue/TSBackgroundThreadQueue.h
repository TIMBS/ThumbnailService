//
//  SerialQueue.h
//  SerialQueue
//
//  Created by Aleksey Garbarev on 05.01.14.
//  Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface TSBackgroundThreadQueue : NSObject

- (id) initWithName:(NSString *)name threadPriority:(CGFloat)threadPriority;

- (void) dispatchAsync:(dispatch_block_t)block;

@end
