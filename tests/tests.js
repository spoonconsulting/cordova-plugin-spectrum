/* global cordova */
/* global SpectrumManager */
exports.defineAutoTests = () => {
  describe('Spectrum', () => {
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

    it('exposes SpectrumManager globally', () => {
      expect(SpectrumManager).toBeDefined()
    })

    it('should have compressImage function', () => {
      expect(SpectrumManager.compressImage).toBeDefined()
    })

    it('returns an error if no argument is given', (done) => {
      SpectrumManager.compressImage(null, () => {}, err => {
        expect(err).toBeDefined()
        expect(err.message).toBe('missing options')
        done()
      })
    })

    it('returns an error if sourcePath is not given', (done) => {
      SpectrumManager.compressImage({}, () => {}, err => {
        expect(err).toBeDefined()
        expect(err.message).toBe('sourcePath is missing')
        done()
      })
    })

    it('returns an error if sourcePath is invalid', (done) => {
      SpectrumManager.compressImage({
        sourcePath: 'invalid url'
      }, () => {}, err => {
        expect(err).toBeDefined()
        done()
      })
    })

    it('compresses an image', (done) => {
      var sampleFile = 'tree.jpg'
      copyFileToDataDirectory(sampleFile).then(path => {
        getFileSize(path).then(originalSize => {
          SpectrumManager.compressImage({
            sourcePath: path
          }, () => {
            getFileSize(path).then(newSize => {
              expect(newSize).toBeGreaterThan(0)
              expect(newSize).toBeLessThan(originalSize)
              deleteFile(sampleFile).then(done)
            })
          }, err => console.err(err))
        })
      })
    })
  })
}
