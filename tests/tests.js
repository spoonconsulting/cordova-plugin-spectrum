/* global CordovaExif, SpectrumManager, TestUtils */

exports.defineAutoTests = function () {
  describe('Spectrum', function () {
    // increase the timeout since android emulators run without acceleration on Travis and are very slow
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 70000

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
      TestUtils.copyFileToDataDirectory(sampleFile).then(function (path) {
        TestUtils.getFileSize(path).then(function (originalSize) {
          SpectrumManager.compressImage({
            sourcePath: path
          }, function () {
            TestUtils.getFileSize(path).then(function (newSize) {
              expect(newSize).toBeGreaterThan(0)
              expect(newSize).toBeLessThan(originalSize)
              TestUtils.deleteFile(sampleFile).then(done)
            })
          }, function (err) {
            console.err(err)
          })
        })
      })
    })

    it('preserves exif on compressed image', function (done) {
      var sampleFile = 'tree.jpg'
      TestUtils.copyFileToDataDirectory(sampleFile).then(function (path) {
        SpectrumManager.compressImage({
          sourcePath: path
        }, function () {
          CordovaExif.readData(path, function (exif) {
            expect(Object.keys(exif).length).toBeGreaterThan(0)
            expect(exif.Make).toBe('google')
            expect(parseFloat(exif.ShutterSpeedValue.toFixed(2))).toBe(11.22)
            TestUtils.deleteFile(sampleFile).then(done)
          })
        }, function (err) {
          console.err(err)
        })
      })
    })

    it('compresses image without changing its dimension', function (done) {
      var sampleFile = 'tree.jpg'
      TestUtils.copyFileToDataDirectory(sampleFile).then(function (path) {
        TestUtils.getImageDimensions(path).then(function (originalDimension) {
          SpectrumManager.compressImage({
            sourcePath: path
          }, function () {
            TestUtils.getImageDimensions(path).then(function (resizedDimension) {
              expect(resizedDimension.width).toBe(originalDimension.width)
              expect(resizedDimension.height).toBe(originalDimension.height)
              TestUtils.deleteFile(sampleFile).then(done)
            })
          }, function (err) {
            console.err(err)
          })
        })
      })
    })
  })
}
