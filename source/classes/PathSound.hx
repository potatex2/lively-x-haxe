package classes;

import flixel.sound.FlxSound;
import flixel.FlxG;
import sys.FileSystem;
import classes.Const;

class PathSound extends FlxSound {
    public function soundCheck(path:String, sound:Bool = true):Void {
        if (this == null || !FileSystem.exists(Const.RD + path)) return;
        try {
            this.loadEmbedded(Const.RD + path, !sound);
            FlxG.sound.list.add(this);
            trace('$path | in '+FlxG.sound.list);
            this.play();
        } catch(nul) throw nul;
    }
}