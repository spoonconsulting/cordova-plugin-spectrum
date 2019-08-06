var exec = require("cordova/exec");

module.exports = {
	compressImage: compressImage
};

function compressImage (params, success, fail) {
    if (!params) {
        return fail('missing options');
    }
	exec(success,fail, "SpectrumManager", "compressImage", [params]);
}
