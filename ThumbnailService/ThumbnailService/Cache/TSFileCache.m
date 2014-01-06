//
//  FileCache.m
//  ThumbnailService
//
//  Created by Aleksey Garbarev on 09.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import "TSFileCache.h"
#import "TSBackgroundThreadQueue.h"

static NSString *kCacheExtensionImage  = @"image";
static NSString *kCacheExtensionObject = @"object";

@implementation TSFileCache {
    NSFileManager *fileManager;
    NSString *_cacheDirectory;
    TSBackgroundThreadQueue *fileCacheQueue;
}

- (id) init
{
    self = [super init];
    if (self) {
        fileManager = [NSFileManager defaultManager];
        [self createCacheDirectory];
        
        
        fileCacheQueue = [[TSBackgroundThreadQueue alloc] initWithName:@"TSFileCacheQueue" threadPriority:0.4];
        
        self.imageWriteMode = TSFileCacheImageWriteModePNG;
        self.imageWriteCompressionQuality = 0.6;
    }
    return self;
}

#pragma mark - NSCache overrides

- (id) objectForKey:(id)key
{
    __block id object = nil;
    
    if (![self objectExistsForKey:key]) {
        return nil;
    }
    
    NSString *extension = [self pathExtensionForKey:key];
    NSString *path = [self filePathForKey:key extension:extension];
    
    if ([extension isEqualToString:kCacheExtensionImage]) {
        object = [[UIImage alloc] initWithContentsOfFile:path];
    } else if ([extension isEqualToString:kCacheExtensionObject]){
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }

    return object;
}

- (void) setObject:(id)obj forKey:(id)key
{
    [self setObject:obj forKey:key cost:0];
}

- (void) setObject:(id)object forKey:(id)key cost:(NSUInteger)g
{
    __weak typeof (self) weakSelf = self;
    
    dispatch_block_t writeBlock = ^{
        @autoreleasepool {
            NSString *extension;
            NSData *data;
            if ([object isKindOfClass:[UIImage class]]) {
                data = [weakSelf dataFromImage:object];
                extension = [weakSelf imageExtension];
            } else {
                data = [NSKeyedArchiver archivedDataWithRootObject:object];
                extension = kCacheExtensionObject;
            }
            
            if (weakSelf) {
                NSString *path = [[[weakSelf cacheDirectory] stringByAppendingPathComponent:key] stringByAppendingPathExtension:extension];
                [data writeToFile:path options:0 error:nil];
            }
        }
    };
    
    if (self.shouldWriteAsynchronically) {
        [fileCacheQueue dispatchAsync:writeBlock];
    } else {
        writeBlock();
    }
}

- (void) removeObjectForKey:(id)key
{
    NSString *path = [self pathForKey:key];
    [fileManager removeItemAtPath:path error:nil];
}

- (void) removeAllObjects
{
    [fileManager removeItemAtPath:[self cacheDirectory] error:nil];
    [self createCacheDirectory];
}

- (void) setName:(NSString *)n
{
    [super setName:n];
    [self updateCacheDirectory];
    [self createCacheDirectory];
}

- (NSString *) name
{
    return [super name];
}

#pragma mark -

- (id) objectWithContentsOfPath:(NSString *)path
{
    id object;
    
    if ([[path pathExtension] isEqualToString:kCacheExtensionImage]) {
        object = [UIImage imageWithContentsOfFile:path];
    } else {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    
    return object;
}

#pragma mark - Paths

- (NSString *) filePathForKey:(NSString *)key extension:(NSString *)extension
{
    return [[[self cacheDirectory] stringByAppendingPathComponent:key] stringByAppendingPathExtension:extension];
}

- (NSString *) pathForKey:(NSString *)key
{
    NSString *extension = [self pathExtensionForKey:key];
    return [self filePathForKey:key extension:extension];
}

- (BOOL) objectExistsForKey:(NSString *)key
{
    return [self pathExtensionForKey:key] != nil;
}

- (NSString *) pathExtensionForKey:(NSString *)key
{
    NSString *extension = nil;
    if ([self objectExistsForKey:key andExtension:kCacheExtensionImage]) {
        extension = kCacheExtensionImage;
    } else if ([self objectExistsForKey:key andExtension:kCacheExtensionObject]){
        extension = kCacheExtensionObject;
    }
    return extension;
}

- (BOOL) objectExistsForKey:(NSString *)key andExtension:(NSString *)extension
{
    NSString *path = [[[self cacheDirectory] stringByAppendingPathComponent:key] stringByAppendingPathExtension:extension];
    return [fileManager fileExistsAtPath:path];
}

#pragma mark - Cache Directory

- (void) updateCacheDirectory
{
    NSString *rootCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    _cacheDirectory = [rootCacheDirectory stringByAppendingPathComponent:[self name]];
}

- (NSString *) cacheDirectory
{
    return _cacheDirectory;
}

- (void) createCacheDirectory
{
    [fileManager createDirectoryAtPath:[self cacheDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
}

#pragma mark - Image Compression

- (NSData *) dataFromImage:(UIImage *)image
{
    NSData *imageData = nil;
    if (self.imageWriteMode == TSFileCacheImageWriteModeJPG) {
        imageData = UIImageJPEGRepresentation(image, self.imageWriteCompressionQuality);
    } else if (self.imageWriteMode == TSFileCacheImageWriteModePNG) {
        imageData = UIImagePNGRepresentation(image);
    } else {
        imageData = [NSKeyedArchiver archivedDataWithRootObject:image];
    }
    return imageData;
}

- (NSString *) imageExtension
{
    NSString *imageExtension;
    if (self.imageWriteMode == TSFileCacheImageWriteModeBase64) {
        imageExtension = kCacheExtensionObject;
    } else {
        imageExtension = kCacheExtensionImage;
    }
    return imageExtension;
}

@end
