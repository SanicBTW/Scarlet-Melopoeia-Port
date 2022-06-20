package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;

import animateatlas.AtlasFrameMaker;

#if sys
import Sys;
import sys.FileSystem;
import openfl.Assets;
import sys.io.File;
#end

#if mobileC
import ui.Mobilecontrols;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['F', 0.2], //From 0% to 19%
		['E', 0.4], //From 20% to 39%
		['E+', 0.5], //From 40% to 49%
		['B', 0.6], //From 50% to 59%
		['B+', 0.69], //From 60% to 68%
		['Nicee', 0.7], //69%
		['A', 0.8], //From 70% to 79%
		['A+', 0.9], //From 80% to 89%
		['S', 1], //From 90% to 99%
		['S+', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	
	#if (haxe >= "4.0.0")
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	#else
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, Dynamic>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	#end

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;
	
	public static var songSpeed:Float = 0;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;
	private static var resetSpriteCache:Bool = false;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
        public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;
	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;
	var runCutscene:Bool = false;

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var ghostMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var judgementCounter:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;
	var versionTxt:FlxText;
	var judgementCounterTween:FlxTween;
    var healthCounter:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	#if mobileC
	var mcontrols:Mobilecontrols; 
	#end	

	private var luaArray:Array<FunkinLua> = [];

	//Achievement shit
	var keysPressed:Array<Bool> = [false, false, false, false];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	var precacheList:Map<String, String> = new Map<String, String>();

	var subway:BGSprite;
	var tunnelLight:FlxSprite;

	var REIMUorb:FlxSprite;

	var rumia_fog:FlxSprite;
	var sign:FlxSprite;
	var laser:FlxSprite;

	var daiyousei:FlxSprite;
	var rumia:FlxSprite;
	var sakuya:FlxSprite;

	override public function create()
	{
        #if MODS_ALLOWED
 		Paths.destroyLoadedImages(resetSpriteCache);
  		#end	
		resetSpriteCache = false;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		sicks = 0;
        bads = 0;
		goods = 0;
        shits = 0;

		practiceMode = false;
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = '' + CoolUtil.difficultyStuff[storyDifficulty][0];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;
		trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case "lowest-vibes":
					curStage = "subway";
				case "mystical-maiden" | "eternal-pray":
					curStage = "shrine";
			}
		}
		PlayState.SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case "subway":
				GameOverSubstate.characterName = "coupleGM";
				GameOverSubstate.deathSoundName = "fnf_loss_subway";
				GameOverSubstate.loopSoundName = "subwayLoop";
				GameOverSubstate.endSoundName = "subwayEnd";

				tunnelLight = new FlxSprite(-1250, -200);
				tunnelLight.frames = Paths.getSparrowAtlas('prologue/tunnelLight');
				tunnelLight.animation.addByPrefix("movement", "tunnel", 24, true);
				tunnelLight.scrollFactor.set(1,1);

				subway = new BGSprite('prologue/prologue_subway', -1250, -750);
				subway.scrollFactor.set(1,1);

				add(tunnelLight);
				add(subway);
			case "shrine":
				GameOverSubstate.characterName = "RBF";
				GameOverSubstate.deathSoundName = "fnf_loss_touhou";

				var shrine_sky = new BGSprite("shrine/shrine_sky", -600, -250);
				shrine_sky.scrollFactor.set(0.1, 0.1);
				var shrine_forest = new BGSprite("shrine/shrine_forest", -600, -350);
				shrine_forest.scrollFactor.set(0.3, 0.3);
				var shrine_warehouse = new BGSprite("shrine/shrine_warehouse", -600, -250);
				shrine_warehouse.scrollFactor.set(0.8, 0.8);
				var shrine_ground = new BGSprite("shrine/shrine_ground", -600, -250);
				shrine_ground.scrollFactor.set(0.95, 0.95);
				var shrine_treesback = new BGSprite("shrine/shrine_treesback", -600, -250);
				shrine_treesback.scrollFactor.set(0.9, 0.9);
				var shrine_treesbody = new BGSprite("shrine/shrine_treesbody", -600, -250);
				shrine_treesbody.scrollFactor.set(0.95, 0.95);
				var shrine_treesfront = new BGSprite("shrine/shrine_treesfront", -600, -250);
				shrine_treesfront.scrollFactor.set(0.97, 0.97);
				add(shrine_sky);
				add(shrine_forest);
				add(shrine_warehouse);
				add(shrine_ground);
				add(shrine_treesback);
				add(shrine_treesbody);
				add(shrine_treesfront);

				if(Paths.formatToSongPath(SONG.song) == "mystical-maiden")
				{
					REIMUorb = new FlxSprite(100, 550);
					REIMUorb.frames = Paths.getSparrowAtlas('characters/REIMUorb_Assets');
					REIMUorb.animation.addByPrefix("idle", 'REIMUorb', 24, false);
					REIMUorb.animation.addByPrefix("0", 'PURPLE_REIMUorb', 24, false);
					REIMUorb.animation.addByPrefix("1", 'BLUE_REIMUorb', 24, false);
					REIMUorb.animation.addByPrefix("2", 'GREEN_REIMUorb', 24, false);
					REIMUorb.animation.addByPrefix("3", 'RED_REIMUorb', 24, false);
					REIMUorb.animation.play("idle");
					add(REIMUorb);
				}
			case "entrance":
				GameOverSubstate.characterName = "REIMUnight-player";
				GameOverSubstate.deathSoundName = "fnf_loss_touhou";

				var entrance_nightsky = new BGSprite('entrance/entrance_nightsky', -600, -550);
				entrance_nightsky.scrollFactor.set(0.05, 0.05);
				var entrance_mountains = new BGSprite('entrance/entrance_mountains', -600, -350);
				entrance_mountains.scrollFactor.set(0.1, 0.1);
				var entrance_trees = new BGSprite('entrance/entrance_trees', -600, -450);
				entrance_trees.scrollFactor.set(0.3, 0.3);
				var entrance_ground = new BGSprite('entrance/entrance_ground', -600, -250);
				entrance_ground.scrollFactor.set(0.95, 0.95);

				rumia_fog = new FlxSprite(-500, -1500);
				rumia_fog.frames = Paths.getSparrowAtlas('entrance/rumia_fog');
				rumia_fog.animation.addByPrefix("fog", "rumia_fog", 24, true);
				rumia_fog.scrollFactor.set(0.05, 0);
				rumia_fog.scale.set(1.5, 1.5);

				sign = new FlxSprite(420, 100);
				sign.frames = Paths.getSparrowAtlas("entrance/spell-cards-rumia");
				sign.animation.addByPrefix("demarcation", "spell", 24, false);
				sign.alpha = 0;
				sign.scrollFactor.set(0, 0);

				laser = new FlxSprite(700, 700);
				laser.frames = Paths.getSparrowAtlas("entrance/RUMIA-laser");
				laser.animation.addByPrefix("idle", "RUMIA-laserIdle", 24, false);
				laser.animation.addByPrefix("fire", "RUMIA-laserFire", 24, false);
				laser.alpha = 0;

				add(entrance_nightsky);
				add(entrance_mountains);
				add(entrance_trees);
				add(entrance_ground);

				add(rumia_fog);
				rumia_fog.visible = false;

				add(sign);
				add(laser);

			case "patrol":
				GameOverSubstate.characterName = "PatrolCIRNO";
				GameOverSubstate.deathSoundName = "fnf_loss_cirno";

				var funky_bg = new BGSprite('funky-bg', -400, -250);
				funky_bg.scrollFactor.set(1,1);

				daiyousei = new FlxSprite(950, 350);
				daiyousei.frames = Paths.getSparrowAtlas("patrol/PatrolDAI");
				daiyousei.animation.addByIndices('dance0', 'DAIYOUSEI_idle', [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14], "", 24);
				daiyousei.animation.addByIndices('dance1', 'DAIYOUSEI_idle', [15,16,17,18,19,20,21,22,23,24,25,26,27,28,29], "", 24);
				daiyousei.scrollFactor.set(1,1);
				rumia = new FlxSprite(850, 480);
				rumia.frames = Paths.getSparrowAtlas("patrol/PatrolRUMIA");
				rumia.animation.addByPrefix("idle1", 'PatrolRUMIA', 24, false);
				rumia.animation.addByPrefix("idle2", "PatrolRUMIA", 24, false);
				rumia.scrollFactor.set(0.7, 0.2);
				rumia.scale.set(1.2, 1.2);
				sakuya = new FlxSprite(-350, 420);
				sakuya.frames = Paths.getSparrowAtlas("patrol/PatrolSAKUYA");
				sakuya.animation.addByPrefix("idle1", "PatrolSAKUYA", 24, false);
				sakuya.animation.addByPrefix("idle2", "PatrolSAKUYA", 24, false);
				sakuya.scrollFactor.set(0.7, 0.2);
				sakuya.scale.set(1.2, 1.2);

				add(funky_bg);
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);

		add(dadGroup);
		add(boyfriendGroup);

		//me when layering
		if(curStage == "patrol"){
			add(daiyousei);
			add(rumia);
			add(sakuya);
		}
			

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end


		var gfVersion:String = SONG.player3;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case "entrance" | "patrol":
					gfVersion = "noRGF";
				case "subway":
					gfVersion = "couple";
				case "shrine":
					gfVersion = "RGFbasic";
			}

			SONG.player3 = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 45;

		if(ClientPrefs.timeBarType == 'Song Name')
        {
            timeTxt.text = SONG.song;
        }
        updateTime = showTime;

        if (ClientPrefs.keTimeBar)
            timeBarBG = new AttachedSprite('healthBar');
        else
			timeBarBG = new AttachedSprite('timeBar');

		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		if (ClientPrefs.keTimeBar)
            timeBarBG.screenCenter(X);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		if (ClientPrefs.keTimeBar)
            timeBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
        else
			timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);

		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
        {
            timeTxt.size = 24;
            timeTxt.y += 3;
        }
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys()) {
			var luaToLoad:String = 'custom_notetypes/' + notetype + '.lua';
		    luaToLoad = Paths.getPreloadPath(luaToLoad);			
			if(OpenFlAssets.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(Asset2File.getPath(luaToLoad)));
			}
		}
		for (event in eventPushedMap.keys()) {
			var luaToLoad:String = 'custom_events/' + event + '.lua';
		    luaToLoad = Paths.getPreloadPath(luaToLoad);			
			if(OpenFlAssets.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(Asset2File.getPath(luaToLoad)));
			}
		}	
		#end		

		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.alpha = ClientPrefs.healthBarAlpha;
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		iconP1.visible = !ClientPrefs.hideHud;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		iconP2.visible = !ClientPrefs.hideHud;
		add(iconP2);
		reloadHealthBarColors();

		if (ClientPrefs.scoreType == 'Psych Engine') {
        	scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
            scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        }
        else if (ClientPrefs.scoreType == 'Kade Engine') {
        	scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 20);
        	scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        }
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		if(ClientPrefs.scoreType != 'Disabled') { add(scoreTxt); }

		healthCounter = new FlxText(0, healthBarBG.y - 48, FlxG.width, "" , 20);
        healthCounter.setFormat(Paths.font("vcr.ttf"), 19, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        healthCounter.scrollFactor.set();
        healthCounter.borderSize = 1.25;
        healthCounter.alpha = 1;
        healthCounter.visible = ClientPrefs.healthCounter;
        if(ClientPrefs.healthCounter) { add(healthCounter); }

		if (!ClientPrefs.noAntimash) {
            versionTxt = new FlxText(5, FlxG.height - 24, 0, SONG.song + " - " + CoolUtil.difficultyString() , 16);
        }
    	else if (ClientPrefs.noAntimash) {
            versionTxt = new FlxText(5, FlxG.height - 24, 0, SONG.song + " - " + CoolUtil.difficultyString() + " | no Antimash! " , 16);
        }
		versionTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        versionTxt.scrollFactor.set();
        add(versionTxt);
		
		judgementCounter = new FlxText(20, 0, 0, "", 20);
        judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        judgementCounter.borderSize = 2;
        judgementCounter.borderQuality = 2;
        judgementCounter.scrollFactor.set();
        judgementCounter.screenCenter(Y);
        if(ClientPrefs.judgements) {add(judgementCounter);}
		
		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		judgementCounter.cameras = [camHUD];
		healthCounter.cameras = [camHUD];
		versionTxt.cameras = [camHUD];

		#if mobileC
			mcontrols = new Mobilecontrols();

			switch (mcontrols.mode)
			{
				case VIRTUALPAD_RIGHT | VIRTUALPAD_LEFT | VIRTUALPAD_CUSTOM:
					controls.setVirtualPadNOTES(mcontrols._virtualPad, FULL, NONE);
				case HITBOX:
					controls.setHitBoxNOTES(mcontrols._hitbox);
				default:
			}
			trackedinputsNOTES = controls.trackedinputsNOTES;
			controls.trackedinputsNOTES = [];

			var camcontrol = new FlxCamera();
			FlxG.cameras.add(camcontrol);
			camcontrol.bgColor.alpha = 0;
			mcontrols.cameras = [camcontrol];

			mcontrols.visible = false;

			add(mcontrols);
		#end		

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		// SONG SPECIFIC SCRIPTS
                #if LUA_ALLOWED
                var filesPushed:Array<String> = [];
                var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

                for (folder in foldersToCheck)
                {
                        if(FileSystem.exists(folder))
                        {
                                for (file in FileSystem.readDirectory(folder))
                                {
                                        if(file.endsWith('.lua') && !filesPushed.contains(file))
                                        {
                                                luaArray.push(new FunkinLua(folder + file));
                                                filesPushed.push(file);
                                        }
                                }
                        }
                }
                #end
		updateTime = true;
		
		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'ugh' | 'guns' | 'stress':
					tankIntro();
				default:
					startCountdown();
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSound('missnote1'); 
		CoolUtil.precacheSound('missnote2'); 
		CoolUtil.precacheSound('missnote3'); 
		if (ClientPrefs.playHitSounds) {
			CoolUtil.precacheSound('Tick'); 
			FlxG.sound.play(Paths.sound('Tick'), 0); 
		}
		CoolUtil.precacheSound("laserCharge");
		CoolUtil.precacheSound("laserFire");
		CoolUtil.precacheSound('graze');
		#if desktop
		// Updating Discord Rich Presence.
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
		
		callOnLuas('onCreatePost', []);
		
		super.create();

		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}
		CustomFadeTransition.nextCamera = camOther;
		onCreatePost();
	}

	public function addTextToDebug(text:String) {
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup));
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.alreadyLoaded = false;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.alreadyLoaded = false;
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.alreadyLoaded = false;
				}
		}
	}
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		if(OpenFlAssets.exists(fileName)) 
		{
			foundFile = true;
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
                                if(endingSong) 
			        {
				        endSong();
			        } 
			        else 
			        {
				        startCountdown();
			        }
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			if(endingSong) 
			{
				endSong();
			} 
			else 
			{
				startCountdown();
			}
		}
	}	

	var dialogueCount:Int = 0;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{	
		// TO DO: Make this more flexible, maybe?
		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			if(endingSong) {
				doof.finishThing = endSong;
			} else {
				doof.finishThing = startCountdown;
			}
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countDownSprites:Array<FlxSprite> = [];

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
            #if mobileC
		    mcontrols.visible = true;
		    #end
			generateStaticArrows(0);
			generateStaticArrows(1);

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);

			var swagCounter:Int = 0;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}


				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						ready.scrollFactor.set();
						ready.updateHitbox();

						if (PlayState.isPixelStage)
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

						ready.screenCenter();
						ready.antialiasing = antialias;
						add(ready);
						countDownSprites.push(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(ready);
								remove(ready);
								ready.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						set.scrollFactor.set();

						if (PlayState.isPixelStage)
							set.setGraphicSize(Std.int(set.width * daPixelZoom));

						set.screenCenter();
						set.antialiasing = antialias;
						add(set);
						countDownSprites.push(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(set);
								remove(set);
								set.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						go.scrollFactor.set();

						if (PlayState.isPixelStage)
							go.setGraphicSize(Std.int(go.width * daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						go.antialiasing = antialias;
						add(go);
						countDownSprites.push(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(go);
								remove(go);
								go.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = 1 * note.multAlpha;
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				if (generatedMusic)
				{
					notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				}

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		switch(curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
        songSpeed = SONG.speed;
		if(ClientPrefs.scroll) {
			songSpeed = ClientPrefs.speed;
		}	
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		if (OpenFlAssets.exists(file)) {
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if(songNotes[1] < 0) {
						eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
						eventPushed(songNotes);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);

					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
					
					
					if (section.gfSection){
							trace("got gf section");
						if (songNotes[3] == null || songNotes[3] == ''|| songNotes[3].length ==0){
							swagNote.noteType = 'GF Sing';
							trace("got gf notes");
						}
					}
					
					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);

							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
						}
					}

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else {}

					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
				} else { //Event Notes
					eventNotes.push([songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]]);
					eventPushed(songNotes);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[2]) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event[3].toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(event[3]);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[4];
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event[2])) {
			eventPushedMap.set(event[2], true);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[2]]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event[2]) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
                        if (player < 1) targetAlpha = ClientPrefs.opponentArrowOpacity;
                        else if (player == 1) targetAlpha = targetAlpha = ClientPrefs.arrowOpacity;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else 
			{
                                babyArrow.alpha = targetAlpha;
                        }
			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		callOnLuas('onUpdate', [elapsed]);

		if(candodge == true && FlxG.keys.justPressed.SPACE)
		{
			dodged = true;
			FlxG.sound.play(Paths.sound("graze"), 0.25);
			boyfriend.playAnim("dodge", true);
			boyfriend.specialAnim = true;
			remove(warning);
			candodge = false;
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(ratingString == '?') {
			scoreTxt.text = 'Score: ' + songScore + ' |  Misses: ' + songMisses + ' | Rank: ' + ratingString;
			judgementCounter.text = 'Sicks: 0 \nGoods: 0\nBads: 0\nShits: 0\ne';
            healthCounter.text = 'Health: 50%';
		} else {
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Acc: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | Rank: ' + ratingString + ' (' + ratingFC + ')' ;//peeps wanted no integer rating
            judgementCounter.text = 'Sicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nE';
            healthCounter.text = 'Health: ' + Math.round(health * 50) + '%'  ;
		}

		if(cpuControlled) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		botplayTxt.visible = cpuControlled;

		if (FlxG.keys.justPressed.ENTER#if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					MusicBeatState.switchState(new GitarooPause());
				}
				else {
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();
					}
					PauseSubState.transCamera = camOther;
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				}
			
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.justPressed.SEVEN && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30), 0, 1))));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;
		/*
		if (!ClientPrefs.tabi)
                {
                if (health > 2)
                        health = 2;
                } else {
                var p2ToUse:Float = healthBar.x + (healthBar.width * (FlxMath.remapToRange((health / 2 * 100), 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
                if (iconP2.x - iconP2.width / 2 < healthBar.x && iconP2.x > p2ToUse)
                {
                        healthBarBG.offset.x = iconP2.x - p2ToUse;
                        healthBar.offset.x = iconP2.x - p2ToUse;
                } else {
                        healthBarBG.offset.x = 0;
                        healthBar.offset.x = 0;
                }
                iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange((health / 2 * 100), 0, 100, 100, 0) * 0.01) - iconOffset);
                iconP2.x = p2ToUse;
                if (health > ClientPrefs.tabiMax)
                        health = ClientPrefs.tabiMax;
                }	*/

		if (healthBar.percent < 20) {
			scoreTxt.color = CoolUtil.smoothColorChange(scoreTxt.color, FlxColor.fromRGB(255, 64, 64), 0.3);
			iconP1.animation.curAnim.curFrame = 1;
                }
		else if (healthBar.percent > 80) {
			scoreTxt.color = CoolUtil.smoothColorChange(scoreTxt.color, FlxColor.fromRGB(100, 255, 100), 0.3);
			iconP2.animation.curAnim.curFrame = 1;
                }
		else { 
			scoreTxt.color = CoolUtil.smoothColorChange(scoreTxt.color, FlxColor.fromRGB(255, 255, 255), 0.3);
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
                }

		if (FlxG.keys.justPressed.EIGHT && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					var songCalc:Float = (songLength - curTime);
                                        if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(songSpeed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				if(!daNote.mustPress && ClientPrefs.middleScroll)
				{
					daNote.active = true;
					daNote.visible = false;
				}
				else if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
				if(daNote.mustPress) {
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
				} else {
					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
					strumAngle = opponentStrums.members[daNote.noteData].angle;
					strumAlpha = opponentStrums.members[daNote.noteData].alpha;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var center:Float = strumY + Note.swagWidth / 2;

				if(daNote.copyX) {
					daNote.x = strumX;
				}
				if(daNote.copyAngle) {
					daNote.angle = strumAngle;
				}
				if(daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}
				if(daNote.copyY) {
					if (ClientPrefs.downScroll) {
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote) {
							//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8;
								} else {
									daNote.y -= 19;
								}
							} 
							daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

							if(daNote.mustPress || !daNote.ignoreNote)
							{
								if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
						}
					} else {
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if(daNote.mustPress || !daNote.ignoreNote)
						{
							if (daNote.isSustainNote
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					if (Paths.formatToSongPath(SONG.song) != 'tutorial')
						camZooming = true;

					if(daNote.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = 0.6;
					} else if(!daNote.noAnimation) {
						var altAnim:String = "";

						if (SONG.notes[Math.floor(curStep / 16)] != null)
						{
							if (SONG.notes[Math.floor(curStep / 16)].altAnim || daNote.noteType == 'Alt Animation') {
								altAnim = '-alt';
							}
						}

						var animToPlay:String = '';
						switch (Math.abs(daNote.noteData))
						{
							case 0:
								animToPlay = 'singLEFT';
							case 1:
								animToPlay = 'singDOWN';
							case 2:
								animToPlay = 'singUP';
							case 3:
								animToPlay = 'singRIGHT';
						}
						if(daNote.noteType == 'GF Sing') {
							gf.playAnim(animToPlay + altAnim, true);
							gf.holdTimer = 0;
						} else {
							dad.playAnim(animToPlay + altAnim, true);
							dad.holdTimer = 0;
						}
					}
					//if (camFocus == 'dad' && ClientPrefs.dynamicCam)
					//	triggerCamMovement(Math.abs(note.noteData % 4));
					
					if (SONG.needsVoices)
						vocals.volume = 1;

					var time:Float = 0.15;
					if(daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
						time += 0.15;
					}
					StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)) % 4, time);
					daNote.hitByOpponent = true;

					callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

					if (!daNote.isSustainNote)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * songSpeed));

				var doKill:Bool = daNote.y < -daNote.height;
				if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', PlayState.cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		#end
	}

	var isDead:Bool = false;
	function doDeathCheck() {
		if (health <= 0 && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y, this));
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var early:Float = eventNoteEarlyTrigger(eventNotes[0]);
			var leStrumTime:Float = eventNotes[0][0];
			if(Conductor.songPosition < leStrumTime - early) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0][3] != null)
				value1 = eventNotes[0][3];

			var value2:String = '';
			if(eventNotes[0][4] != null)
				value2 = eventNotes[0][4];

			triggerEventNote(eventNotes[0][2], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				if(lightId > 0 && curLightEvent != lightId) {
					if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if(blammedLightsBlack.alpha == 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
								chars[i].colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					} else {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						blammedLightsBlack.alpha = 1;

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = null;
						}
						dad.color = color;
						boyfriend.color = color;
						gf.color = color;
					}
					
					if(curStage == 'philly') {
						if(phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}
				} else {
					if(blammedLightsBlack.alpha != 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if(curStage == 'philly') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if(phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					var chars:Array<Character> = [boyfriend, gf, dad];
					for (i in 0...chars.length) {
						if(chars[i].colorTween != null) {
							chars[i].colorTween.cancel();
						}
						chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
							chars[i].colorTween = null;
						}, ease: FlxEase.quadInOut});
					}

					curLight = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							if(!boyfriend.alreadyLoaded) {
								boyfriend.alpha = 1;
								boyfriend.alreadyLoaded = true;
							}
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
						}
				}
				reloadHealthBarColors();
			
			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
		}
		else
		{
			moveCamera(false);
		}

		/*
		if(SONG.notes[id] == null) return;

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			
			if (SONG.notes[id].gfSection){
				
				callOnLuas('onMoveCamera', ['gf']);
			}else{
				callOnLuas('onMoveCamera', ['dad']);
			}
		}
		else
		{
			moveCamera(false);
			if (SONG.notes[id].gfSection){
				callOnLuas('onMoveCamera', ['gf']);
			}else{
				callOnLuas('onMoveCamera', ['boyfriend']);
			}
		}*/
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}
	/*
	public function moveCamera(isDad:Bool) {
		
		
		if(isDad) {
//			camFocus = 'dad'
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();
		} else {
//			camFocus = 'bf';
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
		}
		
		if (SONG.notes[Std.int(curStep / 16)].gfSection){
			
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
		}
		
	}*/

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.0475;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.0475;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		#if mobileC
		mcontrols.visible = false;
		#end
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		runCutscene = false; 
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', []);

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!usedPractice) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					usedPractice = false;
					changedDifficulty = false;
					cpuControlled = false;
				}
				else
				{
					var difficulty:String = '' + CoolUtil.difficultyStuff[storyDifficulty][1];

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelFadeTween();
							//resetSpriteCache = true;
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelFadeTween();
						//resetSpriteCache = true;
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				usedPractice = false;
				changedDifficulty = false;
				cpuControlled = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}
	
	var msTxt:FlxText = null;
        var timeShown = 0;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + 8); 
		if (ClientPrefs.playHitSounds)
			FlxG.sound.play(Paths.sound('Tick'));
		
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating  = 'shit';
			shits++;
			score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.5)
		{
			daRating = 'bad';
			bads++;
			score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.25)
		{
			daRating = 'good';
			goods++;
			score = 200;
		}

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
			sicks++;
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			RecalculateRating();
			if(scoreTxtTween != null && judgementCounterTween != null) {
				scoreTxtTween.cancel();
				judgementCounterTween.cancel();
			}
			scoreTxt.scale.x = 1.1;
			scoreTxt.scale.y = 1.1;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
			judgementCounter.scale.x = 1.075;
                        judgementCounter.scale.y = 1.075;
                        judgementCounterTween = FlxTween.tween(judgementCounter.scale, {x: 1, y: 1}, 0.2, {
                                onComplete: function(twn:FlxTween) {
					judgementCounterTween = null;
                                }
                        });
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		if (msTxt != null) {
                        remove(msTxt);
                }

                var msTiming = HelperFunctions.truncateFloat(noteDiff, 3);
                msTxt = new FlxText(0, 0, 0, "0ms");
                        timeShown = 0;
                        switch (daRating)
                        {
                                case 'shit' | 'bad':
                                        msTxt.color = FlxColor.RED;
                                case 'good':
                                        msTxt.color = FlxColor.GREEN;
                                case 'sick':
                                        msTxt.color = FlxColor.CYAN;
                        }

                msTxt.borderStyle = OUTLINE;
                msTxt.borderSize = 1;
                msTxt.borderColor = FlxColor.BLACK;
                msTxt.text = msTiming + "ms";
                msTxt.size = 20;
