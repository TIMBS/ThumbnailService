//
//  RequestsTests.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 13.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ThumbnailService.h"
#import "TSSourceTest.h"

#import "TestUtils.h"
#import "ThumbnailService+Testing.h"

@interface RequestsGroupTests : XCTestCase

@end

@implementation RequestsGroupTests {
    ThumbnailService *thumbnailService;
}

- (void)setUp
{
    [super setUp];
    
    thumbnailService = [[ThumbnailService alloc] init];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testGroupNormalCompletion
{
    __block int thumbnailCalled = 0;
    __block int placeholderCalled = 0;
    
    TSRequestCompletion placeholderCompletion = ^(UIImage *result, NSError *error) {
        placeholderCalled++;
    };
    TSRequestCompletion thumbnailCompletion = ^(UIImage *result, NSError *error) {
        thumbnailCalled++;
    };
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request1 = [TSRequest new];
    request1.source = source;
    request1.size = CGSizeMake(100, 100);
    request1.queuePriority = NSOperationQueuePriorityHigh;
    [request1 setPlaceholderCompletion:placeholderCompletion];
    [request1 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request2 = [TSRequest new];
    request2.source = source;
    request2.size = CGSizeMake(200, 200);
    request2.queuePriority = NSOperationQueuePriorityNormal;
    [request2 setPlaceholderCompletion:placeholderCompletion];
    [request2 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request3 = [TSRequest new];
    request3.source = source;
    request3.size = CGSizeMake(300, 300);
    request3.queuePriority = NSOperationQueuePriorityLow;
    [request3 setPlaceholderCompletion:placeholderCompletion];
    [request3 setThumbnailCompletion:thumbnailCompletion];
    
    request1.shouldCastCompletionsToMainThread = NO;
    request2.shouldCastCompletionsToMainThread = NO;
    request3.shouldCastCompletionsToMainThread = NO;
    
    TSRequestGroupSequence *group = [TSRequestGroupSequence new];
    [group addRequest:request1];
    [group addRequest:request2];
    [group addRequest:request3];
    
    [thumbnailService enqueueRequestGroup:group];
    
    WaitAndCallInBackground(0.2, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(0.4, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(0.6, ^{
        [source fire];
    });
    
    [group waitUntilFinished];
    
    XCTAssert(thumbnailCalled == 3, @"Called: %d", thumbnailCalled);
    XCTAssert(placeholderCalled == 3, @"Called: %d",placeholderCalled);
    
}

- (void) testGroupCancel
{
    __block int thumbnailCalled = 0;
    
    TSRequestCompletion thumbnailCompletion = ^(UIImage *result, NSError *error) {
        thumbnailCalled++;
    };
    
    TSSourceTest *source = [TSSourceTest new];
    
    TSRequest *request1 = [TSRequest new];
    request1.source = source;
    request1.size = CGSizeMake(100, 100);
    request1.queuePriority = NSOperationQueuePriorityHigh;
    [request1 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request2 = [TSRequest new];
    request2.source = source;
    request2.size = CGSizeMake(200, 200);
    request2.queuePriority = NSOperationQueuePriorityNormal;
    [request2 setThumbnailCompletion:thumbnailCompletion];
    
    TSRequest *request3 = [TSRequest new];
    request3.source = source;
    request3.size = CGSizeMake(300, 300);
    request3.queuePriority = NSOperationQueuePriorityLow;
    [request3 setThumbnailCompletion:thumbnailCompletion];
    
    request1.shouldCastCompletionsToMainThread = NO;
    request2.shouldCastCompletionsToMainThread = NO;
    request3.shouldCastCompletionsToMainThread = NO;
    
    TSRequestGroupSequence *group = [TSRequestGroupSequence new];
    [group addRequest:request1];
    [group addRequest:request2];
    [group addRequest:request3];
    
    [thumbnailService enqueueRequestGroup:group];
    
    WaitAndCallInBackground(0.2, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(0.4, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(0.6, ^{
        [source fire];
    });
    
    WaitAndCallInBackground(0.41, ^{
        [group cancel];
    });
    
    [group waitUntilFinished];
    
    XCTAssert(thumbnailCalled == 2, @"Called: %d", thumbnailCalled);
    
}

@end
