import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import classes.ButtonMapping;
import flixel.ui.FlxButton;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxStringUtil;
import openfl.text.TextField;
import openfl.system.Capabilities;
import openfl.events.Event;
import lime.app.Application;
import haxe.Json; // parser
import hscript.Interp;
#if html5
import js.Browser;
#elseif sys
import sys.io.Process;
import sys.FileSystem;
#end
import flixel.FlxState;
import flixel.FlxSprite as Img;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.FlxCamera as HUD;
import flixel.math.FlxMath;
import classes.Bar;
import classes.FlxDynamics;
import flixel.tweens.*;
import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop as BG;
#if cpp
@:cppFileCode('#include <windows.h>')
// Might work in conjunction with winuser.h in the future.
#end
/**
 * **The bulk of what's rendered on your screen (or window, if you're testing or debugging).**
 * 
 * All elements that will be rendered must be placed here through `add()`
*/
class WallpaperState extends FlxState {
    /**
    * **The directory where all the assets are jumbled up.**
    *     
    * _I know, I know, not a good practice... this is a hyperfixation, alright?_
    */
    public var RootDirectory:String = "bulkAssets/";

    /**
    * **You know I had to do a self-insert for this. :3**
    * 
    * _Placeholder image that bops to the music beat (independent of `camHUD`)._
    */
    var bopper:Img;
    /**
     * Camera instance for anything that will bop to the music playing.
     */
    public static var camHUD:HUD;
    var bgGoofy:BG;
    static var transition:BG;
    static var transitionSprite:FlxSprite;
    private var lastFrame:Int = -1;

    /**
     * Camera instance for buttons added. (and another thing that i forgot)
     */
    public static var camGUI:HUD;

    // ⬇️ Windows-exclusive for interactivity ⬇️
    #if cpp
    /**
        Top group for GUI, or what you'd consider the "header".    
    */
    public static var TopGroup:FlxSpriteGroup = new FlxSpriteGroup(0, -100);
    public static final TopPos = 5;
    /**
        Bottom group for GUI, or what you'd consider the "footer".    
    */
    //init on create()
    public static var BottomGroup:FlxTypedSpriteGroup<FlxAnimButton>; 
    public static var BottomPos:Float;
    #end

    var startBop:Bool = false;
    public static var jason:Float;
    public static var croshet:Float;
    var realTime:FlxText;
    var musicProg:Bar;
    var mute:FlxGroupButton;
    var bopPrefs:Bool = true;
    static var afkTime:Int = 0;

    // Windows
    /**
        Set as TextField to ensure there are no fragments or whatever it's called for resolution.
        
        Still has the resizing bs, but hey, it's still a better optimization than FlxText rendering...
    */
    // *** NTS: Make buttons dynamic through user-created files and the Reflect class.
    static var selectedLink:TextField;
    public static var flaxhixele:FlxText;
    static var shutdownWarn:Img;
    static var shutDown:FlxAnimButton;
    static var tabBackIn:FlxAnimButton;


    static var updateNote:FlxAnimButton;
    static var afkNote:TextField;
    static var silly:FlxText;
    static var ticktock:haxe.Timer;

    // Both
    public static var Selection:String;
    static var Note:String;

    public static var instance:WallpaperState;
    public var configButton:FlxAnimButton;

