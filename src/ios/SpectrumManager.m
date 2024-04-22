//
//  SpectrumManager.m
//  Spoon Consulting
//
//  Created by Spoon Consulting on 30/07/2019.
//

#import "SpectrumManager.h"
#import "CDVFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
@implementation SpectrumManager
-(void)compressImage:(CDVInvokedUrlCommand*)command{
    [self.commandDelegate runInBackground:^{
        @try {
            [self startImageCompression:command];
        } @catch (NSException *exception) {
            [self returnErrorResult:command forException:exception];
        }
    }];
}
-(void)returnErrorResult:(CDVInvokedUrlCommand*)command forException:(NSException*)exception{
    NSString* message = [NSString stringWithFormat:@"(%@) - %@", exception.name, exception.reason];
    [self returnErrorResult: command withMsg:message];
}

-(void)returnErrorResult:(CDVInvokedUrlCommand*) command withMsg: (NSString*)msg{
    NSString* sourcePath = ((NSDictionary*)command.arguments[0])[@"sourcePath"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@ : %@", msg, sourcePath]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)startImageCompression:(CDVInvokedUrlCommand*)command{
    NSDictionary* config = command.arguments[0];
    NSString* sourcePath = config[@"sourcePath"];
    
    if (!sourcePath)
        return [self returnErrorResult:command withMsg:@"Missing source path"];
    
    sourcePath = [self resolveNativePath: sourcePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourcePath])
        return [self returnErrorResult:command withMsg:@"Source file does not exist"];
    
    NSString* currentFolderPath = [sourcePath stringByDeletingLastPathComponent];
    NSString* timestampName = [NSString stringWithFormat:@"%f.%@",[[NSDate date] timeIntervalSince1970] * 1000, [sourcePath pathExtension]];
    NSString* destinationPath = [currentFolderPath stringByAppendingPathComponent:timestampName];
    UIImage* image = [UIImage imageWithContentsOfFile:sourcePath];
    NSData *compressedImageData = UIImageJPEGRepresentation(image, 0.8);
    
    CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:sourcePath], NULL);
    NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
    
    NSError *writeError = nil;
    BOOL success = [compressedImageData writeToFile:destinationPath options:NSDataWritingAtomic error:&writeError];
    if (!success) {
        return [self returnErrorResult:command withMsg:writeError.localizedDescription];
    } else {
        CGImageDestinationRef destinationRef = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:destinationPath], kUTTypeJPEG, 1, NULL);
        if (destinationRef) {
            CGImageDestinationAddImageFromSource(destinationRef, sourceRef, 0, (__bridge CFDictionaryRef)metadata);
            success = CGImageDestinationFinalize(destinationRef);
            CFRelease(destinationRef);
        }
        
        if (!success) {
            return [self returnErrorResult:command withMsg:@"Failed to copy metadata"];
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager removeItemAtPath:sourcePath error:nil]) {
            [fileManager copyItemAtPath:destinationPath toPath:sourcePath error:nil];
            [fileManager removeItemAtPath:destinationPath error:nil];
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [pluginResult setKeepCallback:@YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(NSString*)resolveNativePath:(NSString*)path{
    CDVFile *filePlugin = [self.commandDelegate getCommandInstance:@"File"];
    CDVFilesystemURL *url = [CDVFilesystemURL fileSystemURLWithString:path];
    NSString* cdvFilePath = [filePlugin filesystemPathForURL:url];
    return cdvFilePath? cdvFilePath : path;
}
@end
