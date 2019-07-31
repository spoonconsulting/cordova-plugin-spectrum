//
//  SpectrumManager.m
//  Spoon Consulting
//
//  Created by Spoon Consulting on 30/07/2019.
//

#import "SpectrumManager.h"

@implementation SpectrumManager
-(void)transcodeImage:(CDVInvokedUrlCommand*)command{
    NSDictionary* config = command.arguments[0];
    NSString* sourcePath  = config[@"sourcePath"];
    NSString* destinationPath  = config[@"destinationPath"];
    NSNumber* targetSize = config[@"targetSize"];
    
    if (!sourcePath) {
        return [self returnResult:command withMsg:@"missing source path" success:false];
    }
    
    sourcePath = [sourcePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourcePath] ) {
        return [self returnResult:command withMsg:@"source file does not exists" success:false];
    }
    BOOL shouldReplaceOriginalFile = !destinationPath || [destinationPath isEqualToString:sourcePath];
    if (shouldReplaceOriginalFile) {
        NSString* currentFolderPath = [sourcePath stringByDeletingLastPathComponent];
        NSString * timestampName = [NSString stringWithFormat:@"%f.%@",[[NSDate date] timeIntervalSince1970] * 1000, [sourcePath pathExtension]];
        destinationPath = [currentFolderPath stringByAppendingPathComponent:timestampName];
    }
    destinationPath = [destinationPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    CGSize desiredSize = !targetSize ? CGSizeZero : CGSizeMake(targetSize.intValue, targetSize.intValue);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self transcodeImageAtPath:sourcePath toPath:destinationPath targetSize:desiredSize onCompletion:^(NSError * error, NSString *finalPath) {
            if (shouldReplaceOriginalFile && !error){
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager removeItemAtPath:sourcePath error:nil]){
                    [fileManager copyItemAtPath:destinationPath toPath:sourcePath error:nil];
                    [fileManager removeItemAtPath:destinationPath error:nil];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error){
                    return [self returnResult:command withMsg: error.localizedDescription success:false];
                }else{
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{}];
                    [pluginResult setKeepCallback:@YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
        }];
     });
    
}
-(void)returnResult:(CDVInvokedUrlCommand *) command withMsg: (NSString*)msg success:(BOOL)success {
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:success ? CDVCommandStatus_OK : CDVCommandStatus_ERROR messageAsString:msg];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
-(void)transcodeImageAtPath:(NSString*)path toPath:(NSString*)targetPath targetSize:(CGSize)targetSize onCompletion:(void (^)(NSError* error, NSString* finalPath))handler{
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    if (!image) {
        NSError *err = [NSError errorWithDomain:@"com.spectrum.error"
                                           code:100
                                       userInfo:@{NSLocalizedDescriptionKey:@"invalid source file"}];
        return handler(err, nil);
    }
    FSPEncodeRequirement *encodeRequirement =
    [FSPEncodeRequirement encodeRequirementWithFormat:FSPEncodedImageFormat.jpeg
                                                 mode:FSPEncodeRequirementModeLossy
                                              quality:80];
    FSPTransformations *transformations;
    if (!CGSizeEqualToSize(CGSizeZero, targetSize)) {
        transformations = [FSPTransformations new];
        transformations.resizeRequirement = [[FSPResizeRequirement alloc] initWithMode:FSPResizeRequirementModeExactOrSmaller targetSize:targetSize];
    }
    
    FSPEncodeOptions *options =
    [FSPEncodeOptions encodeOptionsWithEncodeRequirement:encodeRequirement
                                         transformations:transformations
                                                metadata:[FSPImageMetadata imageMetadataFromImage: image]
                                           configuration:nil
                     outputPixelSpecificationRequirement:nil];
    
    NSError *error;
    FSPSpectrum *spectrum = [[FSPSpectrum alloc] initWithPlugins:@[[FSPJpegPlugin new], [FSPPngPlugin new]] configuration:nil];
    FSPResult *result = [spectrum encodeImage:image toFileAtURL:[NSURL fileURLWithPath:targetPath] options:options error:&error];
    if (error){
        NSLog(@"could not transcode image %@", error.localizedDescription);
        return handler(error, nil);
    }else{
        NSLog(@"encoded image in %f secs", result.duration/1000.0);
        handler(nil, targetPath);
    }
    
}
@end
