package;
import flixel.text.FlxText;
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

import WallpaperState as WS;

class SettingsSubState extends FlxSubState {
    var outtaThere:FlxAnimButton;
    var placehold:FlxDynamicText;
    var musicSelect:FlxUIDropDownMenu;
    var iconSelect:FlxUIDropDownMenu;
    var musicHeader:FlxText;
    var iconHeader:FlxText;
    public static var logger:ExternLogger;

    var linkHeader:FlxText;
    var repoButton:FlxAnimButton;
    override function create() {
        // Figure out how to add the sparrow atlas for the Alphabet class.
        super.create();

        WS.instance.configButton.visible = false;
        WS.instance.persistentUpdate = true;
        FlxTween.completeTweensOf(WS.camHUD, ["alpha"]);
        FlxTween.tween(WS.camHUD, {alpha: 0.5}, 0.85, {ease: FlxEase.cubeOut});
        placehold = new FlxDynamicText("placeholder", 0, 0, 0, "More features coming soon!", 22)
        .setFormat("PhantomMuff 1.5", 22, 0x63ED00, CENTER, OUTLINE, 0x01959f);
        placehold.screenCenter();
        placehold.y += 200;
        this.add(placehold);

        outtaThere = new FlxAnimButton("exit", 0, Capabilities.screenResolutionY * 0.7125, WallpaperState.Embed("SaveConfig.png"), destroy);
        outtaThere.x = Capabilities.screenResolutionX / 2 - outtaThere.width / 2;
        this.add(outtaThere);
        outtaThere.setCallbacks(
            () -> {
                FlxTween.cancelTweensOf(outtaThere);
                FlxG.sound.play("bulkAssets/sound/clickOut.ogg");
                outtaThere.scale.x = 1;
                outtaThere.scale.y = 1;
                destroy();
            },
            () -> {
                FlxTween.cancelTweensOf(outtaThere);
                FlxG.sound.play("bulkAssets/sound/clickIn.ogg");
                outtaThere.scale.x -= 0.2;
                outtaThere.scale.y -= 0.2;
            },
            () -> {
                FlxTween.cancelTweensOf(outtaThere, ["scale.x", "scale.y"]);
                FlxTween.tween(outtaThere, {"scale.x": 0.9, "scale.y": 0.9, y: outtaThere.y - 10}, 0.5, {ease: FlxEase.circOut});
            },
            () -> {
                FlxTween.cancelTweensOf(outtaThere, ["scale.x", "scale.y"]);
                FlxTween.tween(outtaThere, {"scale.x": 0.8, "scale.y": 0.8, y: outtaThere.init_Y}, 0.5, {ease: FlxEase.circOut});
            }
        );

        InitMusicSelect();
        InitIconList();
        AddGithub();
        musicSelect.selectedLabel = WS.Selection;

        FlxG.stage.addChild(logger);
    }
    override function destroy() {
        FlxTween.completeTweensOf(WS.camHUD, ["alpha"]);
        FlxTween.tween(WS.camHUD, {alpha: 1}, 0.85, {ease: FlxEase.cubeOut});
        WS.instance.configButton.visible = true;
        outtaThere = null;
        FlxG.save.data.selected = musicSelect.selectedLabel;
        FlxG.save.flush();
        FlxG.stage.removeChild(logger);
        close();
        super.destroy();
    }

