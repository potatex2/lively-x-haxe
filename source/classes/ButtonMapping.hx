package classes;

import openfl.filesystem.File;
import openfl.desktop.NativeProcessStartupInfo;
import openfl.desktop.NativeProcess;
import openfl.system.Capabilities;
import haxe.exceptions.ArgumentException;
import sys.FileSystem;
import haxe.Exception;
import haxe.ValueException;
import flixel.tweens.FlxEase;
import sys.io.Process;
import classes.FlxDynamics.FlxAnimButton;
import flixel.tweens.FlxTween;
import haxe.Json;

typedef ButtonProperties = {
    var x:Int;
    var y:Int;

    /** Graphic path in the `bulkAssets/buttons` folder; extension included. */
    var label:String;

    /** Tooltip text (text that shows when hovering over button). */
    var tooltip:String;

    /**
        CLI commands and/or executable to run. *Note: Only one can be executed for now.*
        
        _For environment variables, **the same format as Command Prompt should be used:**_ [ `%VAR_NAME%` ].
    **/
    var target:String;

    /** Working directory where the target file should be run through. (causes issues with Lime projects...) */
    var runIn:String;

    /** Offset by `x` from the right? */
    var fromRight:Bool;

    /** Offset by `y` from the bottom? */
    var fromBottom:Bool;

    /** __Optional__ - tooltip color in _hexadecimal_ format (e.g. `0xFFFFFF`). */
    @:optional var tooltipColor:String;

    /** __Optional__ - button size (might make this a FlxPoint) */
    @:optional var scale:Int;

    /** __Optional__ - Convenience flag for OneDrive paths. (personal feature tbh) */
    @:optional var inOneDrive:Bool;

    // Possible feature: Set custom sound with default as ToggleJingle.ogg
}

class ButtonMapping {
    public static var ButtonArray:Array<FlxAnimButton> = [];
    static var ErrorIndices:Map<Int, String> = [];
    public static function createButtons() {
        final path:String = "bulkAssets/buttons/config.json";
        var buttonList:Array<ButtonProperties> = Json.parse(Assets.getText(path)).buttons;
        for (button in buttonList) {
            var buttonToAdd:FlxAnimButton = new FlxAnimButton(button.label, 0, 0, 'bulkAssets/buttons/${button.label}');
            buttonToAdd.init_X = button.fromRight ? Capabilities.screenResolutionX - button.x : button.x;
            buttonToAdd.init_Y = button.fromBottom ? Capabilities.screenResolutionY - button.y : button.y;
            if (button.scale != null && button.scale is Int)
                buttonToAdd.scale.set(button.scale, button.scale);
            
            var ifEnv:String = CheckForEnv(button.runIn, buttonList.indexOf(button));
            if (ifEnv == null) continue; // skip making button callbacks and adding.

            buttonToAdd.setCallbacks(
                () -> {
                    FlxTween.cancelTweensOf(buttonToAdd);
                    WallpaperState.toggle.soundCheck("ToggleJingle.ogg");
                    buttonToAdd.scale.x = button.scale;
                    buttonToAdd.scale.y = button.scale;
                    //Note: Command flags are not properly parsed for this; fix soon
                    // Idea: Buttons for selecction group (i.e. based off of FNF mod folders)
                    var args = new NativeProcessStartupInfo();
                    args.executable = new File(ifEnv + "/" + button.target); //placeholder index for one; iterate over object arguments in this block soon.
                    args.workingDirectory = new File(ifEnv);
                    var exec:NativeProcess = new NativeProcess();
                    try exec.start(args) catch(no) throw no;
                },
                () -> {
                    FlxTween.cancelTweensOf(buttonToAdd);
                    WallpaperState.toggle.soundCheck("clickIn.ogg");
                    buttonToAdd.scale.x -= 0.2;
                    buttonToAdd.scale.y -= 0.2;
                },
                () -> {
                    FlxTween.cancelTweensOf(buttonToAdd, ["scale.x", "scale.y"]);
                    FlxTween.tween(buttonToAdd, {"scale.x": 0.7, "scale.y": 0.7, y: buttonToAdd.y - 10}, 0.5, {ease: FlxEase.circOut});
                    WallpaperState.changeText(button.tooltip, flixel.util.FlxColor.fromString(button.tooltipColor));
                },
                () -> {
                    inline WallpaperState.resetSelection();
                    FlxTween.cancelTweensOf(buttonToAdd, ["scale.x", "scale.y"]);
                    FlxTween.tween(buttonToAdd, {"scale.x": 0.6, "scale.y": 0.6, y: buttonToAdd.init_Y}, 0.5, {ease: FlxEase.circOut});
                }
            );
            ButtonArray.push(buttonToAdd);
        }
        if (Lambda.count(ErrorIndices) > 0) throw 'JSON | Could not open or run target at ${Lambda.count(ErrorIndices) > 1 ? "buttons: " + ErrorIndices : "button #" + (ErrorIndices)}; check the file path(s).';

        trace(ButtonArray);
        for (btn in ButtonArray) {
            WallpaperState.instance.add(btn);
            btn.cameras = [WallpaperState.camGUI];
        }
    } 
    static function CheckForEnv(cmdPath:String, index:Int):String {
        // To-do: In case of there being more than one argument (which there shouldn't be, really...) set an array for multiple occurrences.
        final envReg:EReg = ~/%([0-9a-zA-Z_(-)]+)%/giu;
        final cdReg:EReg = ~/^(cd )/gi;
        final extReg:EReg = ~/exe|txt|lnk/gi; //hardcoded for now
        var cwd:String = Sys.getCwd();
        var formattedArgs:Array<String> = [];
        if (envReg.match(cmdPath)) {
            var parsedEnv:Null<String> = envReg.matched(1); // Check To-do
            parsedEnv = Sys.getEnv(parsedEnv).replace("\\","/");
            trace("** Env Variable detected: " + parsedEnv);
            if (parsedEnv == null || parsedEnv == "") {
                Sys.println('     !!! BUTTON ${index+1} ERROR. Environment variable specified does not exist or have a value!');
                ErrorIndices.set(index + 1, "InvalidEnvError");
                return null;
            }
            
            cmdPath = envReg.replace(cmdPath, parsedEnv);
            trace(cmdPath); // TO-DO: FIX ALL LOGIC FOR DIRECTORIES BEFORE FILES.
            if (cdReg.match(cmdPath)) {
                formattedArgs.push("cmd /k ");
                cwd = cmdPath.substr(3);
                cmdPath = cmdPath.substr(3);
            }
            if (FileSystem.exists(cwd + "/" + cmdPath) || FileSystem.exists(cmdPath) ) {
                trace('Button ${index+1} successfully parsed. Target: $cmdPath');
                return cmdPath;
            }
            else {
                Sys.println('     !!! BUTTON ${index+1} ERROR. Target: $cmdPath');
                ErrorIndices.set(index + 1, "NullPathError");
                return null;
            }            
        }
        return null;
    }
    
}