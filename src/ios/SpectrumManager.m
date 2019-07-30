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
//    NSString* imageId  = config[@"id"];
    NSString* sourcePath  = config[@"sourcePath"];
    NSString* destinationPath  = config[@"destinationPath"];
    NSNumber* targetSize = config[@"targetSize"];
    
    if (!sourcePath) {
        return [self returnResult:command withMsg:@"missing source path" success:false];
    }
    
    if (!destinationPath) {
        return [self returnResult:command withMsg:@"missing destination path" success:false];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourcePath] ) {
        return [self returnResult:command withMsg:@"source file does not exists" success:false];
    }
    CGSize desiredSize = !targetSize ? CGSizeZero : CGSizeMake(targetSize.intValue, targetSize.intValue);
    [self transcodeImageAtPath:sourcePath toPath:destinationPath targetSize:desiredSize onCompletion:^(NSError * error, NSString *finalPath) {
        if (error){
             return [self returnResult:command withMsg: error.localizedDescription success:false];
        }else{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:@{@"transcodePath": finalPath}];
            [pluginResult setKeepCallback:@YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];

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
                                       userInfo:@{
                                                  NSLocalizedDescriptionKey:@"invalid source file"
                                                  }];
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
