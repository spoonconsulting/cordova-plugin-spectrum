/* global CordovaExif, SpectrumManager, cordova, Image, FileReader */

exports.defineAutoTests = function () {
  describe('Spectrum', function () {
    // increase the timeout since android emulators run without acceleration on Travis and are very slow
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 70000

    function copyFileToDataDirectory (fileName) {
      return new Promise(function (resolve, reject) {
        window.resolveLocalFileSystemURL(cordova.file.applicationDirectory + fileName, function (fileEntry) {
          window.resolveLocalFileSystemURL(cordova.file.dataDirectory, function (directory) {
            fileEntry.copyTo(directory, fileName, function () {
              resolve((cordova.file.dataDirectory + fileName))
            },
            function (err) {
              console.log(err)
              reject(err)
            })
          }, reject)
        }, reject)
      })
    }

    function getFileSize (imageUri) {
      return new Promise(function (resolve, reject) {
        window.resolveLocalFileSystemURI(imageUri,
          function (fileEntry) {
            fileEntry.file(function (fileObj) {
              resolve(fileObj.size / (1024 * 1024))
            },
            reject)
          }, reject)
      })
    }

    function deleteFile (fileName) {
      return new Promise(function (resolve, reject) {
        window.resolveLocalFileSystemURL(cordova.file.dataDirectory, function (dir) {
          dir.getFile(fileName, {
            create: false
          }, function (fileEntry) {
            fileEntry.remove(resolve, reject, reject)
          })
        }, reject)
      })
    }

    function getImageDimensions (imageURI) {
      return new Promise(function (resolve, reject) {
        window.resolveLocalFileSystemURL(imageURI, function (fileEntry) {
          fileEntry.file(function (fileObject) {
            var reader = new FileReader()
            reader.onloadend = function (evt) {
              var image = new Image()
              image.onload = function (evt) {
                image = null
                resolve({
                  width: this.width,
                  height: this.height
                })
              }
              image.src = evt.target.result
            }
            reader.readAsDataURL(fileObject)
          }, reject)
        })
      })
    }

    it('exposes SpectrumManager globally', function () {
      expect(SpectrumManager).toBeDefined()
    })

    it('should have compressImage function', function () {
      expect(SpectrumManager.compressImage).toBeDefined()
    })

    it('returns an error if no argument is given', function (done) {
      SpectrumManager.compressImage(null, function () {}, function (err) {
        expect(err).toBeDefined()
        expect(err.message).toBe('missing options')
        done()
      })
    })

    it('returns an error if sourcePath is not given', function (done) {
      SpectrumManager.compressImage({}, function () {}, function (err) {
        expect(err).toBeDefined()
        expect(err.message).toBe('sourcePath is missing')
        done()
      })
    })

    it('returns an error if sourcePath is invalid', function (done) {
      SpectrumManager.compressImage({
        sourcePath: 'invalid url'
      }, function () {}, function (err) {
        expect(err).toBeDefined()
        done()
      })
    })

    it('compresses an image', function (done) {
      var sampleFile = 'tree.jpg'
      copyFileToDataDirectory(sampleFile).then(function (path) {
        getFileSize(path).then(function (originalSize) {
          SpectrumManager.compressImage({
            sourcePath: path
          }, function () {
            getFileSize(path).then(function (newSize) {
              expect(newSize).toBeGreaterThan(0)
              expect(newSize).toBeLessThan(originalSize)
              deleteFile(sampleFile).then(done)
            })
          }, function (err) {
            console.err(err)
          })
        })
      })
    })

    it('preserves exif on compressed image', function (done) {
      var sampleFile = 'tree.jpg'
      copyFileToDataDirectory(sampleFile).then(function (path) {
        SpectrumManager.compressImage({
          sourcePath: path
        }, function () {
          CordovaExif.readData(path, function (exif) {
            expect(Object.keys(exif).length).toBeGreaterThan(0)
            expect(exif.Make).toBe('google')
            expect(exif.ShutterSpeedValue).toBe(11.22)
            deleteFile(sampleFile).then(done)
          })
        }, function (err) {
          console.err(err)
        })
      })
    })

    it('compresses image without changing its dimesion', function (done) {
      var sampleFile = 'tree.jpg'
      copyFileToDataDirectory(sampleFile).then(function (path) {
        getImageDimensions(path).then(function (originalDimension) {
          SpectrumManager.compressImage({
            sourcePath: path
          }, function () {
            getImageDimensions(path).then(function (resizedDimension) {
              expect(resizedDimension.width).toBe(originalDimension.width)
              expect(resizedDimension.height).toBe(originalDimension.height)
              deleteFile(sampleFile).then(done)
            })
          }, function (err) {
            console.err(err)
          })
        })
      })
    })
  })
}
