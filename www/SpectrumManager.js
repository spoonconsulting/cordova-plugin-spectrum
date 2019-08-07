var exec = require("cordova/exec");

module.exports = {
	compressImage: compressImage
};

function compressImage (params, success, fail) {
    if (!params) 
        return fail('missing options');

    if (!params.sourcePath)
        return fail('sourcePath is missing');

    if (!params.targetSize)
        params.targetSize = 0;
    
    params.sourcePath = params.sourcePath.replace('file://', '');
	exec(success,fail, "SpectrumManager", "compressImage", [params]);
}
