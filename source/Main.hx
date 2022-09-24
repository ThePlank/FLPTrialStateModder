package;

import cpp.UInt16;
import cpp.UInt8;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Path;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import sys.io.File;

using StringTools;

class Main extends Sprite
{
	public function new()
	{
		super();
		#if (flixel >= "5.0.0")
		addChild(new FlxGame(0, 0, PlayState, 60, 60, true));
		#else
		addChild(new FlxGame(0, 0, PlayState, 1, 60, 60, true));
		#end
	}
}

class PlayState extends FlxState
{
	var flpFile:FileReference;
	var untrial = true;
	var unlockArray = [
		[0xD0, 0x50],
		[0xF0, 0x70],
		[0xD1, 0x51],
		[0xC1, 0x41],
		[0xC8, 0x41],
		[0xC0, 0x40]
	];
	var lockArray = [
		[0x50, 0xD0],
		[0x70, 0xF0],
		[0x51, 0xD1],
		[0x41, 0xC1],
		[0x41, 0xC8],
		[0x40, 0xC0]
	];
	var overwriteFlp = true;

	override public function create()
	{
		if (FlxG.save.data.overwrite == null)
		{
			FlxG.save.data.overwrite = true;
			FlxG.save.flush();
		}
		else
			overwriteFlp = FlxG.save.data.overwrite;
		var bg = new FlxSprite().loadGraphic("assets/bg.png");
		bg.screenCenter();
		add(bg);
		var untrialbutton = new FlxButton(0, 0, "Untrial-ize FLP", function()
		{
			untrial = true;
			flpFile = new FileReference(); // make it new and existing
			flpFile.addEventListener(Event.SELECT, flp); // add if people confirm
			flpFile.addEventListener(Event.CANCEL, nomoreevents); // add if people say nah
			flpFile.browse([new FileFilter("FL Studio Project files (*.flp).", "flp")]); // start that file selecter B)
		});
		add(untrialbutton);
		var trial = new FlxButton(0, 0, "Trial-ize FLP", function()
		{
			untrial = false;
			flpFile = new FileReference(); // make it new and existing
			flpFile.addEventListener(Event.SELECT, flp); // add if people confirm
			flpFile.addEventListener(Event.CANCEL, nomoreevents); // add if people say nah
			flpFile.browse([new FileFilter("FL Studio Project files (*.flp).", "flp")]); // start that file selecter B)
		});
		add(trial);
		var overwriteText = new FlxText(50, 50, 0, "You are currently " + (overwriteFlp ? "" : "not ") + "in overwriting mode.", 20);
		var overwriteButton = new FlxButton(50, 100, "Toggle overwriting mode.", function()
		{
			overwriteFlp = !overwriteFlp;
			FlxG.save.data.overwrite = overwriteFlp;
			overwriteText.text = "You are currently " + (overwriteFlp ? "" : "not ") + "in overwriting mode.";
		});
		overwriteButton.setGraphicSize(390, 75);
		overwriteButton.label.scale.set(overwriteButton.scale.x - 2.25, overwriteButton.scale.y - 0.75);
		overwriteButton.updateHitbox();
		overwriteButton.label.updateHitbox();
		overwriteButton.label.fieldWidth = 245;
		overwriteButton.label.x += 120;
		add(overwriteText);
		add(overwriteButton);
		var sizetoscale = 3.0;
		var extraoffset = 30;
		// ignore code below just trying to make it look good with bigger buttons
		untrialbutton.scale.set(sizetoscale, sizetoscale);
		untrialbutton.label.scale.set(sizetoscale, sizetoscale);
		untrialbutton.updateHitbox();
		untrialbutton.label.updateHitbox();
		untrialbutton.screenCenter();
		untrialbutton.x -= untrialbutton.width + extraoffset;
		trial.scale.set(sizetoscale, sizetoscale);
		trial.label.scale.set(sizetoscale, sizetoscale);
		trial.updateHitbox();
		trial.label.updateHitbox();
		trial.screenCenter();
		trial.x += trial.width + extraoffset;
		super.create();
	}

	function nomoreevents(e) // stands for no untrial flp events
	{
		flpFile.removeEventListener(Event.SELECT, null); // if them people cancel it / did it
		flpFile.removeEventListener(Event.CANCEL, null); // ^
		flpFile = null;
	}

	function flp(e)
	{
		@:privateAccess
		{
			var path = flpFile.__path; // get that path
			if (path == null || !sys.FileSystem.exists(path) || (!path.endsWith(".flp") && !path.endsWith(".fst"))
			{
				return;
			} // check it aint broken
			var flp = sys.io.File.getBytes(path); // yoink the bytes

			var fixyArray = unlockArray;
			if (!untrial)
				fixyArray = lockArray;
var flstudio11flag = 0; // check
			for (i in 0x30...flp.b.length) // detect 00 00 00 D4 34 and set the flag to correct value
			{
				if (flp.b[i] == 0x00 && flp.b[i + 1] == 0x00 && flp.b[i + 2] == 0x00 && flp.b[i + 3] == 0xD4 && flp.b[i + 4] == 0x34)
				{
					for (j in i...i + 25)
					{
						for (k in 0...fixyArray.length)
						{
							if (flp.b[j] == fixyArray[k][0])
							{
								flp.b[j] = fixyArray[k][1];
								
							}
						}
					}
					flstudio11flag++;
				}

				if (flp.b.length - i < 20)
					break;
			}
			if (flstudio11flag == 0) // kinda sus that there no plugins found or effects
				{
						for (i in 0x30...flp.b.length) // detect 00 00 00 D4 34 and set the flag to correct value
			{
				if (flp.b[i] == 0x00 && flp.b[i + 1] == 0xD4 && flp.b[i +2] == 0x34)
				{
					for (j in i...i + 25)
					{
						for (k in 0...fixyArray.length)
						{
							if (flp.b[j] == fixyArray[k][0])
							{
								flp.b[j] = fixyArray[k][1];
								
							}
						}
					}
					flstudio11flag++;
				}

				if (flp.b.length - i < 20)
					break;
			}
				}  // kinda ineffeicenve but whatecever!!!
			for (i in 0...0x30) // set trial header thing to 01
			{
				if (flp.b[i] == 0x1c)
				{
					if (untrial)
					flp.b[i + 1] = 0x01;
					else
					flp.b[i + 1] = 0x00;
				}
			}
			var newpath = path;
			if (!overwriteFlp) // one liner B) nvenrembeibd
				{
					if (path.endsWith(".fst"))
				newpath = path.split(".fst").splice(0, path.split(".fst").length - 1).join("")
					+ " - "
					+ ((untrial) ? "NON-" : "")
					+ "TRIALED MODE.fst";
					else
						newpath = path.split(".flp").splice(0, path.split(".flp").length - 1).join("")
					+ " - "
					+ ((untrial) ? "NON-" : "")
					+ "TRIALED MODE.flp";

				}
			sys.io.File.saveBytes(newpath, flp); // save it
			yayyoudidit(); // display happy text :D
			nomoreevents(null);
		}
	}

	function yayyoudidit()
	{
		FlxG.sound.play("assets/ding.wav"); // play that ding sound
		var text = new FlxText(0, 0, 0, "Nice! Test it out to see if it works!", 28);
		text.alignment = CENTER;
		text.color = FlxColor.GREEN;
		text.screenCenter();
		text.y += 200;
		add(text);
		FlxTween.tween(text, {alpha: 0}, 1, {
			onComplete: function(_)
			{
				remove(text, true);
				text.destroy();
				text = null;
			},
			onUpdate: function(_)
			{
				text.y -= 1.25;
			}
		});
	}
}
