package classes;

import flixel.sound.FlxSound;
import flixel.FlxG;
import classes.Const;

class PathSound extends FlxSound {
    public function soundCheck(path:String, sound:Bool = true):Void {
        if (this == null) return;
        try {
            this.loadEmbedded(Const.RD + path, !sound);
            FlxG.sound.list.add(this);
            this.play();
        } catch(nul) throw nul;
    }
}