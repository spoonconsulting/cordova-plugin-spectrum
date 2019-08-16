//
//  SpectrumManager.m
//  Spoon Consulting
//
//  Created by Spoon Consulting on 30/07/2019.
//

#import "SpectrumManager.h"
#import "CDVFile.h"
@implementation SpectrumManager
-(void)compressImage:(CDVInvokedUrlCommand*)command{
    NSDictionary* config = command.arguments[0];
    NSString* sourcePath = config[@"sourcePath"];
    NSNumber* targetSize = config[@"targetSize"];
    
    if (!sourcePath)
        return [self returnErrorResult:command withMsg:@"missing source path"];
    
    if (!spectrum)
        spectrum = [[FSPSpectrum alloc] initWithPlugins:@[[FSPJpegPlugin new], [FSPPngPlugin new]] configuration:nil];
    sourcePath = [self resolveNativePath: sourcePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourcePath])
        return [self returnErrorResult:command withMsg:@"source file does not exists"];
    
    NSString* currentFolderPath = [sourcePath stringByDeletingLastPathComponent];
    NSString* timestampName = [NSString stringWithFormat:@"%f.%@",[[NSDate date] timeIntervalSince1970] * 1000, [sourcePath pathExtension]];
    NSString* destinationPath = [currentFolderPath stringByAppendingPathComponent:timestampName];
    CGSize desiredSize = !targetSize ? CGSizeZero : CGSizeMake(targetSize.intValue, targetSize.intValue);
    [self.commandDelegate runInBackground:^{
        [self transcodeImageAtPath:sourcePath toPath:destinationPath targetSize:desiredSize onCompletion:^(NSError * error, NSString *finalPath) {
            if (!error){
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager removeItemAtPath:sourcePath error:nil]){
                    [fileManager copyItemAtPath:destinationPath toPath:sourcePath error:nil];
                    [fileManager removeItemAtPath:destinationPath error:nil];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error){
                    return [self returnErrorResult:command withMsg:error.localizedDescription];
                }else{
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                    [pluginResult setKeepCallback:@YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
        }];
    }];
    
}
-(NSString*)resolveNativePath:(NSString*)path{
    CDVFile *filePlugin = [self.commandDelegate getCommandInstance:@"File"];
    CDVFilesystemURL *url = [CDVFilesystemURL fileSystemURLWithString:path];
    NSString* cdvFilePath = [filePlugin filesystemPathForURL:url];
    return cdvFilePath? cdvFilePath : path;
}
-(void)returnErrorResult:(CDVInvokedUrlCommand *) command withMsg: (NSString*)msg{
    NSString* sourcePath = ((NSDictionary*)command.arguments[0])[@"sourcePath"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@ : %@", msg, sourcePath]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
-(void)transcodeImageAtPath:(NSString*)path toPath:(NSString*)targetPath targetSize:(CGSize)targetSize onCompletion:(void (^)(NSError* error, NSString* finalPath))handler{
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    if (!image) {
        NSError *err = [NSError errorWithDomain:@"com.plugin-spectrum.error"
                                           code:100
                                       userInfo:@{NSLocalizedDescriptionKey:[@"invalid source file: " stringByAppendingString:path]}];
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
    
    NSData* data = UIImageJPEGRepresentation(image, 1.0);
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    FSPEncodeOptions *options =
    [FSPEncodeOptions encodeOptionsWithEncodeRequirement:encodeRequirement
                                         transformations:transformations
                                                metadata:[FSPImageMetadata imageMetadataWithDictionary:metadata]
                                           configuration:nil
                     outputPixelSpecificationRequirement:nil];
    
    NSError *error;
    [spectrum encodeImage:image toFileAtURL:[NSURL fileURLWithPath:targetPath] options:options error:&error];
    if (error){
        return handler(error, nil);
    } else {
        handler(nil, targetPath);
    }
}
@end