//                msTxt.cameras = [camHUD];

                if (msTxt.alpha != 1)  {
                                msTxt.alpha = 1;
                }
                                add(msTxt);
		rating.visible = !ClientPrefs.hideHud;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
//		comboSpr.cameras = [camHUD];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		msTxt.velocity.x += comboSpr.velocity.x;
		add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		msTxt.updateHitbox();
		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001,
			onUpdate: function(tween:FlxTween) {
                                        if (msTxt != null)
                                        msTxt.alpha -= 0.02;
                                        timeShown++;
                        }
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();
				if (msTxt != null && timeShown >= 20)
                                {
                                        remove(msTxt);
                                        msTxt = null;
                                }
                                rating.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;

		var upP = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP = controls.NOTE_DOWN_P;
		var leftP = controls.NOTE_LEFT_P;

		var upR = controls.NOTE_UP_R;
		var rightR = controls.NOTE_RIGHT_R;
		var downR = controls.NOTE_DOWN_R;
		var leftR = controls.NOTE_LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
		var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if ((controlHoldArray.contains(true) || controlArray.contains(true)) && !endingSong) {
				var canMiss:Bool = !ClientPrefs.ghostTapping;
				if (controlArray.contains(true)) {
					for (i in 0...controlArray.length) {
						// heavily based on my own code LOL if it aint broke dont fix it
						var pressNotes:Array<Note> = [];
						var notesDatas:Array<Int> = [];
						var notesStopped:Bool = false;

						var sortedNotesList:Array<Note> = [];
						notes.forEachAlive(function(daNote:Note)
						{
							if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate 
							&& !daNote.wasGoodHit && daNote.noteData == i) {
								sortedNotesList.push(daNote);
								notesDatas.push(daNote.noteData);
								if (!ClientPrefs.noAntimash) {  // Credits to tposejank
								        canMiss = true;
								}
							}
						});
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							for (epicNote in sortedNotesList)
							{
								for (doubleNote in pressNotes) {
									if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10) {
										doubleNote.kill();
										notes.remove(doubleNote, true);
										doubleNote.destroy();
									} else
										notesStopped = true;
								}
									
								// eee jack detection before was not super good
								if (controlArray[epicNote.noteData] && !notesStopped) {
									goodNoteHit(epicNote);
									pressNotes.push(epicNote);
								}

							}
						}
						else if (canMiss) 
							ghostMiss(controlArray[i], i, true);

						// I dunno what you need this for but here you go
						//									- Shubs

						// Shubs, this is for the "Just the Two of Us" achievement lol
						//									- Shadow Mario
						if (!keysPressed[i] && controlArray[i]) 
							keysPressed[i] = true;
					}
				}

				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			} else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		playerStrums.forEach(function(spr:StrumNote)
		{
			if(controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm') {
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			if(controlReleaseArray[spr.ID]) {
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		});
	}

	function ghostMiss(statement:Bool = false, direction:Int = 0, ?ghostMiss:Bool = false) {
		if (statement) {
			noteMissPress(direction, ghostMiss);
			callOnLuas('noteMissPress', [direction]);
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		health -= daNote.missHealth; //For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		RecalculateRating();

		var animToPlay:String = '';
		switch (Math.abs(daNote.noteData) % 4)
		{
			case 0:
				animToPlay = 'singLEFTmiss';
			case 1:
				animToPlay = 'singDOWNmiss';
			case 2:
				animToPlay = 'singUPmiss';
			case 3:
				animToPlay = 'singRIGHTmiss';
		}

		if(daNote.noteType == 'GF Sing') {
			gf.playAnim(animToPlay, true);
		} else {
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			boyfriend.playAnim(animToPlay + daAlt, true);
		}
		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1, ?ghostMiss:Bool = false):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.04;
			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				if(ghostMiss) ghostMisses++;
				songMisses++;
			}
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			switch (direction)
			{
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
			}
			vocals.volume = 0;
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				var animToPlay:String = '';
				switch (Std.int(Math.abs(note.noteData)))
				{
					case 0:
						animToPlay = 'singLEFT';
					case 1:
						animToPlay = 'singDOWN';
					case 2:
						animToPlay = 'singUP';
					case 3:
						animToPlay = 'singRIGHT';
				}

				if(note.noteType == "REIMU-Bullet Note")
				{
					var dir = "0";
					switch(Std.int(Math.abs(note.noteData)))
					{
						case 0:
							dir = "0";
						case 1:
							dir = "1";
						case 2:
							dir = "2";
						case 3:
							dir = "3";
					}
					REIMUorb.animation.play(dir);
				}

				if(note.noteType == 'GF Sing') {
					if(gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				} else {
					boyfriend.playAnim(animToPlay + daAlt, true);
					boyfriend.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD 
			var leData:Int = Math.round(Math.abs(note.noteData)); 
			var leType:String = note.noteType; 
//			if (camFocus == 'bf' && ClientPrefs.dynamicCam) 
				//triggerCamMovement(Math.abs(note.noteData % 4));

			callOnLuas('goodNoteHit', 
			[notes.members.indexOf(note), leData, leType, isSus]);
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];
		super.destroy();
	}

	public function cancelFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		if(curStage == "subway")
		{
			switch(curStep)
			{
				case 0:
					gfSpeed = 4;
				case 15:
					/* haxe ver must be above 4.1.5 lol, though i dont understand this one
					for(i in 0...3)
					{
						strumLineNotes[i].alpha = 0;
					}
					for(i in 4...7)
					{
						strumLineNotes[i].x = i*200-515;
					}
					*/
					FlxTween.tween(camHUD, {alpha: 1}, 1.5, {ease: FlxEase.linear});
				case 30:
					FlxTween.tween(gf, {alpha: 1}, 3, {ease: FlxEase.linear});
				case 90:
					gfSpeed = 2;
				case 120:
					FlxTween.tween(subway, {alpha: 1}, 3, {ease: FlxEase.linear});
				case 135:
					gfSpeed = 1;
				case 142:
					FlxTween.tween(tunnelLight, {alpha: 1}, 3, {ease: FlxEase.linear});
				case 150:
					gfSpeed = 4;
			}
		}

		if(curStage == "entrance")
		{
			switch(curStep)
			{
				case 132:
					FlxTween.tween(laser, {alpha: 1}, 1, {ease: FlxEase.linear});
					FlxG.sound.play(Paths.sound("laserCharge"), 0.25);
				case 136:
					dodge(0.85);
				case 144:
					laser.animation.play("fire");
					FlxG.sound.play(Paths.sound("laserFire"), 0.1);
				case 146:
					rumia_fog.visible = false;
					FlxTween.tween(sign, {alpha: 0}, 1.5, {ease: FlxEase.linear});
					FlxTween.tween(laser, {alpha: 0}, 1, {ease: FlxEase.linear});
				case 680:
					dad.playAnim("reveal", true);
					dad.idleSuffix = "-alt";
					dad.recalculateDanceIdle();
					addcamzoom(0.25, 0.09);
				case 688:
					rumia_fog.visible = true;
					FlxTween.tween(sign, {alpha: 1}, 1.5, {ease: FlxEase.linear});
					addcamzoom(0.5, 0.09);
			}
		}

		if(curStage == "patrol")
		{
			switch(curStep)
			{
				case 693:
					//i might remove this, i only wanted to have fun lmao
					if(ClientPrefs.constDodging == true){
						dodge(0.5);
					}
				case 696:
					dad.playAnim("shoot");
					dad.specialAnim = true;
					if(ClientPrefs.constDodging == false){
						boyfriend.playAnim("dodge");
						boyfriend.specialAnim = true;
					}
			}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
			if (ClientPrefs.iconBoping) {
				var funny:Float = (healthBar.percent * 0.01) + 0.01;
        		if (curBeat % gfSpeed == 0) { 
					curBeat % (gfSpeed * 2) == 0 ? {
        		    	iconP1.scale.set(1.1, 0.8);
        		    	iconP2.scale.set(1.1, 1.3);

        		        FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
        		        FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
        		    } : {
        		        iconP1.scale.set(1.1, 1.3);
        		        iconP2.scale.set(1.1, 0.8);

        		        FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
        		        FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
        		    }

        		    FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
        		    FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

        			iconP1.updateHitbox();
        			iconP2.updateHitbox();
        			}
			}
		{
			gf.dance();
		}

		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case "shrine":
				if(Paths.formatToSongPath(SONG.song) == "mystical-maiden")
				{
					if(curBeat % 2 == 0)
					{
						REIMUorb.animation.play("idle");
					}
				}
			case "entrance":
				if(curBeat % 2 == 0)
				{
					sign.animation.play("demarcation");
				}
			case "patrol":
				if(curBeat % 2 == 0)
				{
					daiyousei.animation.play("dance0");
					rumia.animation.play("idle1");
					sakuya.animation.play("idle1");
				}
				if(curBeat % 2 == 1)
				{
					daiyousei.animation.play("dance1");
					rumia.animation.play("idle2");
					sakuya.animation.play("idle2");
				}
		}

		if(curBeat % 2 == 0 && ClientPrefs.constDodging == true)
		{
			dodge(0.85);
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingString:String;
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('ghostMisses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop) {
			ratingPercent = songScore / ((songHits + songMisses - ghostMisses) * 350);
			if(!Math.isNaN(ratingPercent) && ratingPercent < 0) ratingPercent = 0;

			if(Math.isNaN(ratingPercent)) {
				ratingString = '?';
			} else if(ratingPercent >= 1) {
				ratingPercent = 1;
				ratingString = ratingStuff[ratingStuff.length-1][0]; //Uses last string
			} else {
				for (i in 0...ratingStuff.length-1) {
					if(ratingPercent < ratingStuff[i][1]) {
						ratingString = ratingStuff[i][0];
						break;
					}
				}
			}
			ratingFC = "";
	                   if (sicks > 0) ratingFC = "SFC";
		               if (goods > 0) ratingFC = "GFC";
		               if (bads > 0 || shits > 0) ratingFC = "FC";
		                   if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			                   else if (songMisses >= 10) ratingFC = "Clear";

			setOnLuas('rating', ratingPercent);
			setOnLuas('ratingName', ratingString);
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String>):String {
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName)) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode && !cpuControlled) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice && !cpuControlled) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 20 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;

	function tankIntro()
	{
		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		//inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);

		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;

		var tankmanEnd:Void->Void = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;

			var stuff:Array<FlxSprite> = [tankman, gfDance, gfCutscene, picoCutscene, boyfriendCutscene];
			for (char in stuff)
			{
				char.kill();
				remove(char);
				char.destroy();
			}
			//Paths.clearUnusedMemory();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				FlxG.sound.playMusic(Paths.music('DISTORTO'), 0, false);
				FlxG.sound.music.fadeIn();

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				new FlxTimer().start(3, function(tmr:FlxTimer)
				{
					camFollow.x += 800;
					camFollow.y += 100;

					// Beep!
					new FlxTimer().start(1.5, function(tmr:FlxTimer)
					{
						boyfriend.playAnim('singUP', true);
						boyfriend.specialAnim = true;
						FlxG.sound.play(Paths.sound('bfBeep'));
					});

					// Move camera to Tankman
					new FlxTimer().start(3, function(tmr:FlxTimer)
					{
						camFollow.x -= 800;
						camFollow.y -= 100;

						tankman.animation.play('killYou', true);
						FlxG.sound.play(Paths.sound('killYou'));

						// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
						new FlxTimer().start(6.1, function(tmr:FlxTimer)
						{
							tankmanEnd();
						});
					});
				});

			case 'guns':
				tankman.x += 40;
				tankman.y += 10;

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				FlxG.sound.playMusic(Paths.music('DISTORTO'), 0, false);
				FlxG.sound.music.fadeIn();

				new FlxTimer().start(0.01, function(tmr:FlxTimer) //Fixes sync????
				{
					tightBars.play(true);
				});

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				new FlxTimer().start(4, function(tmr:FlxTimer)
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

				new FlxTimer().start(11.6, function(tmr:FlxTimer)
				{
					tankmanEnd();

					gf.dance();
					gf.animation.finishCallback = null;
				});

			case 'stress':
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('cutscenes/stress2', 'image');

				gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
				gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
				gfDance.animation.play('dance', true);
				addBehindGF(gfDance);

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				addBehindGF(gfCutscene);
				gfCutscene.alpha = 0.00001;

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				new FlxTimer().start(0.01, function(tmr:FlxTimer) //Fixes sync????
				{
					cutsceneSnd.play(true);
				});

				new FlxTimer().start(15.2, function(tmr:FlxTimer)
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
					new FlxTimer().start(2.3, function(tmr:FlxTimer)
					{
						zoomBack();
					});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				new FlxTimer().start(19.5, function(tmr:FlxTimer)
				{
					tankman.frames = Paths.getSparrowAtlas('cutscenes/stress2');
					tankman.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman.animation.play('lookWhoItIs', true);
					tankman.x += 90;
					tankman.y += 6;

					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						camFollow.set(dad.x + 500, dad.y + 170);
					});
				});

				new FlxTimer().start(31.2, function(tmr:FlxTimer)
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});

					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						zoomBack();
					});
				});

				new FlxTimer().start(35.5, function(tmr:FlxTimer)
				{
					tankmanEnd();
					boyfriend.animation.finishCallback = null;
				});
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

