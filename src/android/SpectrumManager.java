package com.spoon.spectrum;

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
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

import static com.facebook.spectrum.image.EncodedImageFormat.JPEG;

public class SpectrumManager extends CordovaPlugin {

    private static Spectrum mSpectrum;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        if (mSpectrum == null) {
            SpectrumSoLoader.init(cordova.getActivity());
            mSpectrum = Spectrum.make(new SpectrumLogcatLogger(Log.INFO), DefaultPlugins.get());
        }
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        try {
            if (action.equals("compressImage")) {
                JSONObject config = args.length() > 0 ? (JSONObject) args.get(0) : null;
                String path = config.has("sourcePath") ? config.getString("sourcePath") : null;
                int size = config.has("targetSize") ? config.getInt("targetSize") : 0;
                transcodeImage(path, size, callbackContext);
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private void transcodeImage(String path, int size, CallbackContext callbackContext) {

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    if (path == null) {
                        callbackContext.error("missing source path");
                        return;
                    }
                    final String sourcePath = path.replace("file://", "");
                    File file = new File(sourcePath);
                    if (!file.exists()) {
                        callbackContext.error("source file does not exists");
                        return;
                    }

                    final InputStream inputStream = new FileInputStream(sourcePath);
                    final TranscodeOptions transcodeOptions;
                    if (size > 0) {
                        transcodeOptions = TranscodeOptions.Builder(new EncodeRequirement(JPEG, 80)).resize(ResizeRequirement.Mode.EXACT_OR_SMALLER, new ImageSize(size, size)).build();
                    } else {
                        transcodeOptions = TranscodeOptions.Builder(new EncodeRequirement(JPEG, 80)).build();
                    }

                    String fileExtension = MimeTypeMap.getFileExtensionFromUrl(Uri.fromFile(file).toString());
                    String destinationFileName = UUID.randomUUID().toString() + fileExtension;
                    String destinationPath = sourcePath.replace(file.getName(), destinationFileName);

                    final SpectrumResult result = mSpectrum.transcode(
                            EncodedImageSource.from(inputStream),
                            EncodedImageSink.from(destinationPath),
                            transcodeOptions,
                            "com.spectrum-plugin");
                    if (result.isSuccessful()) {
                        if (!file.delete()) {
                            callbackContext.error("could not delete source image");
                            return;
                        }
                        if (!new File(destinationPath).renameTo(file)) {
                            callbackContext.error("could not rename image");
                            return;
                        }
                        PluginResult plugingResult = new PluginResult(PluginResult.Status.OK);
                        plugingResult.setKeepCallback(true);
                        callbackContext.sendPluginResult(plugingResult);
                    } else {
                        callbackContext.error("could not compress image");
                    }

                } catch (final IOException e) {
                    callbackContext.error("source file does not exists");
                } catch (final SpectrumException e) {
                    callbackContext.error("invalid image");
                }
            }
        });
    }

}