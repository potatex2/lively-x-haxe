package classes;

import flixel.ui.FlxButton;

/**
    Literally `FlxButton`, but added a buffer. I might just hardcode it in
    original file at some point if nothing else is added and this becomes redundant.
    
    \- PotateX2
*/
class UI extends FlxButton {
    public var buffer:Bool = false; // buffer for button spam prevention
    public function new(x:Int, y:Int, text:String, func:Void->Void) {
        super(x, y, text, func);
    }
}