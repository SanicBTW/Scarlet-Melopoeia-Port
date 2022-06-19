package;

/// Code created by Rozebud for FPS Plus (thanks rozebud)
// modified by KadeDev for use in Kade Engine/Tricky

import flixel.util.FlxAxes;
import flixel.FlxSubState;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.utils.Assets;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;

using StringTools;

class KeyBindMenu extends MusicBeatSubstate
{

    var keyTextDisplay:FlxText;
    var keyWarning:FlxText;
    var warningTween:FlxTween;
    var keyText:Array<Dynamic> = 
    [
        "NOTE LEFT", "NOTE DOWN", "NOTE UP", "NOTE RIGHT",
        "ACCEPT", "BACK", "PAUSE", "RESET"
    ];
    var defaultKeys:Array<Dynamic> = 
    [
        "A", "S", "W", "D",
        "SPACE", "BACKSPACE", "ENTER", "R"
    ];
    var curSelected:Int = -1;

    var keys:Array<Dynamic> = [
        FlxG.save.data.noteLeftBind, //0
        FlxG.save.data.noteDownBind, //1
        FlxG.save.data.noteUpBind, //2
        FlxG.save.data.noteRightBind, //3
        FlxG.save.data.acceptBind, //4
        FlxG.save.data.backBind, //5
        FlxG.save.data.pauseBind, //6
        FlxG.save.data.resetBind //7
    ];

    var tempKey:String = "";
    var blackBox:FlxSprite;
    var infoText:FlxText;

    var state:String = "select";

	override function create()
	{	

        for (i in 0...keys.length)
        {
            var k = keys[i];
            if (k == null)
                keys[i] = defaultKeys[i];
        }
	
		persistentUpdate = persistentDraw = true;

        keyTextDisplay = new FlxText(-10, 0, 1280, "", 72);
		keyTextDisplay.scrollFactor.set(0, 0);
		keyTextDisplay.setFormat("VCR OSD Mono", 42, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyTextDisplay.borderSize = 2;
		keyTextDisplay.borderQuality = 3;

        blackBox = new FlxSprite(0,0).makeGraphic(FlxG.width,FlxG.height,FlxColor.BLACK);
        add(blackBox);

        infoText = new FlxText(-10, 580, 1280, "(Escape to save, backspace to leave without saving)", 72);
		infoText.scrollFactor.set(0, 0);
		infoText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 2;
		infoText.borderQuality = 3;
        infoText.alpha = 0;
        infoText.screenCenter(FlxAxes.X);
        add(infoText);
        add(keyTextDisplay);

        blackBox.alpha = 0;
        keyTextDisplay.alpha = 0;

        FlxTween.tween(keyTextDisplay, {alpha: 1}, 1, {ease: FlxEase.expoInOut});
        FlxTween.tween(infoText, {alpha: 1}, 1.4, {ease: FlxEase.expoInOut});
        FlxTween.tween(blackBox, {alpha: 0.7}, 1, {ease: FlxEase.expoInOut});

        OptionsState.instance.acceptInput = false;

        textUpdate();

		super.create();
	}

	override function update(elapsed:Float)
	{

        switch(state){

            case "select":
                if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(-1);
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(1);
				}

                if (controls.ACCEPT){
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    state = "input";
                }
                else if(controls.BACK){
                    quit();
                }
				else if (controls.RESET){
                    reset();
                }

            case "input":
                tempKey = keys[curSelected];
                keys[curSelected] = "?";
                textUpdate();
                state = "waiting";

            case "waiting":
                if(controls.BACK){
                    keys[curSelected] = tempKey;
                    state = "select";
                    FlxG.sound.play(Paths.sound('confirmMenu'));
                }
                else if(controls.ACCEPT){
                    //addKey(defaultKeys[curSelected]);
                    save();
                    state = "select";
                }
                else if(FlxG.keys.justPressed.ANY){
                    addKey(FlxG.keys.getIsDown()[0].ID.toString());
                    save();
                    state = "select";
                }


            case "exiting":


            default:
                state = "select";

        }

        if(FlxG.keys.justPressed.ANY)
			textUpdate();

		super.update(elapsed);
		
	}

    function textUpdate(){

        keyTextDisplay.text = "\n\n";

        for(i in 0...8){

            var textStart = (i == curSelected) ? "> " : "  ";
            keyTextDisplay.text += textStart + keys[i] + " (" +  keyText[i] + ")\n";
        }
        keyTextDisplay.screenCenter();
    }

    function save(){
        FlxG.save.data.noteLeftBind = keys[0];
        FlxG.save.data.noteDownBind = keys[1];
        FlxG.save.data.noteUpBind = keys[2];
        FlxG.save.data.noteRightBind = keys[3];
        FlxG.save.data.acceptBind = keys[4];
        FlxG.save.data.backBind = keys[5];
        FlxG.save.data.pauseBind = keys[6];
        FlxG.save.data.resetBind = keys[7];

        FlxG.save.flush();

        PlayerSettings.player1.controls.loadKeyBinds();
    }

    function reset()
    {
        for(i in 0...7){
            keys[i] = defaultKeys[i];
        }

        quit();

    }

    function quit(){

        state = "exiting";

        save();

        OptionsState.instance.acceptInput = true;

        FlxTween.tween(keyTextDisplay, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
        FlxTween.tween(blackBox, {alpha: 0}, 1.1, {ease: FlxEase.expoInOut, onComplete: function(flx:FlxTween){close();}});
        FlxTween.tween(infoText, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
    }


	function addKey(r:String){

        var shouldReturn:Bool = true;

        var notAllowed:Array<String> = [];

        trace(notAllowed);

        for(x in 0...keys.length)
            {
                var oK = keys[x];
                if(oK == r)
                    keys[x] = null;
                if (notAllowed.contains(oK))
                    return;
            }

        if(shouldReturn){
            keys[curSelected] = r;
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        else
        {
            keys[curSelected] = tempKey;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            keyWarning.alpha = 1;
            warningTween.cancel();
            warningTween = FlxTween.tween(keyWarning, {alpha: 0}, 0.5, {ease: FlxEase.circOut, startDelay: 2});
        }

	}

    function changeItem(_amount:Int = 0)
    {
        curSelected += _amount;
                
        if (curSelected > 11)
            curSelected = 0;
        if (curSelected < 0)
            curSelected = 11;
    }
}