//
//  SpectrumManager.h
//  Spoon Consulting
//
//  Created by Spoon Consulting on 30/07/2019.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
NS_ASSUME_NONNULL_BEGIN

@interface SpectrumManager : CDVPlugin{
    FSPSpectrum *spectrum;
}
-(void)compressImage:(CDVInvokedUrlCommand*)command;
@end

NS_ASSUME_NONNULL_END
