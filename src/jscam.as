/**
 * jQuery webcam
 * Copyright (c) 2010, Robert Eisele (robert@xarg.org)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * Date: 09/12/2010
 *
 * @author Robert Eisele
 * @version 1.0
 *
 * @see http://www.xarg.org/project/jquery-webcam-plugin/
 **/

import flash.system.Security;
import flash.external.ExternalInterface;
import flash.display.BitmapData;

class JSCam {

  private static var camera:Camera = null;
  private static var display:MovieClip = null;
  private static var buffer:BitmapData = null;
  private static var quality:Number = 85;

  public static function main():Void {

    System.security.allowDomain("*");

    if (_root.quality)
      quality = _root.quality;


    // From: http://www.squidder.com/2009/03/09/trick-auto-select-mac-isight-in-flash/
    var cameraId:Number = -1;
    for (var i = 0, l = Camera.names.length; i < l; i++)
      if (Camera.names[i] == "USB Video Class Video") {
        cameraId = i;
        break;
      }

    if (cameraId > -1)
      camera = Camera.get(cameraId);
    else
      camera = Camera.get();

    if (camera) {
      // http://www.adobe.com/support/flash/action_scripts/actionscript_dictionary/actionscript_dictionary133.html
      camera.onStatus = function(info:Object) {
        switch (info.code) {
          case 'Camera.Muted':
            ExternalInterface.call('webcam.debug', "notify", "Camera stopped");
            break;
          case 'Camera.Unmuted' :
            ExternalInterface.call('webcam.debug', "notify", "Camera started");
            break;
        }
      }

      camera.setQuality(0, 100);
      camera.setMode(Stage.width, Stage.height, 24, false);

      ExternalInterface.addCallback("capture", null, capture);
      ExternalInterface.addCallback("setCamera", null, setCamera);
      ExternalInterface.addCallback("getCameraList", null, getCameraList);

			display = _root.attachMovie("clip", "video", 1);
      display.video.attachVideo(camera);
      display.video._x = 0;
      display.video._y = 0;

    } else {
      ExternalInterface.call('webcam.debug', "error", "No camera was detected.");
    }
  }


  public static function getCameraList():Array {
    var list = new Array();

    for (var i=0, l = Camera.names.length; i < l; i++)
      list[i] = Camera.names[i];

    return list;
  }


  public static function setCamera(cameraId:Number):Boolean {
    if (0 <= cameraId && cameraId < Camera.names.length) {
      camera = Camera.get(cameraId);
      camera.setQuality(0, 100);
      camera.setMode(Stage.width, Stage.height, 24, false);
      return true;
    }
    return false;
  }


  public static function capture():Boolean {
    if (!camera)
      return false;

    ExternalInterface.call('webcam.debug', "notify", "Capturing started.");

    buffer = new BitmapData(Stage.width, Stage.height);
    buffer.draw(display.video);

    var pixels = [];
    for (var i=0; i < 240; ++i)
      for (var j=0; j < 320; ++j)
        pixels.push(buffer.getPixel(j, i).valueOf())

    ExternalInterface.call("webcam.onCapture", pixels);
    ExternalInterface.call('webcam.debug', "notify", "Capturing finished.");

    return true;
  }
}