/*	var camFocus:String = "";
	var daFunneOffsetMultiplier:Float = 20;
	var dadPos:Array<Float> = [0, 0];
	var bfPos:Array<Float> = [0, 0];
	function triggerCamMovement(num:Float = 0)
	{
		if (camFocus == 'bf')
		{
			switch (num)
			{
				case 2:
					camFollow.y = bfPos[1] - daFunneOffsetMultiplier;
					camFollow.x = bfPos[0];
				case 3:
					camFollow.x = bfPos[0] + daFunneOffsetMultiplier;
					camFollow.y = bfPos[1];
				case 1:
					camFollow.y = bfPos[1] + daFunneOffsetMultiplier;
					camFollow.x = bfPos[0];
				case 0:
					camFollow.x = bfPos[0] - daFunneOffsetMultiplier;
					camFollow.y = bfPos[1];
			}
		}
		else
		{
			switch (num)
			{
				case 2:
					camFollow.y = dadPos[1] - daFunneOffsetMultiplier;
					camFollow.x = dadPos[0];
				case 3:
					camFollow.x = dadPos[0] + daFunneOffsetMultiplier;
					camFollow.y = dadPos[1];
				case 1:
					camFollow.y = dadPos[1] + daFunneOffsetMultiplier;
					camFollow.x = dadPos[0];
				case 0:
					camFollow.x = dadPos[0] - daFunneOffsetMultiplier;
					camFollow.y = dadPos[1];
			}
		}
	}

	function getCamOffsets()
	{
		dadPos[0] = dad.getMidpoint().x + 150 + dad.cameraPosition[0];
		dadPos[1] = dad.getMidpoint().y - 100 + dad.cameraPosition[1];

		switch (curStage)
		{
			case 'limo':
				bfPos[0] = boyfriend.getMidpoint().x - 110;
				bfPos[1] = boyfriend.getMidpoint().y - 95;
			case 'mall':
				bfPos[0] = boyfriend.getMidpoint().x - 100;
				bfPos[1] = boyfriend.getMidpoint().y - 165;
			case 'school' | 'schoolEvil':
				bfPos[0] = boyfriend.getMidpoint().x - 290;
				bfPos[1] = boyfriend.getMidpoint().y - 300;
			default:
				bfPos[0] = boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0];
				bfPos[1] = boyfriend.getMidpoint().y - 100 + boyfriend.cameraPosition[1];
			//bedrock engine my beloved
		} //not working in 0.4.2 sadly
	} */

	function onCreatePost()
	{
		warning = new FlxSprite(9999, 9999);
		warning.frames = Paths.getSparrowAtlas("RUMIA-warning");
		warning.animation.addByPrefix("warning", "warning", 25, true);
		warning.cameras = [camOther];
		warning.scale.set(0.50, 0.50);		

		switch(curStage)
		{
			case "subway":
				camHUD.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				gf.alpha = 0;
				subway.alpha = 0;
				tunnelLight.alpha = 0;
				camGame.shake(0.00075, 115.99);		
		}
	}

	var dodged = false;
	var candodge = false;
	var dodgetime:Float = 0;
	var warning:FlxSprite;
	var died = new FlxTimer();
	function dodge(time:Float)
	{
		dodgetime = time;
		warning.x = 440;
		warning.y = 200;
		warning.animation.play("warning");
		add(warning);
		FlxG.sound.play(Paths.sound("warning"));
		candodge = true;
		died.start(dodgetime, timer -> ({
			if(dodged == false){
				health = 0;
			} else if(dodged == true){
				dodged = false;
			}
		}));
	}

	function addcamzoom(value1:Float, value2:Float)
	{
		var camZoom:Float = value1;
		var hudZoom:Float = value2;
		if(Math.isNaN(camZoom)) camZoom = 0.015;
		if(Math.isNaN(hudZoom)) hudZoom = 0.03;

		FlxG.camera.zoom += camZoom;
		camHUD.zoom += hudZoom;
	}
}
