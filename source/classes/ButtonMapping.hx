package classes;

import openfl.events.NativeProcessExitEvent;
import classes.psych.Discord.DiscordClient;
import WallpaperState;
import openfl.events.Event;
import lime.app.Application;
import haxe.io.BytesData;
import openfl.events.ProgressEvent;
import openfl.Vector;
import openfl.filesystem.File;
import openfl.desktop.NativeProcessStartupInfo;
import openfl.desktop.NativeProcess;
import openfl.system.Capabilities;
import sys.FileSystem;
import haxe.Exception;
import flixel.tweens.FlxEase;
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

    /** __Optional__ - other command-line arguments. */
    @:optional var args:String;

    /** __Optional__ - tooltip color in _hexadecimal_ format (e.g. `0xFFFFFF`). */
    @:optional var tooltipColor:String;

    /** __Optional__ - button size. */
    @:optional var scale:Int;

    /** __Highly optional__ - Discord RPC properties on button click (reverts when target is closed).*/
    @:optional var RPC:RpcSettings;
    // Possible feature: Set custom sound with default as ToggleJingle.ogg
}
private typedef RpcSettings = {
    ?details:String,
    ?state:Null<String>,
    ?smallImageKey:Null<String>,
    ?hasStartTimestamp:Bool,
    ?endTimestamp:Null<Float>
}


//NTS: Make a reloadButtons() function and button for better UX and convenience.
class ButtonMapping {
    public static var ButtonArray:Array<FlxAnimButton> = [];
    static var ErrorIndices:Map<Int, String> = [];
    static final Default:ButtonProperties = {
        x: 0,
        y: 0,
        label: null,
        tooltip: "(No tooltip set)",
        target: null,
        runIn: null,
        fromRight: false,
        fromBottom: false,
        tooltipColor: "#ffffff",
        args: null,
        scale: 1
    };
    static final DefaultRpc:RpcSettings = {
        details: "(No label provided.)",
        state: "Stateful state",
        smallImageKey: null,
        hasStartTimestamp: false,
        endTimestamp: null
    };
    public static function createButtons() {
        final path:String = "bulkAssets/config.json";
        var buttonList:Array<ButtonProperties> = Json.parse(Assets.getText(path)).buttons;
        for (button in buttonList) {
            //Defaults (isn't there a better way to do this?)
            button.x = button.x ?? Default.x;
            button.y = button.y ?? Default.y;
            button.label = button.label ?? Default.label;
            button.tooltip = button.tooltip ?? Default.tooltip;
            button.target = button.target ?? Default.target;
            button.runIn = button.runIn ?? Default.runIn;
            button.fromRight = button.fromRight ?? Default.fromRight;
            button.fromBottom = button.fromBottom ?? Default.fromBottom;
            button.tooltipColor = button.tooltipColor ?? Default.tooltipColor;
            button.args = button.args ?? Default.args;
            button.scale = button.scale ?? Default.scale;

            if (button.RPC != null) {
                button.RPC.details = button.RPC.details ?? DefaultRpc.details;
                button.RPC.endTimestamp = button.RPC.endTimestamp ?? DefaultRpc.endTimestamp;
                button.RPC.hasStartTimestamp = button.RPC.hasStartTimestamp ?? DefaultRpc.hasStartTimestamp;
                button.RPC.smallImageKey = button.RPC.smallImageKey ?? DefaultRpc.smallImageKey;
                button.RPC.state = button.RPC.state ?? DefaultRpc.state;
            }

            // Button creation
            var labelPath = 'bulkAssets/buttons/${button.label}';
            if (!FileSystem.exists(labelPath)) {
                ErrorIndices.set(buttonList.indexOf(button) + 1, "LabelPathError");
                Sys.println("   \x1b[1;31mButtonMapping\x1b[33m | Button " + (buttonList.indexOf(button) + 1) + " has an invalid image path.\x1b[0m");
                continue;
            }
            var buttonToAdd:FlxAnimButton = new FlxAnimButton(button.label, 0, 0, 'bulkAssets/buttons/${button.label}');
            if (button.scale != null && button.scale is Int)
                buttonToAdd.scale.set(button.scale, button.scale);
            buttonToAdd.init_X = button.fromRight ? Capabilities.screenResolutionX - buttonToAdd.width - button.x : button.x;
            buttonToAdd.init_Y = button.fromBottom ? Capabilities.screenResolutionY - buttonToAdd.height - button.y : button.y;
            
            var ifEnv:String = CheckForEnv(button.runIn, buttonList.indexOf(button));
            if (ifEnv == null) {
                Sys.println("   \x1b[1;33mButtonMapping\x1b[37m | Button " + (buttonList.indexOf(button) + 1) + " needs argument checks.\x1b[0m");
                continue; // skip making button callbacks and adding.
            }

            buttonToAdd.setCallbacks(
                () -> {
                    FlxTween.cancelTweensOf(buttonToAdd);
                    flixel.FlxG.sound.play("bulkAssets/sound/ToggleJingle.ogg");
                    buttonToAdd.scale.x = button.scale;
                    buttonToAdd.scale.y = button.scale;
                    //Note: Command flags are not properly parsed for this; fix soon
                    // Idea: Buttons for selecction group (i.e. based off of FNF mod folders)
                    var args = new NativeProcessStartupInfo();
                    args.executable = new File(ifEnv + "/" + button.target); //placeholder index for one; iterate over object arguments in this block soon.
                    args.workingDirectory = new File(ifEnv);
                    var bruh:Vector<String> = new Vector();
                    bruh.push(button.args);
                    args.arguments = bruh;
                    SettingsSubState.logger.trace("EXTRACE STARTED: "+  button.target + "\n===============", true);

                    var exec:NativeProcess = new NativeProcess();
                    var eventCallback = (e) -> {
                        @:privateAccess var bytes = new haxe.io.Bytes(Std.int(e.bytesLoaded), new BytesData());
                        exec.standardOutput.readBytes(bytes, 0, 0);
                        SettingsSubState.logger.trace(bytes.toString(), true);
                    }; 

                    try {
                        exec.start(args);
                        
                        // Command-line argument readings below for if an app successfully launches; make a smaller app for this soon.
                        exec.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, eventCallback);
                        exec.addEventListener(NativeProcessExitEvent.EXIT, (close:NativeProcessExitEvent) -> {
                            DiscordClient.changePresence();
                        });
                    } catch(no) throw no;

                    if (button.RPC != null) DiscordClient.changePresence(button.RPC.details, button.RPC.state, button.RPC.smallImageKey, button.RPC.hasStartTimestamp, button.RPC.endTimestamp);
                    else DiscordClient.changePresence("Just launched shortcut: " + button.target);
                },
                () -> {
                    FlxTween.cancelTweensOf(buttonToAdd);
                    flixel.FlxG.sound.play("bulkAssets/sound/clickIn.ogg");
                    buttonToAdd.scale.x -= 0.2;
                    buttonToAdd.scale.y -= 0.2;
                },
                () -> {
                    FlxTween.cancelTweensOf(buttonToAdd, ["scale.x", "scale.y"]);
                    FlxTween.tween(buttonToAdd, {"scale.x": button.scale + 0.2, "scale.y": button.scale + 0.2, y: buttonToAdd.y - 10}, 0.5, {ease: FlxEase.circOut});
                    WallpaperState.changeText(button.tooltip, flixel.util.FlxColor.fromString(button.tooltipColor));
                },
                () -> {
                    inline WallpaperState.resetSelection();
                    FlxTween.cancelTweensOf(buttonToAdd, ["scale.x", "scale.y"]);
                    FlxTween.tween(buttonToAdd, {"scale.x": button.scale, "scale.y": button.scale, y: buttonToAdd.init_Y}, 0.5, {ease: FlxEase.circOut});
                }
            );
            ButtonArray.push(buttonToAdd);
        }
        if (Lambda.count(ErrorIndices) > 0) 
            Application.current.window.alert('JSON | Could not initialize ${Lambda.count(ErrorIndices) > 1 ? "buttons: " + ErrorIndices : "button #" + (ErrorIndices)}; check object syntax or console for info.', "- Buttons failed! -");

