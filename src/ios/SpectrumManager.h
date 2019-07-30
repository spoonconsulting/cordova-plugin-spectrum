//
//  SpectrumManager.h
//  Spoon Consulting
//
//  Created by Spoon Consulting on 30/07/2019.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <SpectrumKit/SpectrumKit.h>
#import <SpectrumKit/FSPJpegPlugin.h>
#import <SpectrumKit/FSPPngPlugin.h>
NS_ASSUME_NONNULL_BEGIN

@interface SpectrumManager : CDVPlugin
-(void)transcodeImage:(CDVInvokedUrlCommand*)command;
@end

NS_ASSUME_NONNULL_END