    // Load config preferences before wallpaper application runs with default values.
    public static function loadConfig(save:flixel.util.FlxSave) {
        if (save.data.selected == null) { //Fallback for music
            var musicList:Array<String> = FileSystem.readDirectory("bulkAssets/music");
            var i:Int = 0;
            while (i <= musicList.length - 1) {
                if (i > musicList.length - 1) throw "WallpaperState | No music files were found, please add a file for fallback!";
                var fileName:Array<String> = musicList[i].split(".");
                if (fileName[1] == "ogg" || fileName[1] == "mp3" || fileName[1] == "wav") {
                    Selection = fileName[0];
                    save.data.selected = Selection;
                    Sys.println("        \x1b[1;33mloadConfig | \x1b[0;43m Fallback set to: " + Selection + "\x1b[0m");
                    break;   
                }
                i++;
            }
        }
        save.data.fish = "fosj.";
        save.flush();

        Selection = save.data.selected;
        Sys.println("$$$$$ SAVE DATA: " + save.data);
    }
    static function Preload() {
        var soundList:Array<String> = [];
        for (file in FileSystem.readDirectory("bulkAssets/sound")) {
            //FlxG.sound.cache('bulkAssets/sound/$file');
            // this causes an error with the errors in the build obj files...
            var test = new FlxSound().loadEmbedded('bulkAssets/sound/$file');
            FlxG.sound.list.add(test);
        }
    }

