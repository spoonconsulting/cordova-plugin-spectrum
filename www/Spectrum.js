var exec = require("cordova/exec");

module.exports = {
	transcodeImage: transcodeImage
};

function transcodeImage (params, success, fail) {
    if (!params) {
        return fail('missing options');
    }
	exec(success,fail, "SpectrumManager", "compressImage", [params]);
}
