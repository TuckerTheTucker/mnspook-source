package meta;

import flixel.FlxG;
import lime.utils.Assets;
import flixel.util.FlxColor;
import meta.state.PlayState;

using StringTools;

#if !html5
import sys.FileSystem;
#end

class CoolUtil
{
	// tymgus45
	public static var difficultyArray:Array<String> = ["NORMAL", "SCARY"];
	public static var difficultyLength = difficultyArray.length;

	public static function difficultyFromNumber(number:Int):String
	{
		return difficultyArray[number];
	}

	public static function noteTypeToString(number:Int):String
	{
		var daText:String = '';
		switch(number)
		{
			case 1:
				daText = 'Trick';
			case 2:
				daText = 'Treat';
			default:
				daText = 'Normal';
		}

		return daText;
	}

	public static function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static function swapSpaceDash(string:String):String
	{
		return StringTools.contains(string, '-') ? dashToSpace(string) : spaceToDash(string);
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function getOffsetsFromTxt(path:String):Array<Array<String>>
	{
		var fullText:String = Assets.getText(path);

		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split(' '));

		return swagOffsets;
	}

	public static function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String>
	{
		//
		var libraryArray:Array<String> = [];
		#if !html5
		var unfilteredLibrary = FileSystem.readDirectory('$subDir/$library');

		for (folder in unfilteredLibrary)
		{
			if (!folder.contains('.'))
				libraryArray.push(folder);
		}
		trace(libraryArray);
		#end

		return libraryArray;
	}

	public static function getAnimsFromTxt(path:String):Array<Array<String>>
	{
		var fullText:String = Assets.getText(path);

		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagOffsets.push(i.split('--'));
		}

		return swagOffsets;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function weekToColor(week:Int):FlxColor
		{
			var color:FlxColor;
	
			switch(week)
			{
				case 0:
					color = 0xFFFF7D42;
				case 1:
					color = FlxColor.fromRGB(129, 100, 223);
				case 2:
					color = FlxColor.fromRGB(30, 45, 60);
				case 3:
					color = FlxColor.fromRGB(111, 19, 60);
				case 4:
					color = FlxColor.fromRGB(203, 113, 170);
				case 5:
					color = FlxColor.fromRGB(141, 165, 206);
				case 6:
					color = FlxColor.fromRGB(206, 106, 169);
				default:
					color = FlxColor.WHITE;
			}
	
			return(color);
		}
}
