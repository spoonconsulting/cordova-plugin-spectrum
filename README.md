
# cordova-plugin-spectrum
[![Build Status](https://travis-ci.org/spoonconsulting/cordova-plugin-spectrum.svg?branch=master)](https://travis-ci.org/spoonconsulting/cordova-plugin-spectrum)

Cordova plugin wrapper for [Spectrum](https://libspectrum.io/) image compression library

**Supported Platforms**
- iOS
- Android


**Installation**

To install the plugin:

```
cordova plugin add cordova-plugin-spectrum --save
```

To uninstall this plugin:
```
cordova plugin rm cordova-plugin-spectrum
```

**Sample usage**

`compressImage` takes an options object which should include the path to the image. This image will be compressed and overwritten by the new one.
You need to ensure that the file is in writable path.
```javascript
    SpectrumManager.compressImage({
        sourcePath: path
    }, function () {
        console.log('compressed image availble at ', path);
    }, function (err) {
        console.err('could not compress image ',err)
    })
```
## License
Cordova-plugin-spectrum is licensed under the Apache v2 License.

## Credits
Cordova-plugin-spectrum is brought to you by [Spoon Consulting](http://www.spoonconsulting.com/).
