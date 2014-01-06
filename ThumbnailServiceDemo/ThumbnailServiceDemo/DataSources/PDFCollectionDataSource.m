//
//  PDFCollectionDataSource.m
//  ThumbnailServiceDemo
//
//  Created by Sovelu on 12.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "PDFCollectionDataSource.h"
#import <ThumbnailService/ThumbnailService.h>

#import "PreviewCollectionCell.h"


@implementation PDFCollectionDataSource {
    CGPDFDocumentRef document;
    ThumbnailService *thumbnailService;
    NSString *documentName;
}

- (id) init
{
    self = [super init];
    if (self) {
        documentName = @"sample";
        NSURL *documentURL = [[NSBundle mainBundle] URLForResource:documentName withExtension:@"pdf"];
        document = CGPDFDocumentCreateWithURL((__bridge CFURLRef)documentURL);
        
        thumbnailService = [ThumbnailService new];
    }
    return self;
}

- (void)dealloc
{
    CGPDFDocumentRelease(document);
}

- (void)setShouldPrecache:(BOOL)_shouldPrecache
{
    if (_shouldPrecache) {
        [self startPrecache];
    }
}

- (void)setUseMemoryCache:(BOOL)_useMemoryCache
{
    thumbnailService.useMemoryCache = _useMemoryCache;
}

- (void) setUseFileCache:(BOOL)_useFileCache
{
    thumbnailService.useFileCache = _useFileCache;
}

- (void) startPrecache
{
    [self precachePagesFromIndex:1];
}


- (void) precachePagesFromIndex:(NSInteger)i
{
    NSUInteger pagesCount = CGPDFDocumentGetNumberOfPages(document);
    
    static CFAbsoluteTime timeBeforePrecache;

    if (i == 1) {
        timeBeforePrecache = CFAbsoluteTimeGetCurrent();
    }
    
    if (i < pagesCount) {
        __weak typeof (self) weakSelf = self;
        
        TSRequest *request = [TSRequest new];
        
        CGPDFPageRef page = CGPDFDocumentGetPage(document, i);
        TSSourcePDFPage *pageSource = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
        request.source = pageSource;
        request.size = kSmallThumbnailSize;
        request.queuePriority = NSOperationQueuePriorityVeryLow;
        request.shouldCacheInMemory = NO;
        [request setThumbnailCompletion:^(UIImage *result, NSError *error) {
            [weakSelf precachePagesFromIndex:i+1];
        }];
        if (![thumbnailService hasDiskCacheForRequest:request]) {
            [thumbnailService enqueueRequest:request];
        } else {
            [self precachePagesFromIndex:i+1];
        }
    } else {
        NSLog(@"all pdf pages precached for %g sec",CFAbsoluteTimeGetCurrent()-timeBeforePrecache);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return CGPDFDocumentGetNumberOfPages(document);
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionCell" forIndexPath:indexPath];
    
    if (viewCell.context) {
        TSRequest *group = viewCell.context;
        [group cancel];
        viewCell.imageView.image = nil;
    }
    
    CGPDFPageRef page = CGPDFDocumentGetPage(document, [indexPath item]+1);
    
    TSSourcePDFPage *pageSource = [[TSSourcePDFPage alloc] initWithPdfPage:page documentName:documentName];
    
    
    TSRequest *smallThumbRequest = [TSRequest new];
    smallThumbRequest.source = pageSource;
    smallThumbRequest.size = kSmallThumbnailSize;
    smallThumbRequest.queuePriority = TSRequestQueuePriorityVeryHigh;
    [smallThumbRequest setPlaceholderCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
    }];
    [smallThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
        if (!result) {
            NSLog(@"small thumb error: %@",error);
        }
    }];
    
    TSRequest *bigThumbRequest = [TSRequest new];
    bigThumbRequest.source = pageSource;
    bigThumbRequest.size = kBigThumbSize;
    bigThumbRequest.queuePriority = TSRequestQueuePriorityHigh;
    
    [bigThumbRequest setThumbnailCompletion:^(UIImage *result, NSError *error) {
        viewCell.imageView.image = result;
        if (!result) {
            NSLog(@"big thumb error: %@",error);
        }

    }];
    
    if ([thumbnailService hasDiskCacheForRequest:smallThumbRequest]) {
        [thumbnailService executeRequest:smallThumbRequest];
        [thumbnailService enqueueRequest:bigThumbRequest];
        viewCell.context = bigThumbRequest;
    } else {
        TSRequestGroupSequence *group = [TSRequestGroupSequence new];
        [group addRequest:smallThumbRequest];
        [group addRequest:bigThumbRequest];
        [thumbnailService enqueueRequestGroup:group];
        viewCell.context = group;
    }
    
    return viewCell;
}

@end
