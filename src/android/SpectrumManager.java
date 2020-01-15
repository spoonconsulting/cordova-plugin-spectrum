package com.spoon.spectrum;

import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Log;
import android.webkit.MimeTypeMap;


import com.facebook.spectrum.DefaultPlugins;
import com.facebook.spectrum.EncodedImageSink;
import com.facebook.spectrum.EncodedImageSource;
import com.facebook.spectrum.Spectrum;
import com.facebook.spectrum.SpectrumException;
import com.facebook.spectrum.SpectrumResult;
import com.facebook.spectrum.SpectrumSoLoader;
import com.facebook.spectrum.image.ImageSize;
import com.facebook.spectrum.logging.SpectrumLogcatLogger;
import com.facebook.spectrum.options.TranscodeOptions;
import com.facebook.spectrum.requirements.EncodeRequirement;
import com.facebook.spectrum.requirements.ResizeRequirement;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.util.UUID;

import static com.facebook.spectrum.image.EncodedImageFormat.JPEG;

public class SpectrumManager extends CordovaPlugin {

    private static Spectrum mSpectrum;
    
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    if (action.equals("compressImage")) {
                        JSONObject config = (JSONObject) args.get(0);
                        transcodeImage(config.getString("sourcePath"), config.getInt("maxSize"), callbackContext);
                    }
                } catch (Exception e) {
                    callbackContext.error(e.getMessage());
                    e.printStackTrace();
                }
            }
        });
        return true;
    }

    private void transcodeImage(String path, int size, CallbackContext callbackContext) {
        if (mSpectrum == null) {
            SpectrumSoLoader.init(cordova.getActivity());
            mSpectrum = Spectrum.make(new SpectrumLogcatLogger(Log.INFO), DefaultPlugins.get());
        }
        Uri tmpSrc = Uri.parse(path);
        final Uri sourceUri = tmpSrc.getScheme() != null ? webView.getResourceApi().remapUri(tmpSrc) : tmpSrc;
        final String sourcePath = sourceUri.toString();
        File file = new File(sourcePath);
        if (!file.exists()) {
            callbackContext.error("source file does not exists");
            return;
        }
        InputStream inputStream;
        try {
            inputStream = new FileInputStream(sourcePath);
        } catch (Exception e) {
            callbackContext.error(e.toString());
            return;
        }
        final TranscodeOptions transcodeOptions;
        ImageSize targetSize = getImageSize(path, size);
        transcodeOptions = TranscodeOptions.Builder(new EncodeRequirement(JPEG, 80)).resize(ResizeRequirement.Mode.EXACT_OR_SMALLER, targetSize).build();
        String fileExtension = MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(file).toString());
        String destinationFileName = UUID.randomUUID().toString() + "_compressed." + fileExtension;
        String destinationPath = sourcePath.replace(file.getName(), destinationFileName);
        SpectrumResult result;
        try {
            result = mSpectrum.transcode(
                    EncodedImageSource.from(inputStream),
                    EncodedImageSink.from(destinationPath),
                    transcodeOptions,
                    "com.spectrum-plugin");
        } catch (SpectrumException e) {
            callbackContext.error(e.toString());
            return;
        } catch (FileNotFoundException e) {
            callbackContext.error(e.toString());
            return;
        }
        if (result.isSuccessful()) {
            if (!file.delete()) {
                callbackContext.error("could not delete source image");
                return;
            }
            if (!new File(destinationPath).renameTo(file)) {
                callbackContext.error("could not rename image");
                return;
            }
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);
            return;
        }
        callbackContext.error("could not compress image");
    }

    private ImageSize getImageSize(String sourcePath, int defaultSize) {
        int width;
        int height;
        if (defaultSize > 0) {
            width = defaultSize;
            height = defaultSize;
        } else {
            //grab the image size (without passing a resize params, the compression is not being done!)
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(sourcePath, options);
            width = options.outWidth;
            height = options.outHeight;
        }
        return new ImageSize(width, height);
    }
}