package ume.assets;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class UMEAssets
{
	public static var sound_ext(default, null):String = ".ogg";
	public static var image_ext(default, null):String = ".png";
	public static var image_xml_ext(default, null):String = ".xml";
	public static var data_ext(default, null):String = ".json";

	public static var dumpExclusions:Array<String> = [];

	public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedAssets:Map<String, Dynamic> = [];

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					// remove the key from all cache maps
					FlxG.bitmap._cache.remove(key);
					openfl.Assets.cache.removeBitmapData(key);
					currentTrackedAssets.remove(key);

					// and get rid of the object
					obj.persist = false; // make sure the garbage collector actually clears it up
					obj.destroyOnNoUse = true;
					obj.destroy();
				}
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null, ?allowGPU:Bool = true)
	{
		if (bitmap == null)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else
			#end
			{
				if (OpenFlAssets.exists(file, IMAGE))
					bitmap = OpenFlAssets.getBitmapData(file);
			}

			if (bitmap == null)
				return null;
		}

		localTrackedAssets.push(file);
		if (allowGPU)
		{
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = BitmapData.fromTexture(texture);
		}
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, newGraphic);
		return newGraphic;
	}

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		var result = if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
		if (result.contains(':'))
			result = result.split(':')[1];
		return result;
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		var result = getPath(file, type, library);

		return result;
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function video(key:String, ?library:String)
	{
		return getPath('videos/$key.mp4', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function voices(key:String)
	{
		return 'assets/songs/$key/Voices$sound_ext';
	}

	inline static public function inst(key:String)
	{
		return 'assets/songs/$key/Inst$sound_ext';
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$sound_ext', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$sound_ext', MUSIC, library);
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static inline function getText(path:String):String
	{
		#if sys
		return getBytes(path).toString();
		#else
		return openfl.utils.Assets.getText(path);
		#end
	}

	static public function image(key:String, ?library:String, ?allowGPU:Bool = true)
	{
		#if (desktop && !hl)
		var bitmap:BitmapData = null;
		var file:String = "";

		file = getPath('images/$key.png', IMAGE, library);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets[file];
		}
		else if (OpenFlAssets.exists(file, IMAGE))
			bitmap = OpenFlAssets.getBitmapData(file);

		if (bitmap != null)
		{
			var retVal = cacheBitmap(file, bitmap, allowGPU);
			if (retVal != null)
				return retVal;
		}

		trace('oh no its returning null NOOOO ($file)');
		return null;
		#else
		var file:String = "";

		file = getPath('images/$key.png', IMAGE, library);
		return file;
		#end
	}

	public static inline function getSparrowAtlas(key:String)
	{
		return FlxAtlasFrames.fromSparrow(getPath('images/$key.png', IMAGE), getPath('images/$key.xml', TEXT));
	}

	#if sys
	public static inline function getBytes(path:String):haxe.io.Bytes
	{
		return sys.io.File.getBytes(path);
	}
	#end
}
