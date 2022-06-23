package;

import openfl.display.FPS;
import lime.app.Application;
import openfl.Lib;
import ColorSwap;
import CheckboxThingie;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import flixel.input.mouse.FlxMouseEventManager;

using StringTools;

// TO DO: Redo the menu creation system for not being as dumb
class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Controls', #if mobileC 'Mobile Controls', #end 'Notes', 'Preferences'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

    //gotta follow kade stuff
    public static var instance:OptionsState;
    public var acceptInput = true;

	override function create() {
        instance = this;
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var menuBG = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.globalAntialiasing;
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}
		changeSelection();

		#if mobileC
			addVirtualPad(FULL, A_B);
		#end

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		changeSelection();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

        if(acceptInput)
        {
            if (controls.UI_UP_P) {
                changeSelection(-1);
            }
            if (controls.UI_DOWN_P) {
                changeSelection(1);
            }
    
            if (controls.BACK) {
				ClientPrefs.saveSettings();
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
            }
    
            if (controls.ACCEPT) {
                for (item in grpOptions.members) {
                    item.alpha = 0;
                }
    
                switch(options[curSelected]) {
                    case 'Notes':
                        openSubState(new NotesSubstate());
    
                    case 'Controls':
                        openSubState(new KeyBindMenu());

					case 'Mobile Controls':
						MusicBeatState.switchState(new options.CustomControlsState());

                    case 'Preferences':
                        openSubState(new PreferencesSubstate());
                }
            }
        }
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}
}



class NotesSubstate extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var hsvText:Alphabet;
	var nextAccept:Int = 5;

	var posX = 250;
	public function new() {
		super();

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...FlxG.save.data.arrowHSV.length) {
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(0, yPos, Std.string(FlxG.save.data.arrowHSV[i][j]));
				optionText.x = posX + (225 * j) + 100 - ((optionText.lettersArray.length * 90) / 2);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX - 70, yPos);
			note.frames = Paths.getSparrowAtlas('NOTE_assets');
			switch(i) {
				case 0:
					note.animation.addByPrefix('idle', 'purple0');
				case 1:
					note.animation.addByPrefix('idle', 'blue0');
				case 2:
					note.animation.addByPrefix('idle', 'green0');
				case 3:
					note.animation.addByPrefix('idle', 'red0');
			}
			note.animation.play('idle');
			note.antialiasing = FlxG.save.data.globalAntialiasing;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = FlxG.save.data.arrowHSV[i][0] / 360;
			newShader.saturation = FlxG.save.data.arrowHSV[i][1] / 100;
			newShader.brightness = FlxG.save.data.arrowHSV[i][2] / 100;
			shaderArray.push(newShader);
		}
		hsvText = new Alphabet(0, 0, "Hue    Saturation  Brightness", false, false, 0, 0.65);
		add(hsvText);
		changeSelection();

		#if mobileC
			addVirtualPad(FULL, A_B);
		#end
	}

	var changingNote:Bool = false;
	var hsvTextOffsets:Array<Float> = [240, 90];
	override function update(elapsed:Float) {
		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			var intendedPos:Float = posX - 70;
			if (curSelected == i) {
				item.x = FlxMath.lerp(item.x, intendedPos + 100, lerpVal);
			} else {
				item.x = FlxMath.lerp(item.x, intendedPos, lerpVal);
			}
			for (j in 0...3) {
				var item2 = grpNumbers.members[(i * 3) + j];
				item2.x = item.x + 265 + (225 * (j % 3)) - (30 * item2.lettersArray.length) / 2;
				if(FlxG.save.data.arrowHSV[i][j] < 0) {
					item2.x -= 20;
				}
			}

			if(curSelected == i) {
				hsvText.setPosition(item.x + hsvTextOffsets[0], item.y - hsvTextOffsets[1]);
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			changeSelection();
			if(!changingNote) {
				grpNumbers.forEachAlive(function(spr:Alphabet) {
					spr.alpha = 0;
				});
				grpNotes.forEachAlive(function(spr:FlxSprite) {
					spr.alpha = 0;
				});
				close();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = Std.int(FlxG.save.data.arrowHSV.length) - 1;
		if (curSelected >= FlxG.save.data.arrowHSV.length)
			curSelected = 0;

		curValue = FlxG.save.data.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(1, 1);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1.2, 1.2);
				hsvText.setPosition(item.x + hsvTextOffsets[0], item.y - hsvTextOffsets[1]);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = FlxG.save.data.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		FlxG.save.data.arrowHSV[selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}
		grpNumbers.members[(selected * 3) + type].changeText('0');
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if(roundedValue < -max) {
			curValue = -max;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		FlxG.save.data.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}
		grpNumbers.members[(curSelected * 3) + typeSelected].changeText(Std.string(roundedValue));
	}
}

