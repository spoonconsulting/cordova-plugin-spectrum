package com.spoon.spectrum;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import com.facebook.spectrum.Spectrum;
import com.facebook.spectrum.image.ImageSize;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.UUID;
import androidx.exifinterface.media.ExifInterface;

public class SpectrumManager extends CordovaPlugin {
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
                    sendErrorResultForException(callbackContext, e);
                }
            }
        });
        return true;
    }

    private void sendErrorResultForException(CallbackContext callbackContext, Exception exception) {
        callbackContext.error("(" + exception.getClass().getSimpleName() + ") - " + exception.getMessage());
        exception.printStackTrace();
    }

    private void transcodeImage(String path, int size, CallbackContext callbackContext) {
        Uri tmpSrc = Uri.parse(path);
        final Uri sourceUri = tmpSrc.getScheme() != null ? webView.getResourceApi().remapUri(tmpSrc) : tmpSrc;
        final String sourcePath = sourceUri.toString();
        File file = new File(sourcePath);
        if (!file.exists()) {
            callbackContext.error("source file does not exist");
            return;
        }

        Bitmap bitmap;
        try {
            bitmap = BitmapFactory.decodeFile(sourcePath);
            if (bitmap == null) {
                callbackContext.error("Could not decode the image");
                return;
            }
        } catch (Exception e) {
            callbackContext.error("Failed to load image: " + e.getMessage());
            return;
        }

        // Resize the bitmap if necessary
        ImageSize targetSize = getImageSize(path, size);
        if (bitmap.getWidth() != targetSize.width || bitmap.getHeight() != targetSize.height) {
            bitmap = Bitmap.createScaledBitmap(bitmap, targetSize.width, targetSize.height, true);
        }

        String destinationFileName = UUID.randomUUID().toString() + "_compressed.jpg";
        String destinationPath = sourcePath.replace(file.getName(), destinationFileName);
        File outputFile = new File(destinationPath);

        try (FileOutputStream out = new FileOutputStream(outputFile)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)) {
                    callbackContext.error("Failed to compress image");
                    return;
                }
            }
        } catch (Exception e) {
            callbackContext.error("Failed to save compressed image: " + e.getMessage());
            return;
        } finally {
            if (!bitmap.isRecycled()) {
                bitmap.recycle();
            }
        }

        // Initialize ExifInterface for the original and compressed image
        ExifInterface originalExif = null;
        try {
            originalExif = new ExifInterface(sourcePath);
        } catch (IOException e) {
            Log.d("Can't extract origExifs", e.toString());
        }

        // Iterate over all EXIF tags in the original file
        if (originalExif != null) {
            ExifInterface compressedExif = null;
            try {
                compressedExif = new ExifInterface(destinationPath);
            } catch (IOException e) {
                Log.d("Can't extract compExifs", e.toString());
            }

            for (String attribute : SpoonCameraExif.COMMON_TAGS) {
                String value = originalExif.getAttribute(attribute);
                if (value != null) {
                    compressedExif.setAttribute(attribute, value);
                }
            }
            if (compressedExif != null) {
                try {
                    compressedExif.saveAttributes();
                } catch (IOException e) {
                    Log.d("Error saving exifs ", e.toString());
                }
            }
        }

        // Replace the original file with the compressed one
        if (!file.delete()) {
            callbackContext.error("could not delete source image");
            return;
        }
        if (!outputFile.renameTo(file)) {
            callbackContext.error("could not rename image");
            return;
        }

        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
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