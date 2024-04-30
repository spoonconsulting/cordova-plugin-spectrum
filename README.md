
# cordova-plugin-spectrum
[![Build Status](https://travis-ci.org/spoonconsulting/cordova-plugin-spectrum.svg?branch=master)](https://travis-ci.org/spoonconsulting/cordova-plugin-spectrum)

Cordova plugin wrapper for [Spectrum](https://libspectrum.io/) image compression library

**Removal of Spectrum**
cordova-ios 7 will no longer support framework tag for pod installation and Spectrum sdk is no more maintained and will not provide support for its SDK to use framework. The compression logics have been replaced by native api for both platforms.


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

**Methods**

`compressImage(config, success, error)`

Compresses the image and overwrites by the new one. You need to ensure that the file is in writable path.
The following properties are available:

Property | Comment
-------- | -------
sourcePath | Path to the image
maxSize | Resize the image to the specified size preserving aspect ratio (optional)

**Sample usage**

```javascript
SpectrumManager.compressImage({
    sourcePath: path,
    maxSize: 300
}, function () {
    console.log('compressed image available at ', path);
}, function (err) {
    console.err('could not compress image ',err)
})
```
## License
Cordova-plugin-spectrum is licensed under the Apache v2 License.

## Credits
Cordova-plugin-spectrum is brought to you by [Spoon Consulting](http://www.spoonconsulting.com/).
