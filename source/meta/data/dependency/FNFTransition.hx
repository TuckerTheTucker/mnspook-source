package meta.data.dependency;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.Transition;
import flixel.addons.transition.TransitionData;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import meta.MusicBeat.MusicBeatSubState;

/**
 *
 * Transition overrides
 * @author Shadow_Mario_
 *
**/
class FNFTransition extends MusicBeatSubState
{
	public static var finishCallback:Void->Void;

	private var leTween:FlxTween = null;

	public static var nextCamera:FlxCamera;

	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	public function new(duration:Float, isTransIn:Bool)
	{
		super();

		this.isTransIn = isTransIn;
		var width:Int = Std.int(FlxG.width);
		var height:Int = Std.int(FlxG.height);
		transGradient = new FlxSprite(width, 0).makeGraphic(width, height, FlxColor.BLACK);
		transGradient.scrollFactor.set();
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);
		transBlack.scrollFactor.set();
		add(transBlack);

		transGradient.x -= (width - FlxG.width) / 2;
		transBlack.x = transGradient.x;

		if (isTransIn)
		{
			transGradient.x = transBlack.x - transBlack.height;
			FlxTween.tween(transGradient, {x: FlxG.width}, duration, {
				onComplete: function(twn:FlxTween)
				{
					close();
				},
				ease: FlxEase.linear
			});
		}
		else
		{
			transGradient.x = -transGradient.width;
			transBlack.x = transGradient.x - transBlack.width + 50;
			leTween = FlxTween.tween(transGradient, {x: FlxG.width}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.linear
			});
		}
	}

	var camStarted:Bool = false;

	override function update(elapsed:Float)
	{
		if (isTransIn)
			transBlack.x = transGradient.x + transGradient.width;
		else
			transBlack.x = transGradient.x - transBlack.width;

		var camList = FlxG.cameras.list;
		camera = camList[camList.length - 1];
		transBlack.cameras = [camera];
		transGradient.cameras = [camera];

		super.update(elapsed);
		
		if (isTransIn)
			transBlack.x = transGradient.x + transGradient.width;
		else
			transBlack.x = transGradient.x - transBlack.width;
	}

	override function destroy()
	{
		if (leTween != null)
		{
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}