/* global CordovaExif, SpectrumManager, TestUtils */

exports.defineAutoTests = function () {
  describe('Spectrum', function () {
    // increase the timeout since android emulators run without acceleration on Travis and are very slow
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 80000

    var sampleFile = 'tree.jpg'
    var path = ''

    beforeEach(function (done) {
      TestUtils.copyFileToDataDirectory(sampleFile).then(function (newPath) {
        path = newPath
        done()
      })
    })

    afterEach(function (done) {
      TestUtils.deleteFile(sampleFile).then(done)
    })

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
      TestUtils.getFileSize(path).then(function (originalSize) {
        SpectrumManager.compressImage({
          sourcePath: path
        }, function () {
          TestUtils.getFileSize(path).then(function (newSize) {
            expect(newSize).toBeGreaterThan(0)
            expect(newSize).toBeLessThan(originalSize)
            done()
          })
        }, function (err) {
          console.log(err)
        })
      })
    })

    it('preserves exif on compressed image', function (done) {
      CordovaExif.readData(path, function (originalExif) {
        SpectrumManager.compressImage({
          sourcePath: path
        }, function () {
          CordovaExif.readData(path, function (exif) {
            expect(Object.keys(exif).length).toBeGreaterThan(0)
            expect(exif.Make).toBe(originalExif.Make)
            expect(parseFloat(exif.ShutterSpeedValue.toFixed(2))).toBe(parseFloat(originalExif.ShutterSpeedValue.toFixed(2)))
            done()
          })
        }, function (err) {
          console.log(err)
        })
      })
    })

    it('compresses image without resizing if tagetSize is not specified', function (done) {
      TestUtils.getImageDimensions(path).then(function (originalDimension) {
        SpectrumManager.compressImage({
          sourcePath: path
        }, function () {
          TestUtils.getImageDimensions(path).then(function (resizedDimension) {
            expect(resizedDimension.width).toBe(originalDimension.width)
            expect(resizedDimension.height).toBe(originalDimension.height)
            done()
          })
        }, function (err) {
          console.log(err)
        })
      })
    })

    it('compresses and resizes image', function (done) {
      SpectrumManager.compressImage({
        sourcePath: path,
        maxSize: 500
      }, function () {
        TestUtils.getImageDimensions(path).then(function (resizedDimension) {
          expect(resizedDimension.height).toBe(500)
          done()
        })
      }, function (err) {
        console.log(err)
      })
    })
  })
}
