package;

import flixel.ui.FlxButton;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
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
import openfl.media.Video;
import openfl.utils.Assets as OpenFlAssets;
#if sys
import openfl.system.System;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	]; 

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

	public var boyfriendGroup:FlxTypedGroup<Boyfriend>;
	public var dadGroup:FlxTypedGroup<Character>;
	public var gfGroup:FlxTypedGroup<Character>;

	public static var curStage:String = '';
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
	private var curSection:Int = 0;

	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	private var camZooming:Bool = true;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:FlxSprite;
	private var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;
	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;
	public static var displaySongName:String = "";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
    public var shits:Int = 0;

	public static var inst:Dynamic;
	public static var voices:Dynamic;
	var campointX:Float = 0;
	var campointY:Float = 0;
	var bfturn:Bool = false;

	public static var startedSong = false;

	var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	var subway:FlxSprite;
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
		PauseSubState.songName = null; //Reset to default

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		practiceMode = false;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		var songName:String = SONG.song;
		displaySongName = StringTools.replace(songName, '-', ' ');

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
		switch(songName.toLowerCase().replace(" ", "-"))
		{
			case "lowest-vibes":
				curStage = "subway";

				defaultCamZoom = 1;
				BF_X = -400;
				BF_Y = -200;

				GF_X = -400;
				GF_Y = -200;

				DAD_X = -400;
				DAD_Y = -200;

				GameOverSubstate.characterName = "coupleGM";
				GameOverSubstate.deathSoundName = "fnf_loss_subway";
				GameOverSubstate.loopSoundName = "subwayLoop";
				GameOverSubstate.endSoundName = "subwayEnd";

				tunnelLight = new FlxSprite(-1250, -200);
				tunnelLight.frames = Paths.getSparrowAtlas('prologue/tunnelLight');
				tunnelLight.animation.addByPrefix("movement", "tunnel", 24, true);
				tunnelLight.scrollFactor.set(1,1);

				subway = new FlxSprite(-1250, -750).loadGraphic(Paths.image('prologue/prologue_subway'));
				subway.scrollFactor.set(1,1);

				add(tunnelLight);
				add(subway);

			case "mystical-maiden" | "eternal-pray":
				curStage = "shrine";

				defaultCamZoom = 0.8;
				BF_X = 770;
				BF_Y = 100;

				GF_X = 300;
				GF_Y = 200;

				DAD_X = 100;
				DAD_Y = 100;

				GameOverSubstate.characterName = "RBF";
				GameOverSubstate.deathSoundName = "fnf_loss_touhou";

				var shrine_sky = new FlxSprite(-600, -250).loadGraphic(Paths.image("shrine/shrine_sky"));
				shrine_sky.scrollFactor.set(0.1, 0.1);
				var shrine_forest = new FlxSprite(-600, -350).loadGraphic(Paths.image("shrine/shrine_forest"));
				shrine_forest.scrollFactor.set(0.3, 0.3);
				var shrine_warehouse = new FlxSprite(-600, -250).loadGraphic(Paths.image("shrine/shrine_warehouse"));
				shrine_warehouse.scrollFactor.set(0.8, 0.8);
				var shrine_ground = new FlxSprite(-600, -250).loadGraphic(Paths.image("shrine/shrine_ground"));
				shrine_ground.scrollFactor.set(0.95, 0.95);
				var shrine_treesback = new FlxSprite(-600, -250).loadGraphic(Paths.image("shrine/shrine_treesback"));
				shrine_treesback.scrollFactor.set(0.9, 0.9);
				var shrine_treesbody = new FlxSprite(-600, -250).loadGraphic(Paths.image("shrine/shrine_treesbody"));
				shrine_treesbody.scrollFactor.set(0.95, 0.95);
				var shrine_treesfront = new FlxSprite(-600, -250).loadGraphic(Paths.image("shrine/shrine_treesfront"));
				shrine_treesfront.scrollFactor.set(0.97, 0.97);
				add(shrine_sky);
				add(shrine_forest);
				add(shrine_warehouse);
				add(shrine_ground);
				add(shrine_treesback);
				add(shrine_treesbody);
				add(shrine_treesfront);

				if(songName.toLowerCase().replace(" ", "-") == "mystical-maiden")
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

			case 'youkai-of-the-dark':
				curStage = "entrance";

				defaultCamZoom = 0.8;
				BF_X = 1200;
				BF_Y = 630;

				GF_X = 800;
				GF_Y = 710;

				DAD_X = -300;
				DAD_Y = 100;

				GameOverSubstate.characterName = "REIMUnight-player";
				GameOverSubstate.deathSoundName = "fnf_loss_touhou";

				var entrance_nightsky = new FlxSprite(-600, -550).loadGraphic(Paths.image('entrance/entrance_nightsky'));
				entrance_nightsky.scrollFactor.set(0.05, 0.05);
				var entrance_mountains = new FlxSprite(-600, -350).loadGraphic(Paths.image('entrance/entrance_mountains'));
				entrance_mountains.scrollFactor.set(0.1, 0.1);
				var entrance_trees = new FlxSprite(-600, -450).loadGraphic(Paths.image('entrance/entrance_trees'));
				entrance_trees.scrollFactor.set(0.3, 0.3);
				var entrance_ground = new FlxSprite(-600, -250).loadGraphic(Paths.image('entrance/entrance_ground'));
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

			case "funky-patrol":
				curStage = "patrol";

				defaultCamZoom = 1;
				BF_X = 470;
				BF_Y = 120;

				GF_X = 250;
				GF_Y = 200;

				DAD_X = 50;
				DAD_Y = 100;

				GameOverSubstate.characterName = "PatrolCIRNO";
				GameOverSubstate.deathSoundName = "fnf_loss_cirno";

				var funky_bg = new FlxSprite(-400, -250).loadGraphic(Paths.image('funky-bg'));
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
				default:
					gfVersion = 'gf';
			}
			SONG.player3 = gfVersion;
		}

		boyfriendGroup = new FlxTypedGroup<Boyfriend>();
		dadGroup = new FlxTypedGroup<Character>();
		gfGroup = new FlxTypedGroup<Character>();

		gf = new Character(GF_X, GF_Y, gfVersion);
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);

		dad = new Character(DAD_X, DAD_Y, SONG.player2);
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
		dadGroup.add(dad);

		boyfriend = new Boyfriend(BF_X, BF_Y, SONG.player1);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriendGroup.add(boyfriend);
		
		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		if(curStage == "patrol"){
			add(daiyousei);
			add(rumia);
			add(sakuya);
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = !ClientPrefs.hideTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 45;

		timeBarBG = new FlxSprite(timeTxt.x, timeTxt.y + (timeTxt.height / 4)).loadGraphic(Paths.image('timeBar'));
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = !ClientPrefs.hideTime;
		timeBarBG.color = FlxColor.BLACK;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = !ClientPrefs.hideTime;
		add(timeBar);
		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

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
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		if(!ClientPrefs.optHideHealthBar){
			add(healthBarBG);
		}
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		if(!ClientPrefs.optHideHealthBar){
			add(healthBar);
		}
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !ClientPrefs.hideHud;
		if(!ClientPrefs.optHideHealthBar){
			add(iconP1);
		}

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !ClientPrefs.hideHud;
		if(!ClientPrefs.optHideHealthBar){
			add(iconP2);
			reloadHealthBarColors();
		}

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

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

		#if android
		addAndroidControls();
		androidControls.visible = true;
		addPadCamera();
		#end

		startingSong = true;
		updateTime = true;

		startCountdown();
		RecalculateRating();

		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		if(PauseSubState.songName != null){
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != null) {
			CoolUtil.precacheMusic(ClientPrefs.pauseMusic.toLowerCase().replace(" ", "-"));
		}
		
		if(curStage == "entrance")
		{
			CoolUtil.precacheSound("laserCharge");
			CoolUtil.precacheSound("laserFire");
			CoolUtil.precacheSound('graze');
		}
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.create();
		onCreatePost();
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
					var newBoyfriend:Boyfriend = new Boyfriend(BF_X, BF_Y, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.visible = false;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(DAD_X, DAD_Y, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad);
					newDad.visible = false;
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(GF_X, GF_Y, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.visible = false;
				}
		}
	}
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	var perfectMode:Bool = false;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			return;
		}

		inCutscene = false;
		generateStaticArrows(0);
		generateStaticArrows(1);
		for (i in 0...playerStrums.length) {
		}
		for (i in 0...opponentStrums.length) {
			if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
		}

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
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

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = ClientPrefs.globalAntialiasing;
			var altSuffix:String = "";

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					ready.screenCenter();
					ready.antialiasing = antialias;
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					set.screenCenter();
					set.antialiasing = antialias;
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					go.updateHitbox();

					go.screenCenter();
					go.antialiasing = antialias;
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			if (generatedMusic)
			{
				notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
			}

			swagCounter += 1;
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		#if sys
		System.gc();
		#end

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(inst, 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end

		startedSong = true;
	}

	private function generateSong(dataPath:String):Void
	{
		#if sys
		System.gc();
		#end

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(voices);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(inst));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = SONG.song.toLowerCase();
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (sys.FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if(songNotes[1] < 0) {
						eventNotes.push(songNotes);
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
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]];

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(SONG.speed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);

							sustainNote.mustPress = gottaHitNote;

							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
						}
					}

					swagNote.mustPress = gottaHitNote;

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else {}
				} else { //Event Notes
					eventNotes.push(songNotes);
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

		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[2]) {
			case 'Change Character':
				var charType:Int = Std.parseInt(event[3]);
				if(Math.isNaN(charType)) charType = 0;

				var newCharacter:String = event[4];
				addCharacterToList(newCharacter, charType);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
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
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i);

			var skin:String = "NOTE_assets";
			if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;

			babyArrow.frames = Paths.getSparrowAtlas(skin);
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.antialiasing = ClientPrefs.globalAntialiasing;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (Math.abs(i))
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.y -= 10;
			babyArrow.alpha = 1;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			switch(player)
			{
				case 0:
					opponentStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.playAnim('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
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

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
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

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
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
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
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
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
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

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		super.update(elapsed);

		switch(curStage)
		{
			default:
				if(ClientPrefs.optHideHealthBar)
				{
					if(ratingString == 'N/A') {
						scoreTxt.text = 'HP: ' + Math.round(health * 50) + '% | Score: ' + songScore + ' | Misses: ' + songMisses + ' | ' + ratingString;
					} else {
						scoreTxt.text = 'HP: ' + Math.round(health * 50) + '% | Score: ' + songScore + ' | Misses: ' + songMisses + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | ' + ratingString + ' (' + ratingFC + ')' ;
					}
				}
				else
				{
					if(ratingString == 'N/A') {
						scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | ' + ratingString;
					} else {
						scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | ' + ratingString + ' (' + ratingFC + ')' ;
					}
				}
		}

		if(cpuControlled) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		botplayTxt.visible = cpuControlled;

		if (FlxG.keys.justPressed.ENTER #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if(FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health >= 2)
			health = 2;

		if (healthBar.percent < 20) 
		{
			scoreTxt.color = CoolUtil.smoothColorChange(scoreTxt.color, FlxColor.fromRGB(255, 64, 64), 0.3);
			iconP1.animation.curAnim.curFrame = 1;
        }
		else if (healthBar.percent > 80) 
		{
			scoreTxt.color = CoolUtil.smoothColorChange(scoreTxt.color, FlxColor.fromRGB(100, 255, 100), 0.3);
			iconP2.animation.curAnim.curFrame = 1;
        }
		else 
		{ 
			scoreTxt.color = CoolUtil.smoothColorChange(scoreTxt.color, FlxColor.fromRGB(255, 255, 255), 0.3);
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
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

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if(updateTime) {
					var curTime:Float = FlxG.sound.music.time - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					var minutesRemaining:Int = Math.floor(secondsTotal / 60);
					var secondsRemaining:String = '' + secondsTotal % 60;
					if(secondsRemaining.length < 2) secondsRemaining = '0' + secondsRemaining; //Dunno how to make it display a zero first in Haxe lol
					timeTxt.text = minutesRemaining + ':' + secondsRemaining;
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
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

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
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
				var strumY:Float = 0;
				if(daNote.mustPress) {
					strumY = playerStrums.members[daNote.noteData].y;
				} else {
					strumY = opponentStrums.members[daNote.noteData].y;
				}
				var center:Float = strumY + Note.swagWidth / 2;

				if (ClientPrefs.downScroll) {
					daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
					if (daNote.isSustainNote) {
						//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
							if(curStage == 'school' || curStage == 'schoolEvil') {
								daNote.y += 8;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				} else {
					daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

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

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition) {
						goodNoteHit(daNote);
					}
				}

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

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE)
				FlxG.sound.music.onComplete();
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
		#end
	}


	public var isDead:Bool = false;
	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if((skipHealthCheck || health <= 0) && !practiceMode && !isDead) 
		{
			boyfriend.stunned = true;
			deathCounter++;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, displaySongName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?onLua:Bool = false) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = Std.parseInt(value1);
				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter == 'gf') { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
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

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				trace('Anim to play: ' + value1);
				var val2:Int = Std.parseInt(value2);
				if(Math.isNaN(val2)) val2 = 0;

				var char:Character = dad;
				switch(val2) {
					case 1: char = boyfriend;
					case 2: char = gf;
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
				var val:Int = Std.parseInt(value1);
				if(Math.isNaN(val)) val = 0;

				var char:Character = dad;
				switch(val) {
					case 1: char = boyfriend;
					case 2: char = gf;
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
				var charType:Int = Std.parseInt(value1);
				if(Math.isNaN(charType)) charType = 0;

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = true;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf) {
									gf.visible = true;
								}
							} else {
								gf.visible = false;
							}
							dad.visible = true;
							iconP2.changeIcon(dad.healthIcon);
						}

					case 2:
						if(gf.curCharacter != value2) {
							if(!gfMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var isGfVisible:Bool = gf.visible;
							gf.visible = false;
							gf = gfMap.get(value2);
							gf.visible = isGfVisible;
						}

				}
		}
	}

	function moveCameraSection(?id:Int = 0):Void {
		if (SONG.notes[id] != null && camFollow.x != dad.getMidpoint().x + 150 && !SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			campointX = camFollow.x;
			campointY = camFollow.y;
			bfturn = false;
		}

		if (SONG.notes[id] != null && SONG.notes[id].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			moveCamera(false);
			campointX = camFollow.x;
			campointY = camFollow.y;
			bfturn = true;
		}
	}

	public function moveCamera(isDad:Bool) {
		if(isDad) {
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
		} else {
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];
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

	function endSong():Void
	{
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;
		KillNotes();

		if (SONG.validScore && !cpuControlled)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
		}

		trace('WENT BACK TO FREEPLAY??');
		MusicBeatState.switchState(new FreeplayState());
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
		usedPractice = false;
		changedDifficulty = false;
		cpuControlled = false;
	}

	private function KillNotes() {
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

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);
		vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		coolText.cameras = [camHUD];

		var rating:FlxSprite = new FlxSprite();
		var score:Float = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			shits++;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			bads++;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.25)
		{
			daRating = 'good';
			score = 200;
			goods++;
		}

		if (daRating != 'shit' || daRating != 'bad')
		{
			sicks++;
			songScore += Math.round(score);
			songHits++;

			if (!ClientPrefs.optDisableScoreTween)
			{
				if(!cpuControlled)
				{
					if(scoreTxtTween != null) {
						scoreTxtTween.cancel();
					}
					scoreTxt.scale.x = 1.075;
					scoreTxt.scale.y = 1.075;
					scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
						onComplete: function(twn:FlxTween) {
							scoreTxtTween = null;
						}
					});
				}
			}

			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';

			rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
			rating.cameras = [camHUD];
			rating.screenCenter();
			rating.x = coolText.x - 40;
			rating.y -= 60;
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);
			rating.visible = (!ClientPrefs.hideHud);
			
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.cameras = [camHUD];
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;
			comboSpr.visible = (!ClientPrefs.hideHud);
			comboSpr.velocity.x += FlxG.random.int(1, 10);

			if(!cpuControlled) insert(members.indexOf(strumLineNotes), rating);

			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;

			comboSpr.updateHitbox();
			rating.updateHitbox();

			var seperatedScore:Array<Int> = [];

			if(combo >= 1000) {
				seperatedScore.push(Math.floor(combo / 1000) % 10);
			}
			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);
			seperatedScore.push(combo % 10);

			comboSpr.cameras = [camHUD];
			rating.cameras = [camHUD];

			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				numScore.cameras = [camHUD];
				numScore.screenCenter();
				numScore.x = coolText.x + (43 * daLoop) - 90;
				numScore.y += 80;

				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = ClientPrefs.globalAntialiasing;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
				comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));

				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
				numScore.visible = !ClientPrefs.hideHud;
				
				if(!cpuControlled) insert(members.indexOf(strumLineNotes), numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});

				daLoop++;
			}

			coolText.text = Std.string(seperatedScore);

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					coolText.destroy();
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});	
		}
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
								canMiss = true;
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
						{
							if(controlArray[i])
							{
								noteMissPress(i);
							}
						}
					}
				}

			} else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
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

	//look into the handling more deeply
	function noteMiss(direction:Int = 0, daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			notes.forEachAlive(function(note:Note) {
				if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10) {
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
			});

			var bleed = new FlxTimer();

			switch(daNote.noteType)
			{
				case 'RUMIA-Hurt 1' | 'RUMIA-Hurt 2-GREEN' | 'RUMIA-Hurt 2-BLUE' | 'RUMIA-Hurt 2-RED':
				case "RUMIA-Bullet Note":
					health -= 0.25;
					bleed.start(0.2, timer -> {
						health -= 0.001;
					}, 20);
					boyfriend.playAnim(singAnims[Std.int(Math.abs(daNote.noteData)) % 4] + "miss", true);
				case "REIMU-Bullet Note":
					if(storyDifficulty == 2)
					{
						health -= 1;
					}
					else
					{
						health -= 0.8;
						boyfriend.playAnim(singAnims[Std.int(Math.abs(daNote.noteData)) % 4] + "miss", true);
						bleed.start(0.2, timer -> {
							health -= 0.001;
						}, 20);
					}
				default:
					combo = 0;
					health -= 0.04;
					if(!practiceMode) songScore -= 10;
					if(!endingSong){
						songMisses++;
					}
					vocals.volume = 0;
					RecalculateRating();

					var char:Character = boyfriend;
					if(daNote.gfNote) { char = gf; }

					if(char != null)
					{
						var daAlt = '';
						if(daNote.noteType == "Alt Animation") daAlt = '-alt';
		
						char.playAnim(singAnims[Std.int(Math.abs(daNote.noteData)) % 4] + "miss" + daAlt, true);
					}
		
					FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			}
		}
	}

	function noteMissPress(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05;
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			RecalculateRating();

			var char:Character = boyfriend;

			if(char != null)
			{
				char.playAnim(singAnims[direction] + "miss", true);
			}

			vocals.volume = 0;
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		}
	}

	var grazeAnims = ["LEFTgraze", "DOWNgraze", "UPgraze", "RIGHTgraze"];
	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			switch(note.noteType) {
				case 'RUMIA-Hurt 1' | 'RUMIA-Hurt 2-GREEN' | 'RUMIA-Hurt 2-BLUE' | 'RUMIA-Hurt 2-RED':
					if(cpuControlled) return;
					health -= 0.23;
					return;
				case "RUMIA-Bullet Note":
					boyfriend.playAnim(grazeAnims[Std.int(Math.abs(note.noteData)) % 4], true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound("graze"), 0.1);
				case "REIMU-Bullet Note":
					boyfriend.playAnim("dodge", true);
					boyfriend.specialAnim = true;
					camGame.shake(0.01, 0.2);
					REIMUorb.animation.play(Std.string(Std.int(Math.abs(note.noteData)) % 4));
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}

			if (note.noteData >= 0)
			{
				health += 0.023;
			}
			else
			{
				//what is this
				health += 0.004;
			}

			if(!note.noAnimation)
			{
				var char:Character = boyfriend;
				var daAlt = '';
				if(note.noteType == "Alt Animation") daAlt = '-alt';

				if(note.gfNote){ char = gf; }

				if(char != null)
				{
					if(!note.isSustainNote){
						cameraShit(singAnims[Std.int(Math.abs(note.noteData)) % 4], false);
					}
					char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + daAlt, true);
					char.holdTimer = 0;
				}

				if(note.noteType == "Hey") 
				{
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

			if (!note.isSustainNote)
			{
				if(cpuControlled) {
					boyfriend.holdTimer = 0;
				}
				note.kill();
				notes.remove(note, true);
				note.destroy();
			} else if(cpuControlled) {
				var targetHold:Float = Conductor.stepCrochet * 0.001 * boyfriend.singDuration;
				if(boyfriend.holdTimer + 0.2 > targetHold) {
					boyfriend.holdTimer = targetHold - 0.2;
				}
			}
			RecalculateRating();
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(note.noteType == 'Hey!' && boyfriend.animOffsets.exists('hey')) {
			boyfriend.playAnim('hey', true);
			boyfriend.specialAnim = true;
			boyfriend.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;

			if(note.gfNote) { char = gf; }

			if(char != null)
			{
				if(!note.isSustainNote){
					cameraShit(singAnims[Std.int(Math.abs(note.noteData)) % 4], true);
				}
				char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + altAnim, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	override function destroy() {
		super.destroy();
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
					//im lookin at this while doing the remake, still have no idea of waht this is lol, maybe opponent strums?
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

		if(curStage == "patrol")
		{
			switch(curStep)
			{
				case 696:
					dad.playAnim("shoot");
					dad.specialAnim = true;
					boyfriend.playAnim("dodge");
					boyfriend.specialAnim = true;
			}
		}

		lastStepHit = curStep;
	}

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
			}
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

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			//taken from the pe-0.4.2 android thingy
			if (ClientPrefs.iconBoping) {
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
				if(SONG.song.toLowerCase().replace(" ", "-") == "mystical-maiden")
				{
					if(curBeat % 2 == 0)
					{
						REIMUorb.animation.play("idle");
					}
				}
			//gotta work on this one
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

		lastBeatHit = curBeat;
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
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
		ratingPercent = songScore / ((songHits + songMisses) * 350);
		if(!Math.isNaN(ratingPercent) && ratingPercent < 0) ratingPercent = 0;

		if(Math.isNaN(ratingPercent)) {
			ratingString = 'N/A';
		} else if(ratingPercent >= 1) {
			ratingPercent = 1;
			ratingString = ratingStuff[ratingStuff.length-1][0];
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
	}

	//x doesnt seem to be working correctly dunno why
	var multY = 30;
	var multX = 60;
	function cameraShit(animToPlay, isDad)
	{
		if(ClientPrefs.cameraMovOnNoteP && curStage != "subway")
		{
			switch(animToPlay)
			{
				case 'singLEFT':
					camFollow.x = campointX - multX;
				case 'singDOWN':
					camFollow.y = campointY + multY;
				case 'singUP':
					camFollow.y = campointY - multY;
				case 'singRIGHT':
					camFollow.x = campointX + multX;
			}
		}
	}

	function onCreatePost()
	{
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
			case "entrance":
				warning = new FlxSprite(9999, 9999);
				warning.frames = Paths.getSparrowAtlas("RUMIA-warning");
				warning.animation.addByPrefix("warning", "warning", 25, true);
				warning.cameras = [camOther];
				warning.scale.set(0.50, 0.50);	
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
		//having issues with this lol
		died.start(dodgetime, timer -> ({
			if(dodged == false){
				health = 0;
				doDeathCheck();
			} else if(dodged == true){
				dodged = false;
			}
		}));
	}
}
