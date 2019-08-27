/* global cordova */
/* global SpectrumManager */
/* global CordovaExif */

exports.defineAutoTests = function () {
  describe('Spectrum', function () {
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 90000
    function copyFileToDataDirectory (fileName) {
      return new Promise(function (resolve, reject) {
        console.log('Copying :' + fileName + ' ' + cordova.file.applicationDirectory)
        window.resolveLocalFileSystemURL(cordova.file.applicationDirectory + fileName, function (fileEntry) {
          window.resolveLocalFileSystemURL(cordova.file.dataDirectory, function (directory) {
            console.log('copy to ', directory.nativeURL)
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
          }, function (err) { console.err(err) }
          )
        })
      })

      it('preserves exif on compressed image', function (done) {
        var sampleFile = 'tree.jpg'
        copyFileToDataDirectory(sampleFile).then(function (path) {
          CordovaExif.readData(path, function (exif) {
            expect(Object.keys(exif).length).toBeGreaterThan(0)
            expect(exif.Make).toBe('google')
            expect(exif.ShutterSpeedValue).toBe(11.22)
            deleteFile(sampleFile).then(done)
          })
        })
      })
    })
  })
}
