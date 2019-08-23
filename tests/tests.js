exports.defineAutoTests = () => {
  describe("Spectrum", () => {
    it("exposes SpectrumManager globally", () => {
      expect(SpectrumManager).toBeDefined();
    });

    it("should have compressImage function", () => {
      expect(SpectrumManager.compressImage).toBeDefined();
    });

    it("returns an error if no argument is given", (done) => {
      SpectrumManager.compressImage(null, () => {}, err => {
        expect(err).toBeDefined();
        expect(err.message).toBe('missing options');
        done();
      });
    });

    it("returns an error if sourcePath is not given", (done) => {
      SpectrumManager.compressImage({}, () => {}, err => {
        expect(err).toBeDefined();
        expect(err.message).toBe('sourcePath is missing');
        done();
      });
    });

    it("returns an error if sourcePath is invalid", (done) => {
      SpectrumManager.compressImage({
        sourcePath: 'invalid url'
      }, () => {}, err => {
        expect(err).toBeDefined();
        done();
      });
    });
  });
};