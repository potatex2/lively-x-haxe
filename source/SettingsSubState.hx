package;
import flixel.addons.ui.StrNameLabel;
import sys.FileSystem;
import openfl.system.Capabilities;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import classes.FlxDynamics;
import classes.ui.ExternLogger;
import flixel.addons.ui.FlxUIDropDownMenu;

import WallpaperState;

class SettingsSubState extends FlxSubState {
    var outtaThere:FlxAnimButton;
    var placehold:FlxDynamicText;
    var musicSelect:FlxUIDropDownMenu;
    public static var logger:ExternLogger;
    override function create() {
        super.create();

        WallpaperState.instance.configButton.visible = false;
        WallpaperState.instance.persistentUpdate = true;
        FlxTween.completeTweensOf(WallpaperState.camHUD, ["alpha"]);
        FlxTween.tween(WallpaperState.camHUD, {alpha: 0.5}, 0.85, {ease: FlxEase.cubeOut});
        placehold = new FlxDynamicText("placeholder", 0, 0, 0, "placeholder ehehe", 16)
        .setFormat("PhantomMuff 1.5", 16, 0x63ED00, CENTER, OUTLINE, 0x01959f);
        placehold.screenCenter();
        placehold.y += 200;
        this.add(placehold);

        outtaThere = new FlxAnimButton("exit", 0, Capabilities.screenResolutionY * 0.7125, "bulkAssets/SaveConfig.png", destroy);
        outtaThere.x = Capabilities.screenResolutionX / 2 - outtaThere.width / 2;
        this.add(outtaThere);

        InitMusicSelect();
        musicSelect.selectedLabel = WallpaperState.Selection;

        FlxG.stage.addChild(logger);
    }
    override function destroy() {
        FlxTween.completeTweensOf(WallpaperState.camHUD, ["alpha"]);
        FlxTween.tween(WallpaperState.camHUD, {alpha: 1}, 0.85, {ease: FlxEase.cubeOut});
        WallpaperState.instance.configButton.visible = true;
        outtaThere = null;
        FlxG.save.data.selected = musicSelect.selectedLabel;
        FlxG.save.flush();
        FlxG.stage.removeChild(logger);
        close();
        super.destroy();
    }

    var musicSelection:Array<StrNameLabel> = [];
    function InitMusicSelect() {
        // To-do: determine how standalone audio files will be handled.
        var musicList:Array<String> = FileSystem.readDirectory("bulkAssets/music");
        trace(musicList);
        var i:Int = 0;
        while (i <= musicList.length - 1) {
            if (i > musicList.length - 1) break;
            var fileName:Array<String> = musicList[i].split(".");
            var nextFile:Array<String>;
            if ((i + 1 <= musicList.length)) {
                nextFile = musicList[i + 1].split(".");
                if (fileName[0] == nextFile[0] && fileName[1] == "json" && nextFile[1] == "ogg") {
                    musicSelection.push(new StrNameLabel(fileName[0], fileName[0]));
                    i++; // Increment twice for next pair
                }                   
            }
            i++;
        }
        musicSelect = new FlxUIDropDownMenu(100, 50, musicSelection, (sel:String) -> {
            if (WallpaperState.flaxhixele.text.contains(sel)) return; // better way to check this, sigh.
            WallpaperState.Selection = sel;
            FlxG.sound.music.loadEmbedded("bulkAssets/music/" + sel + ".ogg", true).play();
            WallpaperState.jason = haxe.Json.parse(Assets.getText('bulkAssets/music/$sel.json')).music.bpm;
            logger.trace('Data BPM: ${WallpaperState.jason}', false);
            WallpaperState.croshet = flixel.math.FlxMath.roundDecimal(60 / WallpaperState.jason, 4);
            WallpaperState.flaxhixele.text = 'Custom-made in HaxeFlixel; music selected: "$sel"';
        });
        this.add(musicSelect);
    }
}
typedef WallpaperOptions = {
    var pauseMusic:String;
    var volume:Int;
} //is this even necessary