    override function create() {
        Preload();
        // For substate use
        instance = this;

        #if sys
        BottomGroup = new FlxTypedSpriteGroup<FlxAnimButton>(0, Main.screenY);
        BottomPos = Main.screenY - 125;
        Application.current.window.y += 10;
        #end

        super.create();
        Application.current.window.focus();

        //FlxG.camera.bgColor = Json.parse(Assets.getText('bulkAssets/config.json')).backend.bgColor;
        //no effect, looking into it soon.

		bgGoofy = new BG(RootDirectory + "bgGoofy.png"); 
		bgGoofy.updateHitbox(); 
		bgGoofy.alpha = 1; 
		bgGoofy.screenCenter(X); 
		add(bgGoofy);
        bgGoofy.alpha = 0;
        bgGoofy.angle = 45/2;
        bgGoofy.velocity.set(50, 25); // Yes it does, Flixel. Yes. It. Does.
        FlxTween.tween(bgGoofy, {alpha: 0.25}, 1.4, {ease: FlxEase.quartInOut});

        FlxG.sound.music = new FlxSound().loadEmbedded('bulkAssets/music/$Selection.ogg', true).play();
        FlxG.sound.music.volume = 0;
        FlxTween.tween(FlxG.sound.music, {volume: 1}, 2);

        camHUD = new HUD();
        FlxG.cameras.add(camHUD, false);
        camHUD.bgColor.alpha = 0; // Yes. It. Does.

        camGUI = new HUD();
        FlxG.cameras.add(camGUI, false);
        camGUI.bgColor.alpha = 0; // Yes. It. Does.

        //Apparently loadGraphic() can't properly process subtexture atlases, sooo FlxAtlasFrames it is.
        var atlasFrames:Dynamic = FlxAtlasFrames.fromSparrow("bulkAssets/transition.png", "bulkAssets/transition.xml");
        transitionSprite = new FlxSprite();
        transitionSprite.setFrames(atlasFrames, true);
        add(transitionSprite);
        transitionSprite.useFramePixels = true;
        transitionSprite.animation.addByPrefix("fade", "fadeTrans", 9, false);
        transitionSprite.animation.play("fade", true);
        
        transition = new BG();
        add(transition);
        updateBackdropFrame();

        bopper = new Img(FlxG.width + 200, FlxG.height / 2).loadGraphic(RootDirectory + "bozo.png");
        bopper.y = FlxG.height / 2 - bopper.height/2;
        bopper.alpha = 0;
        add(bopper);
        //bopper.cameras = [camHUD];

        // target stuff...
        var TargetWidth:Float = jsOrWin(FlxG.width /2, FlxG.width - 10);
        var TargetHeight:Float = jsOrWin(FlxG.height * 0.7, FlxG.height - 22);
        var TargetAlignment:String = jsOrWin("center", "right");
        var TargetSize:Int = jsOrWin(25, 15);
        realTime = new FlxText(TargetWidth, TargetHeight, 400, "Current Time: ", 25);
        realTime.alignment = TargetAlignment;
        realTime.x -= realTime.fieldWidth #if js / 2 #end;
        realTime.alpha = 1e-3;
        realTime.setFormat("PhantomMuff 1.5", TargetSize, 0xff8aff86, TargetAlignment);
        add(realTime);
        realTime.cameras = [camHUD];
        FlxTween.tween(realTime, {alpha: 1}, 1.4, {ease: FlxEase.sineInOut});

        ticktock = new haxe.Timer(1000);

        configButton = new FlxAnimButton("TestState", 0, 50, "bulkAssets/Settings.png", () -> if (FlxG.state.subState == null && configButton.visible) openSubState(new SettingsSubState()));
        configButton.x = Capabilities.screenResolutionX - configButton.width - 50;
        add(configButton);
        configButton.cameras = [camHUD];
        #if js
        RunAFK();

        var afkNote = new FlxText(FlxG.width / 2, FlxG.height * 0.3, 600, "Note: " + Note, 20);
        afkNote.alpha = 0.001;
        afkNote.setFormat("PhantomMuff 1.5", 20, 0x98ffd381, "center");
        afkNote.x -= afkNote.fieldWidth / 2;
        add(afkNote);
        afkNote.cameras = [camHUD];
        FlxTween.tween(afkNote, {alpha: 1}, 1.4, {ease: FlxEase.sineInOut});
        #end

        silly = new FlxText(FlxG.width /2, jsOrWin(realTime.y + 60, FlxG.height * 0.6), 400, "Time since AFK: ", 20);
        silly.alignment = "center";
        silly.x -= silly.fieldWidth / 2;
        silly.alpha = 0.001;
        silly.setFormat("PhantomMuff 1.5", 20, 0xff00ade2, "center");
        add(silly);
        silly.cameras = [camHUD];
        FlxTween.tween(silly, {alpha: 1}, 1.4, {ease: FlxEase.sineInOut});

        flaxhixele = new FlxText(5, FlxG.height - 30, 600, 'Custom-made in HaxeFlixel; music selected: "$Selection"', 15);
        flaxhixele.alignment = "left";
        flaxhixele.alpha = 0.001;
        flaxhixele.setFormat("PhantomMuff 1.5", 15, 0xffffa600, "left");
        add(flaxhixele);
        flaxhixele.cameras = [camHUD];
        FlxTween.tween(flaxhixele, {alpha: 0.25}, 1.4, {ease: FlxEase.circInOut, type: flixel.tweens.FlxTween.FlxTweenType.PINGPONG});
        /*
        musicProg = new Bar(0, FlxG.height - 18, "musicBar", function() return pause.time / pause.length);
        musicProg.alpha = 0;
        add(musicProg);
        FlxTween.tween(musicProg, {alpha: 0.7}, 1.4, {ease: FlxEase.sineInOut});
        */
        jason = Json.parse(Assets.getText('bulkAssets/music/$Selection.json')).music.bpm;
        Sys.println("   $$$$$ Data BPM: " + jason);
        croshet = FlxMath.roundDecimal(60 / jason, 4);
        FlxTween.tween(bopper, {alpha: 1, x: FlxG.width/2 - bopper.width/2}, 1.7, {ease: FlxEase.sineOut, onComplete: (_) -> startBop = true});
        bopper.angle = 10;
        FlxTween.tween(bopper, {angle: -10}, 1.5, {ease: FlxEase.sineInOut, type: 4});
        /*
        mute = new FlxGroupButton("music", musicProg.barWidth + 30, FlxG.height - 30, new FlxAnimButton(
            "toggleMusic", 0, 0, "bulkAssets/musicIcon.png", null
        ), true);
        FlxGroupButton.get("music").addElement(new FlxTagSprite("muted", 5, 6).loadGraphic("bulkAssets/nO.png"));
        var musicMute = FlxAnimButton.get("toggleMusic");
        var muteGroup = FlxGroupButton.get("music");
        muteGroup.x = musicProg.barWidth + 30;
        muteGroup.y = FlxG.height - 60;
        musicMute.setCallbacks(
            () -> {
                musicMute.scale.x = 1;
                musicMute.scale.y = 1;
                toggle.soundCheck("clickOut.ogg");
                if (FlxGroupButton.get("music").toggleState) {
                    pause.pause();
                    FlxTagSprite.get("muted").visible = true;
                    bopPrefs = false;
                } else {
                    pause.play();
                    FlxTagSprite.get("muted").visible = false;
                    bopPrefs = true;
                }
                FlxGroupButton.get("music").toggleState = !FlxGroupButton.get("music").toggleState;
            },
            () -> {
                musicMute.scale.x -= 0.2;
                musicMute.scale.y -= 0.2;
                toggle.soundCheck("clickIn.ogg");
            }
        );
        FlxTagSprite.get("muted").visible = false;
        add(mute);
        mute.alpha = 0;
        FlxTween.tween(mute, {alpha: 0.7}, 1.4, {ease: FlxEase.sineInOut});
        */

        // Windows-based elements only.
        #if sys
        FlxG.mouse.useSystemCursor = true;

        updateNote = new FlxAnimButton("Update AFK", FlxG.width / 4, 0, "bulkAssets/reload.png");
        updateNote.init_X = FlxG.width / 2 - updateNote.width / 2;
        //updateNote.init_Y = -65;
        TopGroup.add(updateNote);
        updateNote.setCallbacks(
            () -> {
                FlxTween.cancelTweensOf(updateNote);
                FlxG.sound.play("sound/clickOut.ogg");
                var hasOneDrive:Bool = FileSystem.exists(Sys.getEnv("ONEDRIVECONSUMER") + '\\Desktop\\AFKNote.px2');
                afkNote.text = Json.parse(sys.io.File.getContent(Sys.getEnv(hasOneDrive ? "ONEDRIVECONSUMER" : "USERPROFILE") + '\\Desktop\\AFKNote.px2')).afkNote;
                updateNote.scale.x = 1;
                updateNote.scale.y = 1;
            },
            () -> {
                FlxTween.cancelTweensOf(updateNote);
                FlxG.sound.play("bulkAssets/sound/clickIn.ogg");
                updateNote.scale.x -= 0.2;
                updateNote.scale.y -= 0.2;
            },
            () -> {
                FlxTween.cancelTweensOf(updateNote, ["scale.x", "scale.y"]);
                FlxTween.tween(updateNote, {"scale.x": 0.9, "scale.y": 0.9, y: updateNote.y - 10}, 0.5, {ease: FlxEase.circOut});
            },
            () -> {
                FlxTween.cancelTweensOf(updateNote, ["scale.x", "scale.y"]);
                FlxTween.tween(updateNote, {"scale.x": 0.8, "scale.y": 0.8, y: updateNote.init_Y}, 0.5, {ease: FlxEase.circOut});
            }
        );
        afkNote = new openfl.text.TextField();
		afkNote.x = Capabilities.screenResolutionX / 2 - afkNote.width / 2;
		afkNote.y = Capabilities.screenResolutionY / 2 + 60;
        
		afkNote.selectable = false;
        afkNote.type = openfl.text.TextFieldType.DYNAMIC;
		afkNote.defaultTextFormat = new openfl.text.TextFormat("PhantomMuff 1.5", 22, 0xff00ff2a, false, false, false, null, null, "center");
		afkNote.autoSize = CENTER;
		afkNote.multiline = true;
		afkNote.text = "lorem ipsum";
        openfl.Lib.current.addChild(afkNote);

        shutdownWarn = new Img().loadGraphic("bulkAssets/warning.png");
        shutdownWarn.screenCenter();
        add(shutdownWarn);
        shutdownWarn.alpha = 0;

        //Button links
        selectedLink = new openfl.text.TextField();

		selectedLink.selectable = false;
		selectedLink.mouseEnabled = false;
		selectedLink.defaultTextFormat = new openfl.text.TextFormat("PhantomMuff 1.5", 22, 0xff00ff2a, false, false, false, null, null, CENTER);
		selectedLink.autoSize = CENTER;
		selectedLink.multiline = true;
		selectedLink.text = "...";
        openfl.Lib.current.addChild(selectedLink);

        shutDown = new FlxAnimButton("Shutdown", 0, 0, "bulkAssets/shutdown.png");
        shutDown.scale.x = 0.7;
        shutDown.scale.y = 0.7;
        shutDown.init_X = FlxG.width - shutDown.width / 2 - 100;
        //shutDown.init_Y = FlxG.height - shutDown.height - 10;
        BottomGroup.add(shutDown);
        var safety:Int = 0;
        var time = new FlxTimer();
        time.onComplete = (_) -> safety = 0;
        shutDown.setCallbacks(
            () -> {
                shutDown.scale.x = 0.7;
                shutDown.scale.y = 0.7;
                FlxTween.cancelTweensOf(shutdownWarn);
                shutdownWarn.alpha = 1;
                FlxTween.tween(shutdownWarn, {alpha: 0}, 1, {ease: FlxEase.expoOut});
                // WARNING!!
                time.reset(1);
                FlxTween.cancelTweensOf(shutDown);
                safety++;
                FlxG.sound.play('bulkAssets/sound/shutdown$safety.ogg', 0.7);
                if (safety == 3)
                    Type.createInstance(Process, ["shutdown /p"]);
            },
            () -> {
                FlxTween.cancelTweensOf(shutDown);
                FlxG.sound.play("bulkAssets/sound/clickIn.ogg");
                shutDown.scale.x -= 0.2;
                shutDown.scale.y -= 0.2;
            },
            () -> {
                FlxTween.cancelTweensOf(shutDown, ["scale.x", "scale.y"]);
                FlxTween.tween(shutDown, {"scale.x": 0.8, "scale.y": 0.8, y: shutDown.y - 10}, 0.5, {ease: FlxEase.circOut});
                changeText("Shutdown PC", 0xff0000);
            },
            () -> {
                inline resetSelection();
                FlxTween.cancelTweensOf(shutDown, ["scale.x", "scale.y"]);
                FlxTween.tween(shutDown, {"scale.x": 0.7, "scale.y": 0.7, y: BottomPos}, 0.5, {ease: FlxEase.circOut});
            }
        );
        tabBackIn = new FlxAnimButton("TabIn", 0, 0, "bulkAssets/tabBackIn.png");
        tabBackIn.init_X = FlxG.width / 2 - tabBackIn.width / 2;
        tabBackIn.init_Y = tabBackIn.height;
        tabBackIn.setCallbacks(
            () -> {
                onTabIn();
                for (btn in BottomGroup)
                    btn.cd = false;
            },
            () -> {
                FlxTween.cancelTweensOf(tabBackIn);
                FlxG.sound.play("bulkAssets/sound/clickIn.ogg");
                tabBackIn.scale.x -= 0.2;
                tabBackIn.scale.y -= 0.2;
            },
            () -> {
                FlxTween.cancelTweensOf(tabBackIn, ["scale.x", "scale.y"]);
                FlxTween.tween(tabBackIn, {"scale.x": 0.9, "scale.y": 0.9}, 0.5, {ease: FlxEase.circOut});
            },
            () -> {
                FlxTween.cancelTweensOf(tabBackIn, ["scale.x", "scale.y"]);
                FlxTween.tween(tabBackIn, {"scale.x": 0.8, "scale.y": 0.8}, 0.5, {ease: FlxEase.circOut});
            }
        );
        add(tabBackIn);

        add(TopGroup);
        add(BottomGroup);

        classes.WindowsTransparency.enableTransparency();
        #end
        ButtonMapping.createButtons();
    }

