package meta.state.menus;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import meta.MusicBeat.MusicBeatState;
import meta.data.dependency.Discord;
import meta.data.*;
import meta.data.font.Alphabet;
import meta.state.menus.*;
import openfl.Assets;
import lime.app.Application;
import lime.utils.Assets;

using StringTools;
/**
 * ...
 * woooo credit state! my favorite thing to do!
 */

class CreditState extends MusicBeatState
{
	var bg:FlxSprite;
	var nameText:FlxText;
	var descText:FlxText;
	var icon:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var creditText:Alphabet;
	var curSelected:Int = 0;

	var font = Paths.font('splatter.otf');
	
	var cam1:FlxCamera;
	var cam2:FlxCamera;
	var defaultCamZoom:Float = 1.05;
	
	//dynamic array my beloved
	//how 2 work the array: name, credit for
	var peopleArray:Array<Dynamic> = [
		["TuckerTheTucker", "Creator of MNS, Coder, Made Parappa BF"],
		["Alicia", "Voice Actress for Wicherus"],
		["Skulltron96", "Main Week Composer"],
		["SilentJheck", "Artist"],
		["ERRon", "Charter for Spoopy"],
		["voidofnancy", "Dialogue Writer"]
	];
	
	override function create() 
	{
		super.create();
		
		ForeverTools.resetMenuMusic();
		
		// create the camera
		cam1 = new FlxCamera();

		// create the other camera (separate for the depth effect)
		cam2 = new FlxCamera();
		cam2.bgColor.alpha = 0;

		FlxG.cameras.reset(cam1);
		FlxG.cameras.add(cam2);
		FlxCamera.defaultCameras = [cam1];
		
		FlxG.camera.zoom = defaultCamZoom;
		
		var ui_tex = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_assets');

		//background
		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.screenCenter();
		add(bg);
		
		nameText = new FlxText(0, 250, 750, '', 36);
		nameText.font = font;
		nameText.screenCenter(X);
		nameText.alignment = FlxTextAlign.CENTER;
		nameText.borderStyle = FlxTextBorderStyle.OUTLINE;
		nameText.borderSize = 3;
		nameText.color = FlxColor.WHITE;	
		nameText.borderColor = FlxColor.BLACK;
		nameText.cameras = [cam2];
		add(nameText);
		
		descText = new FlxText(0, 350, 500, '', 36);
		descText.font = font;
		descText.screenCenter(X);
		descText.alignment = FlxTextAlign.CENTER;
		descText.borderStyle = FlxTextBorderStyle.OUTLINE;
		descText.borderSize = 3;
		descText.color = FlxColor.WHITE;
		descText.borderColor = FlxColor.BLACK;
		descText.cameras = [cam2];
		add(descText);
		
		//icons have been removed due to time constraints. sorry.
		
		leftArrow = new FlxSprite(395, 225);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left", 24, false);
		leftArrow.animation.addByPrefix('press', "arrow push left", 24, false);
		leftArrow.animation.play('idle');
		leftArrow.scrollFactor.set();
		leftArrow.cameras = [cam2];
		add(leftArrow);
		
		rightArrow = new FlxSprite(845, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right', 24, false);
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.scrollFactor.set();
		rightArrow.cameras = [cam2];
		add(rightArrow);
		
		creditText = new Alphabet(FlxG.width / 2 - 170, 40, 'CREDITS', true, false);
		creditText.cameras = [cam2];
		add(creditText);

		var vignetteBG:FlxSprite = ForeverAssets.addVignette();
		add(vignetteBG);

		var twitText:FlxText = new FlxText(15, FlxG.height - 50, 0, "Press ENTER to View Twitter/YouTube Account", 16);
		twitText.font = font;
		twitText.borderStyle = FlxTextBorderStyle.OUTLINE;
		twitText.borderSize = 3;
		twitText.scrollFactor.set();
		add(twitText);
		
		changeChar(0);
	}
	
	var swung:Bool = false;
	
	override function update(elapsed:Float) 
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		cam2.zoom = FlxMath.lerp(defaultCamZoom, cam2.zoom, 0.95);
		
		if (controls.UI_LEFT)
			leftArrow.animation.play('press');
		else
			leftArrow.animation.play('idle');
		if (controls.UI_RIGHT)
			rightArrow.animation.play('press');
		else
			rightArrow.animation.play('idle');
		
		if (controls.UI_LEFT_P)
		{
			changeChar(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		if (controls.UI_RIGHT_P)
		{
			changeChar(1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			Main.switchState(this, new MainMenuState());
		}

		if (controls.ACCEPT)
		 {
			var daChoice:String = peopleArray[curSelected][0];
			trace('opening url for $daChoice');
			
			switch (daChoice.toLowerCase())
			{
				case 'tuckerthetucker':
					FlxG.openURL('https://www.twitter.com/TuckerTheTucker');
				case 'alicia':
					FlxG.openURL('https://www.twitter.com/aliciasblade');
				case 'skulltron96':
					FlxG.openURL('https://youtube.com/channel/UCbFMjYlSYCV6V6AhEfBJFVQ');
				case 'silentjheck':
					FlxG.openURL('https://www.twitter.com/SilentJheck');
				case 'erron':
					FlxG.openURL('https://www.youtube.com/channel/UCwMrK-IEKqwOS2c196T5bnQ');
				case 'voidofnancy':
					FlxG.openURL('https://youtube.com/channel/UCcY7k739rL6NoKsTq_-fDbg');
			}
		}
		
		super.update(elapsed);
	}
	
	override function beatHit()
	{
		if ((!Init.trueSettings.get('Reduced Movements')))
		{
			FlxG.camera.zoom += 0.015;
			cam2.zoom += 0.03;
			
			swung = !swung;
			//icon.angle = (swung ? 3 : -3);
		}
		
		super.beatHit();
	}
	
	function changeChar(change:Int)
	{
		curSelected += change;
		
		if (curSelected > peopleArray.length - 1)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = peopleArray.length - 1;
		
		nameText.text = peopleArray[curSelected][0];
		descText.text = peopleArray[curSelected][1];
		
		//icon.animation.curAnim.curFrame = curSelected;
	}
	
}