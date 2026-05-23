package;

import flixel.tweens.FlxTween;
import lime.app.Application;
import openfl.system.Capabilities;
import openfl.display.DisplayObject;
import openfl.Lib;
import flixel.FlxG;
import flixel.system.FlxSplash;
import openfl.display.Sprite; //for main ig
import openfl.display.StageScaleMode;
import flixel.FlxGame;
import openfl.events.Event;
import WallpaperState;
import classes.FPSCounter;
#if js
import js.Browser;
import js.html.FontFace;
#end

/**
 * Command-line argument modes for the executable, which controls what GUI elements are shown.
 * 
 * **Flags:**
 * ```haxe
 * // Wallpaper-specific
 * if (Main.mode == Wallpaper) {fullGUIRender(elements);} // Interactive UI goes here
 * // Screen-saver specific
 * if (Main.mode == ScreenSaver) {limitedRender(elements);} // Only HUD elements go here
 * ```
 */
enum Args {
	/**
	* **Wallpaper context for rendering interactive elements.**
	*/
	Wallpaper;
	/**
	* **Screen saver context for general elements.**
	*/
	ScreenSaver;
}
class Main extends Sprite {
	/**
		Window initialization settings for FlxGame, derived from Psych Engine.

		**Note:** The `APP` runs on your current screen resolution to ensure that
		the wallpaper is properly scaled in Lively Wallpaper. *Please do not change*
		*system screen resolution while the app is running; this may cause scaling issues.*
	**/
    var state = {
		width: Std.int(Capabilities?.screenResolutionX) ?? 1280, // WINDOW width
		height: Std.int(Capabilities?.screenResolutionY) ?? 720, // WINDOW height
		initialState: WallpaperState, // starting state
		zoom: 1.0, // game state bounds, SET TO -1 FOR CALCULATIONS
		framerate: 60,
		skipSplash: false, // Flixel splash
		startFullscreen: false
	};
	/**App context for object rendering optimization.*/
	public static var mode:Args = Wallpaper;

	private static var mainInstance:DisplayObject;

	// Dimension initialization since Capabilities can't read them directly on opening.
	public static var screenX:Float;
	public static var screenY:Float;
    
    public static function main():Void
	{
		mainInstance = Lib.current.addChild(new Main());
	}

	public function new() {
        super();

        FlxSplash.creditOverride(Context.Wallpaper);
        if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(?E:Event):Void {
        if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
    }
    private function setupGame() {
		#if js
		var font = new FontFace("PhantomMuff 1.5", "url('bulkAssets/PhantomMuff.ttf')");
        font.load();
		#end
		Preload();
		
        var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		screenX = Capabilities.screenResolutionX;
		screenY = Capabilities.screenResolutionY;

		if (state.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / state.width;
			var ratioY:Float = stageHeight / state.height;
			state.zoom = Math.min(ratioX, ratioY);
			state.width = Math.ceil(stageWidth / state.zoom);
			state.height = Math.ceil(stageHeight / state.zoom);
		}
        addChild(new FlxGame(state.width, state.height, state.initialState, #if (flixel < "5.0.0") state.zoom, #end state.framerate, state.framerate, state.skipSplash, state.startFullscreen));
		addChild(new FPSCounter(5, 5, 0xffffff));
		FlxG.autoPause = false; // DO NOT TOUCH THIS, IT'S A WALLPAPER FOR A REASON.
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		//sqirra-rng crash handler stuff, really neat cuz wtf is happening here in my code jhvbdflhjk
			Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR, dies);

		// shader coords fix from psych, APPARENTLY NEEDED
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
		#if js Browser.window.console.log("%%%%% Post-setup %%%%%\n"); #end
    }
	private function Preload() {
		FlxG.save.bind("WallpaperConfig");
		WallpaperState.loadConfig(FlxG.save);
		// Tweak this for user experience and closing animation shi, idk this is meant to only be a bg element :P
		Lib.application.window.onClose.add(() -> {
			Lib.application.window.onClose.cancel();
			Sys.println("Closing window..");
			FlxG.save.close();
			FlxTween.tween(Lib.application.window, {y: 1500, width: 50, height: 50}, 1.1, {ease: flixel.tweens.FlxEase.circIn, onStart: (_) -> FlxG.sound.play("bulkAssets/ToggleJingle.ogg"), onComplete: (_) -> Sys.exit(0)});
		});
	}
	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static function dies(?e:openfl.events.UncaughtErrorEvent) {
		var callStack:Array<haxe.CallStack.StackItem> = haxe.CallStack.exceptionStack(true);
		var eee:String = "Oops. I fumbled.\n----------\n";
		eee += "\n==⚠️ CRASH REASON: ⚠️==\n" + haxe.CallStack.toString(callStack).replace("Called from", "@ ");
		Sys.println(eee);
		FlxG.sound.play("bulkAssets/error.wav");
		Application.current.window.alert(eee, "please yell at me  -PotateX2");
		Sys.exit(1);
	}
}