    static function RunAFK() {
        #if sys afkTime = 0; #end
        ticktock = new haxe.Timer(1000);
        ticktock.run = () -> {
            afkTime++;
            silly.text = "Time since AFK: " + FlxStringUtil.formatTime(afkTime);
        }
    }

    #if sys
    inline public static function resetSelection() {
        changeText("", 0x00ff2a);
    }
    inline public static function changeText(text:String, ?color:Int) {
        selectedLink.text = text;
        selectedLink.textColor = color != null ? color : 0x00ff2a;
    }

    // Focus Handlers
    public static function onTabOut(e:Event) {
        FlxTween.completeTweensOf(TopGroup);
        FlxTween.completeTweensOf(BottomGroup);
        FlxTween.completeTweensOf(tabBackIn);
        FlxTween.completeTweensOf(camGUI);
        FlxTween.tween(TopGroup, {y: -80, alpha: 0}, 0.7, {ease: FlxEase.elasticInOut, onUpdate: (_) -> updateBackdropFrame()});
        FlxTween.tween(BottomGroup, {y: BottomPos, alpha: 1}, 0.7, {ease: FlxEase.sineOut});
        FlxTween.tween(tabBackIn, {y: tabBackIn.init_Y, alpha: 1}, 0.7, {ease: FlxEase.sineOut});
        FlxTween.tween(camGUI, {alpha: 1}, 0.3, {ease: FlxEase.quintInOut, startDelay: 0.15, onStart: (_) -> for (btn in ButtonMapping.ButtonArray) btn.visible = true});
        FlxTween.tween(camGUI, {y: 0}, 0.4, {ease: FlxEase.sineOut});
        
        RunAFK();
        silly.visible = true;
        tabbedOut = true;
        flaxhixele.visible = true;
        afkNote.visible = true;
        transitionSprite.animation.play("fade", true, false);
    }
    public static function onTabIn() {
        FlxTween.completeTweensOf(TopGroup);
        FlxTween.completeTweensOf(BottomGroup);
        FlxTween.completeTweensOf(tabBackIn);
        FlxTween.completeTweensOf(camGUI);
        FlxTween.tween(TopGroup, {y: TopPos, alpha: 1}, 0.7, {ease: FlxEase.sineOut, onUpdate: (_) -> updateBackdropFrame()});
        FlxTween.tween(BottomGroup, {y: BottomPos + 200, alpha: 0}, 0.7, {ease: FlxEase.elasticInOut});        
        FlxTween.tween(tabBackIn, {y: -250, alpha: 0}, 0.7, {ease: FlxEase.sineOut});
        FlxTween.tween(camGUI, {alpha: 0}, 0.2, {ease: FlxEase.quintIn, onComplete: (_) -> for (btn in ButtonMapping.ButtonArray) btn.visible = false});
        FlxTween.tween(camGUI, {y: 200}, 0.3, {ease: FlxEase.quintIn});

        silly.visible = false;
        tabbedOut = false;
        flaxhixele.visible = false;
        afkNote.visible = false;
        ticktock.stop();
        moveMouse(Capabilities.screenResolutionX / 2, Capabilities.screenResolutionY / 2);
        transitionSprite.animation.play("fade", true, true);
    }
    static function moveMouse(x:Float, y:Float) {
        untyped __cpp__("
            SetCursorPos(x, y);
        ");
    }
    // Focus Handlers end
    #end

    var boopWay:Bool = true;
    var delayy:Bool = false;
    var camBeat:Int;
    var secondsTotal:Float;

    var timestuff:String;
    var aawur:Int;
    var AmPm:String;
    var Hour12:Int;
    static var tabbedOut:Bool = false;
    override function update(elapsed:Float) {
        // Testing scroll event handler for vol
        if (FlxG.mouse.wheel > 0 && FlxG.sound.music.volume < 1) {
            FlxG.sound.music.volume += 0.05;
            FlxG.sound.play("bulkAssets/sound/beep.ogg");
        } else if (FlxG.mouse.wheel < 0 && FlxG.sound.music.volume > 0) {
            FlxG.sound.music.volume -= 0.05;
            FlxG.sound.play("bulkAssets/sound/beep.ogg");
        }
        // Moved it out here since I don't know where to go with the button arrangements
        selectedLink.x = FlxG.mouse.getPosition().x;
        selectedLink.y = FlxG.mouse.getPosition().y - 75;
        if (!tabbedOut) {
            if (FlxG.mouse.getPosition().y >= FlxG.height - 3) {
                onTabOut(null);
                for (btn in BottomGroup)
                    btn.cd = true;
            }
        } else {
            silly.y = FlxG.height * 0.6 + afkNote.height;
        }
        secondsTotal = FlxMath.roundDecimal(FlxG.sound.music.time / 1000, 4);
        if (secondsTotal % croshet >= 0 && secondsTotal % croshet <= 0.03 && bopPrefs) {
            if (!delayy) {
                if (startBop) {
                    FlxTween.completeTweensOf(bopper);
                    camBeat++;
                    if (camBeat % 2 == 0) {
                        camHUD.zoom = 1.01;
                        FlxTween.tween(camHUD, {zoom: 1}, croshet*1.02, {ease: FlxEase.sineOut});
                        if (FlxG.random.bool(2))
                            bopper.loadGraphic("bulkAssets/heh.png");
                        else bopper.loadGraphic("bulkAssets/bozo.png");
                    }
                    FlxTween.tween(bopper, {y: bopper.y - 7}, croshet / 2.04, {ease: FlxEase.expoOut, onComplete: (_) -> {
                        FlxTween.tween(bopper, {y: FlxG.height / 2 - bopper.height/2}, croshet / 2.05, {ease: FlxEase.sineIn});
                    }});
                }
                boopWay = !boopWay;
                bopper.scale.set(0.9,0.9); //YES. IT. DOES.
                FlxTween.tween(bopper.scale, {x: 0.75, y: 0.75}, croshet/1.5, {ease: FlxEase.quadOut});
                delayy = true;
                new FlxTimer().start(croshet/4, (_) -> delayy = false);
            }
        }
            timestuff = Date.now().toString();
            aawur = Std.parseInt(timestuff.substring(timestuff.substring(11,12) == "0" ? 12 : 11, 13));
            AmPm = (aawur <= 11 ? " AM" : " PM");
            Hour12 = ((aawur == 0 || aawur == 12) ? 12 : Std.parseInt(timestuff.substring(11,13)) % 12);
            realTime.text = "Current Time: " + Hour12 + timestuff.substr(13) + AmPm #if js + " MST" #end;
        super.update(elapsed);
        for (cb in updateArray) cb();

        transitionSprite.update(elapsed);
        var cur:Int;
        if (transitionSprite.animation.curAnim != null) {
            cur = transitionSprite.animation.curAnim.curFrame;
            if (cur != lastFrame) {
                lastFrame = cur;
            }
        }
    }

    static var updateArray:Array<haxe.Constraints.Function> = [];
    public static inline function bindToUpdate(callback:haxe.Constraints.Function) {
        updateArray.push((?args) -> callback(args));
    }

    static function updateBackdropFrame() {
        if (transitionSprite.framePixels != null) {
            var bmp:BitmapData = transitionSprite.framePixels.clone();
            var graphic = FlxGraphic.fromBitmapData(bmp);
            transition.loadGraphic(graphic, false, transitionSprite.frameWidth, transitionSprite.frameHeight);
        }
    }
}

inline function jsOrWin(jsVal:Dynamic, winVal:Dynamic):Dynamic {
    return #if js jsVal #elseif cpp winVal #end;
}