class PreferencesSubstate extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
    static var unselectableOptions:Array<String> = [
		'GRAPHICS', //order is here lol
		'VISUALS AND UI',
        'GAMEPLAY',
		'FEATURES'
    ];
    static var noCheckbox:Array<String> = [
		'Framerate',
		'Score Type',
		'Time Bar',
		'Health Bar Opacity',
		'Arrows Opacity',
		'Enemy Arrows Opacity',
		'Note Delay'
    ];
    static var options:Array<String> = [
		'GRAPHICS',
		'Low Quality',
		'Anti-Aliasing',
		#if !html5
		'Framerate', //gotta test this one though
		#end
		'Presistent Cached Data',
		'VISUALS AND UI',
		'Note Splashes',
		'Score Type',
		'FPS Counter',
		'Memory Counter',
		'Play Hit Sounds', //ayo, visuals and ui??
		'Icon Boping',
		'Hide HUD',
		'Health Counter',
		'Time Bar',
		'Flashing Lights',
		'Camera Zooms',
		'Judgements',
		'KE Timebar',
		'Health Bar Opacity',
		'Arrows Opacity',
		'Enemy Arrows Opacity',
        'GAMEPLAY',
		'Downscroll',
		'Middlescroll',
		'Ghost Tapping',
		'No Antimash',
		'Note Delay',
		'FEATURES',
		'Constant Dodging',
		'Vine Boom Death Effect'
    ];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxArray:Array<CheckboxThingie> = [];
	private var checkboxNumber:Array<Int> = [];
	private var grpTexts:FlxTypedGroup<AttachedText>;
	private var textNumber:Array<Int> = [];

	private var characterLayer:FlxTypedGroup<Character>;
	private var showCharacter:Character = null;
	private var descText:FlxText;

	public function new()
	{
		super();
		characterLayer = new FlxTypedGroup<Character>();
		add(characterLayer);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var isCentered:Bool = unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, options[i], false, false);
			optionText.isMenuItem = true;
			if(isCentered) {
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
			} else {
				optionText.x += 200;
				optionText.forceX = 200;
			}
			optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(!isCentered) {
				var useCheckbox:Bool = true;
				for (j in 0...noCheckbox.length) {
					if(options[i] == noCheckbox[j]) {
						useCheckbox = false;
						break;
					}
				}

				if(useCheckbox) { 
					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, false);
					checkbox.sprTracker = optionText;
					checkboxArray.push(checkbox);
					checkboxNumber.push(i);
					add(checkbox);
				} else { 
					var valueText:AttachedText = new AttachedText('0', optionText.width + 80);
					valueText.sprTracker = optionText;
					grpTexts.add(valueText);
					textNumber.push(i);
				} 
			}
		}

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		for (i in 0...options.length) {
			if(!unselectableCheck(i)) {
				curSelected = i;
				break;
			}
		}
		changeSelection();
		reloadValues();

		#if mobileC
		addVirtualPad(FULL, A_B);
		#end
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK) {
			grpOptions.forEachAlive(function(spr:Alphabet) {
				spr.alpha = 0;
			});
			grpTexts.forEachAlive(function(spr:AttachedText) {
				spr.alpha = 0;
			});
			for (i in 0...checkboxArray.length) {
				var spr:CheckboxThingie = checkboxArray[i];
				if(spr != null) {
					spr.alpha = 0;
				}
			}
			if(showCharacter != null) {
				showCharacter.alpha = 0;
			}
			descText.alpha = 0;
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		var usesCheckbox = true;
		for (i in 0...noCheckbox.length) {
			if(options[curSelected] == noCheckbox[i]) {
				usesCheckbox = false;
				break;
			}
		}

		if(usesCheckbox) {
			if(controls.ACCEPT && nextAccept <= 0) {
				switch(options[curSelected]) {
					case 'Low Quality':
						ClientPrefs.lowQuality = !ClientPrefs.lowQuality;
					case 'Anti-Aliasing':
						ClientPrefs.globalAntialiasing = !ClientPrefs.globalAntialiasing;
					case 'Presistent Cached Data':
						ClientPrefs.imagesPersist = !ClientPrefs.imagesPersist;
					case 'Note Splashes':
						ClientPrefs.noteSplashes = !ClientPrefs.noteSplashes;
					case 'FPS Counter':
						ClientPrefs.showFPS = !ClientPrefs.showFPS;
						if(Main.fpsVar != null)
							Main.fpsVar.visible = ClientPrefs.showFPS;				
					case 'Memory Counter':
						ClientPrefs.memoryCounter = !ClientPrefs.memoryCounter;
						if(Main.memoryCounter != null)
							Main.memoryCounter.visible = ClientPrefs.memoryCounter;	
					case 'Play Hit Sounds':
						ClientPrefs.playHitSounds = !ClientPrefs.playHitSounds;
					case 'Icon Boping':
						ClientPrefs.iconBoping = !ClientPrefs.iconBoping;
					case 'Hide HUD':
						ClientPrefs.hideHud = !ClientPrefs.hideHud;
					case 'Health Counter':
						ClientPrefs.healthCounter = !ClientPrefs.healthCounter;
					case 'Flashing Lights':
						ClientPrefs.flashing = !ClientPrefs.flashing;
					case 'Camera Zooms':
						ClientPrefs.camZooms = !ClientPrefs.camZooms;
					case 'Judgements':
						ClientPrefs.judgements = !ClientPrefs.judgements;
					case 'KE Timebar':
						ClientPrefs.keTimeBar = !ClientPrefs.keTimeBar;
					case 'Downscroll':
						ClientPrefs.downScroll = !ClientPrefs.downScroll;
					case 'Middlescroll':
						ClientPrefs.middleScroll = !ClientPrefs.middleScroll;
					case 'Ghost Tapping':
						ClientPrefs.ghostTapping = !ClientPrefs.ghostTapping;
					case 'No Antimash':
						ClientPrefs.noAntimash = !ClientPrefs.noAntimash;
					case 'Constant Dodging':
						ClientPrefs.constDodging = !ClientPrefs.constDodging;
					case 'Vine Boom SFX':
						ClientPrefs.vineBoomDodge = !ClientPrefs.vineBoomDodge;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
				reloadValues();
			}
		} else if (!usesCheckbox) {
			if(controls.UI_LEFT || controls.UI_RIGHT) {
				var add:Int = controls.UI_LEFT ? -1 : 1;
				if(holdTime > 0.5 || controls.UI_LEFT_P || controls.UI_RIGHT_P)
				switch(options[curSelected]) {
					case 'Framerate':
						//taken from funny 0.3.2-h mod port repo lol
						ClientPrefs.framerate += add;
						if(ClientPrefs.framerate < 60) ClientPrefs.framerate = 60;
						else if(ClientPrefs.framerate > 240) ClientPrefs.framerate = 240;

						if(ClientPrefs.framerate > FlxG.drawFramerate) {
							FlxG.updateFramerate = ClientPrefs.framerate;
							FlxG.drawFramerate = ClientPrefs.framerate;
						} else {
							FlxG.drawFramerate = ClientPrefs.framerate;
							FlxG.updateFramerate = ClientPrefs.framerate;
						}
					case 'Score Type':
						var availableOptions = ['Psych Engine', 'Kade Engine', 'Disabled'];
						if(add > availableOptions.length) add = availableOptions.length;
						else if (add < 0) add = 0;
						ClientPrefs.scoreType = availableOptions[add];
					case 'Time Bar':
						var availableOptions = ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled'];
						if(add > availableOptions.length ) add = availableOptions.length;
						else if (add < 0) add = 0;
						ClientPrefs.timeBarType = availableOptions[add];
					case 'Health Bar Opacity':
						var custmadd:Float = controls.UI_LEFT ? -0.1 : 0.1;
						ClientPrefs.healthBarAlpha += custmadd;
						if(ClientPrefs.healthBarAlpha < 0) ClientPrefs.healthBarAlpha = 0;
						else if(ClientPrefs.healthBarAlpha > 1) ClientPrefs.healthBarAlpha = 1;
					case 'Arrows Opacity':
						var custmadd:Float = controls.UI_LEFT ? -0.1 : 0.1;
						ClientPrefs.arrowOpacity += custmadd;
						if(ClientPrefs.arrowOpacity < 0) ClientPrefs.arrowOpacity = 0;
						else if(ClientPrefs.arrowOpacity > 1) ClientPrefs.arrowOpacity = 1;
					case 'Enemy Arrows Opacity':
						var custmadd:Float = controls.UI_LEFT ? -0.1 : 0.1;
						ClientPrefs.opponentArrowOpacity += custmadd;
						if(ClientPrefs.opponentArrowOpacity < 0) ClientPrefs.opponentArrowOpacity = 0;
						else if(ClientPrefs.opponentArrowOpacity > 1) ClientPrefs.opponentArrowOpacity = 1;
					case 'Note Delay':
						//taken from funny 0.3.2-h mod port repo lol
						var mult:Int = 1;
						if(holdTime > 1.5) { //Double speed after 1.5 seconds holding
							mult = 2;
						}
						ClientPrefs.noteOffset += add * mult;
						if(ClientPrefs.noteOffset < 0) ClientPrefs.noteOffset = 0;
						else if(ClientPrefs.noteOffset > 500) ClientPrefs.noteOffset = 500;
				}
				reloadValues();

				if(holdTime <= 0) FlxG.sound.play(Paths.sound('scrollMenu'));
				holdTime += elapsed;
			} else {
                holdTime = 0;
            }
		}

		if(showCharacter != null && showCharacter.animation.curAnim.finished) {
			showCharacter.dance();
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0)
	{
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = options.length - 1;
			if (curSelected >= options.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var daText:String = '';
		switch(options[curSelected]) {
			case 'Low Quality':
				daText = "If checked, disables some background details,\ndecreases loading times and improves performance.";
			case 'Anti-Aliasing':
				daText = "If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.";
			case 'Framerate':
				daText = "Pretty self explanatory, isn't it?";
			case 'Presistent Cached Data':
				daText = "If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.";
			case 'Note Splashes':
				daText = "If unchecked, hitting \"Sick!\" notes won't show particles.";
			case 'Score Type':
				daText = "What should the score be like?";
			case 'FPS Counter':
				daText = "If unchecked, hides FPS Counter.";
			case 'Memory Counter':
				daText = "If checked, enables memory counter.";
			case 'Play Hit Sounds':
				daText = "If checked, enables hit sounds.";
			case 'Icon Boping':
				daText = "If checked, enables icon Boping.";
			case 'Hide HUD':
				daText = "If checked, hides most HUD elements.";
			case 'Health Counter':
				daText = "If checked, enables the health counter.";
			case 'Time Bar':
				daText = "What should the Time Bar display?";
			case 'Flashing Lights':
				daText = "Uncheck this if you're sensitive to flashing lights!";
			case 'Camera Zooms':
				daText = "If unchecked, the camera won't zoom in on a beat hit.";
			case 'Judgements':
				daText = "If unchecked, hides judgements.";
			case 'KE Timebar':
				daText = "If checked, uses the KE timebar.";
			case 'Health Bar Opacity':
				daText = "How Opaque should the health bar and icons be.";
			case 'Arrows Opacity':
				daText = "How Opaque should the arrows be.";
			case 'Enemy Arrows Opacity':
				daText = "How Opaque should the opponent arrows be.";
			case 'Downscroll':
				daText = "If checked, notes go Down instead of Up, simple enough.";
			case 'Middlescroll':
				daText = "If checked, your notes get centered.";
			case 'Ghost Tapping':
				daText = "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.";
			case 'No Antimash':
				daText = "If checked, disables antimash.";
			case 'Note Delay':
				daText = "Changes how late a note is spawned.\nUseful for preventing audio lag from wireless earphones.";

			case 'Constant Dodging':
				daText = "If enabled, you will have to constantly dodge, easy BUGGY ATM";
			case 'Vine Boom SFX':
				daText = "When dodging a vine boom sfx will play";
		}
		descText.text = daText;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}

				for (j in 0...checkboxArray.length) {
					var tracker:FlxSprite = checkboxArray[j].sprTracker;
					if(tracker == item) {
						checkboxArray[j].alpha = item.alpha;
						break;
					}
				}
			}
		}
		for (i in 0...grpTexts.members.length) {
			var text:AttachedText = grpTexts.members[i];
			if(text != null) {
				text.alpha = 0.6;
				if(textNumber[i] == curSelected) {
					text.alpha = 1;
				}
			}
		}

		if(options[curSelected] == 'Anti-Aliasing') {
			if(showCharacter == null) {
				showCharacter = new Character(840, 170, 'bf', true);
				showCharacter.setGraphicSize(Std.int(showCharacter.width * 0.8));
				showCharacter.updateHitbox();
				showCharacter.dance();
				characterLayer.add(showCharacter);
			}
		} else if(showCharacter != null) {
			characterLayer.clear();
			showCharacter = null;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadValues() {
		for (i in 0...checkboxArray.length) {
			var checkbox:CheckboxThingie = checkboxArray[i];
			if(checkbox != null) {
				var daValue:Bool = false;
				switch(options[checkboxNumber[i]]) {
					case 'Low Quality':
						daValue = ClientPrefs.lowQuality;
					case 'Anti-Aliasing':
						daValue = ClientPrefs.globalAntialiasing;
					case 'Presistent Cached Data':
						daValue = ClientPrefs.imagesPersist;
					case 'Note Splashes':
						daValue = ClientPrefs.noteSplashes;
					case 'FPS Counter':
						daValue = ClientPrefs.showFPS;
					case 'Memory Counter':
						daValue = ClientPrefs.memoryCounter;
					case 'Play Hit Sounds':
						daValue = ClientPrefs.playHitSounds;
					case 'Icon Boping':
						daValue = ClientPrefs.iconBoping;
					case 'Hide HUD':
						daValue = ClientPrefs.hideHud;
					case 'Health Counter':
						daValue = ClientPrefs.healthCounter;
					case 'Flashing Lights':
						daValue = ClientPrefs.flashing;
					case 'Camera Zooms':
						daValue = ClientPrefs.camZooms;
					case 'Judgements':
						daValue = ClientPrefs.judgements;
					case 'KE Timebar':
						daValue = ClientPrefs.keTimeBar;
					case 'Downscroll':
						daValue = ClientPrefs.downScroll;
					case 'Middlescroll':
						daValue = ClientPrefs.middleScroll;
					case 'Ghost Tapping':
						daValue = ClientPrefs.ghostTapping;
					case 'No Antimash':
						daValue = ClientPrefs.noAntimash;

					case 'Constant Dodging':
						daValue = ClientPrefs.constDodging;
					case 'Vine Boom SFX':
						daValue = ClientPrefs.vineBoomDodge;
				}
				checkbox.daValue = daValue;
			}
		}
		for (i in 0...grpTexts.members.length) {
			var text:AttachedText = grpTexts.members[i];
			if(text != null) {
				var daText:String = '';
				switch(options[textNumber[i]]) {
					case 'Framerate':
						daText = ClientPrefs.framerate + "FPS";
					case 'Score Type':
						daText = ClientPrefs.scoreType;
					case 'Time Bar':
						daText = ClientPrefs.timeBarType;
					case 'Health Bar Opacity':
						daText = '' + ClientPrefs.healthBarAlpha;
					case 'Arrows Opacity':
						daText = '' + ClientPrefs.arrowOpacity;
					case 'Enemy Arrows Opacity':
						daText = '' + ClientPrefs.opponentArrowOpacity;
					case 'Note Delay':
						daText = ClientPrefs.noteOffset + "ms";
				}
				var lastTracker:FlxSprite = text.sprTracker;
				text.sprTracker = null;
				text.changeText(daText);
				text.sprTracker = lastTracker;
			}
		}
	}

	private function unselectableCheck(num:Int):Bool {
		for (i in 0...unselectableOptions.length) {
			if(options[num] == unselectableOptions[i]) {
				return true;
			}
		}
		return options[num] == '';
	}
}