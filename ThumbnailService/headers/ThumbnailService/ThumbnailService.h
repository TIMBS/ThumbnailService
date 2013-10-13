//
//  ThumbnailService.h
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSRequest.h"
#import "TSRequestGroupSequence.h"

@interface ThumbnailService : NSObject

@property (nonatomic) BOOL shouldCachePlaceholders; /* Default: NO */

@property (nonatomic) BOOL useMemoryCache; /* Default: YES */
@property (nonatomic) BOOL useFileCache;   /* Default: YES */


- (void) performRequest:(TSRequest *)request;

- (void) performRequestOnMainThread:(TSRequest *)request;

- (void) performRequestGroup:(TSRequestGroup *)group;

- (void) clearFileCache;

@end