    var musicSelection:Array<StrNameLabel> = [];
    function InitMusicSelect():Void {
        // To-do: determine how standalone audio files will be handled.
        var musicList:Array<String> = FileSystem.readDirectory("bulkAssets/music");
        Sys.println("   \x1b[1;33mMusicList\x1b[0m | Found files: " + musicList);
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
        musicHeader = new FlxText(150, 75, 0, "Background Music", 22)
        .setFormat("PhantomMuff 1.5", 22, 0x00ffb3, LEFT, OUTLINE, 0x008cff);
        this.add(musicHeader);
        musicSelect = new FlxUIDropDownMenu(150, 110, musicSelection, (sel:String) -> {
            if (WS.flaxhixele.text.contains(sel)) return; // better way to check this, sigh.
            WS.Selection = sel;
            FlxG.sound.music.loadEmbedded("bulkAssets/music/" + sel + ".ogg", true).play();
            WS.jason = haxe.Json.parse(Assets.getText('bulkAssets/music/$sel.json')).music.bpm;
            logger.trace('Data BPM: ${WS.jason}', false);
            WS.croshet = flixel.math.FlxMath.roundDecimal(60 / WS.jason, 4);
            WS.flaxhixele.text = 'Created with HaxeFlixel; music selected: "$sel"';
        });
        this.add(musicSelect);
    }

    var iconList:Array<StrNameLabel> = [];
    function InitIconList():Void {
        //Feature: Distinguish icons with sparrow frames (i.e. original FNF icons) from static ones. 
        var availableIcons:Array<String> = FileSystem.readDirectory("bulkAssets/icons");
        if (availableIcons == null) {
            Sys.println("   \x1b[1;31mIconList\x1b[0;33m | No icons found; falling back to self-insert.\x1b[0m");
            return;
        }
        Sys.println("   \x1b[1;33mIconList\x1b[0m | Found icons: " + availableIcons);
        var i:Int = 0;
        while (i <= availableIcons.length - 1) {
            var fileName:String = availableIcons[i];
            if ((i + 1 <= availableIcons.length)) {
                if (fileName.endsWith(".png") || fileName.endsWith(".jpg")) {
                    iconList.push(new StrNameLabel(fileName.split(".")[0], fileName.split(".")[0]));
                }
            }
            i++;
        }
        iconHeader = new FlxText(150, 250, 0, "Bopper Icon", 22)
        .setFormat("PhantomMuff 1.5", 22, 0xa6ff00, LEFT, OUTLINE, 0x00eeff);
        this.add(iconHeader);
        iconSelect = new FlxUIDropDownMenu(150, 285, iconList, (sel:String) -> {
            WS.bopper.loadGraphic('bulkAssets/icons/$sel');
            WS.bopper.screenCenter(X);
            logger.trace(')))  Changed icon to: $sel', false);
        });
        this.add(iconSelect);
    }
    function AddGithub():Void {
        linkHeader = new FlxText(150, 500, 0, "Issues? Report them in the repo!", 22)
        .setFormat("PhantomMuff 1.5", 22, 0xcfd300, LEFT, OUTLINE, 0xcffd00);
        this.add(linkHeader);
        
        repoButton = new FlxAnimButton("repo", 150, 550, WallpaperState.Embed("siteRepo.png"), destroy);
        this.add(repoButton);
        repoButton.setCallbacks(
            () -> {
                FlxTween.cancelTweensOf(repoButton);
                FlxG.sound.play(WallpaperState.Embed("reduxAccept.ogg"));
                repoButton.scale.x = 1;
                repoButton.scale.y = 1;
                FlxG.openURL("https://github.com/potatex2/lively-x-haxe/issues");
            },
            () -> {
                FlxTween.cancelTweensOf(repoButton);
                FlxG.sound.play("bulkAssets/sound/clickIn.ogg");
                repoButton.scale.x -= 0.2;
                repoButton.scale.y -= 0.2;
            },
            () -> {
                FlxTween.cancelTweensOf(repoButton, ["scale.x", "scale.y"]);
                FlxTween.tween(repoButton, {"scale.x": 0.9, "scale.y": 0.9, y: repoButton.y - 10}, 0.5, {ease: FlxEase.circOut});
            },
            () -> {
                FlxTween.cancelTweensOf(repoButton, ["scale.x", "scale.y"]);
                FlxTween.tween(repoButton, {"scale.x": 0.8, "scale.y": 0.8, y: repoButton.init_Y}, 0.5, {ease: FlxEase.circOut});
            }
        );
    }
}