        for (btn in ButtonArray) {
            WallpaperState.instance.add(btn);
            btn.cameras = [WallpaperState.camGUI];
        }
    } 
    static function CheckForEnv(cmdPath:String, index:Int):String {
        final envReg:EReg = ~/%([0-9a-zA-Z_(-)]+)%/giu;
        var cwd:String = Sys.getCwd();
        if (envReg.match(cmdPath)) {
            var parsedEnv:Null<String> = envReg.matched(1);
            parsedEnv = Sys.getEnv(parsedEnv).replace("\\","/");
            Sys.println("   \x1b[1;33mEnvCheck\x1b[0;37m | "+ (index + 1) +": Env Variable detected: " + parsedEnv);
            if (parsedEnv == null || parsedEnv == "") {
                Sys.println("   \x1b[1;31mEnvCheck\x1b[0;33m | !!! BUTTON " + (index+1) + " ERROR. Environment variable specified does not exist or have a value!\x1b[37m");
                ErrorIndices.set(index + 1, "InvalidEnvError");
                return null;
            }
            
            cmdPath = envReg.replace(cmdPath, parsedEnv);
            // TO-DO: FIX ALL LOGIC FOR DIRECTORIES BEFORE FILES.
            if (FileSystem.exists(cwd + "/" + cmdPath) || FileSystem.exists(cmdPath) ) {
                Sys.println('      \\ Button ${index+1} \x1b[1;32msuccessfully parsed.\x1b[0;37m Target: $cmdPath');
                return cmdPath;
            }
            else {
                // Overhaul: Check which directory may be misspelled and format output path segment for location.
                var WhichDirectory:Array<String> = cmdPath.split("/");
                var checker:String = "";
                var ErrorFound:Bool = false;
                for (path in WhichDirectory) {
                    if (!FileSystem.exists(checker + path)) {
                        if (checker == "C:/") continue;
                        if (!ErrorFound) {
                            checker = checker + "\x1b[1;31m" + path + "\x1b[0;37m/";
                            ErrorFound = true;
                            continue;
                        }
                    }
                    checker += path+"/";
                }
                Sys.println("   \x1b[1;31mEnvCheck\x1b[0;33m | !!! BUTTON " + (index+1) + " ERROR. Target: \x1b[37m" + checker + "\x1b[37m");
                ErrorIndices.set(index + 1, "NullPathError");
                return null;
            }            
        }
        return null;
    }
    
}