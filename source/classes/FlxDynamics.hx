package classes;

import flixel.util.FlxColor;
import flixel.ui.FlxSpriteButton;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

// Honestly, I think I can optimize this with making the map dynamic for each entry
// of whatever and make one class for all extended types.
// Eh, I'm probably delusional and it doesn't work, so I'll figure it out in the future. :P

class FlxDynamicText extends FlxText {
    public static var entries:Map<String, FlxDynamicText> = [];
    public function new(refTag:String, x:Int, y:Int, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
        super(x, y, FieldWidth, Text, Size, EmbeddedFont);
        entries.set(refTag, this);
    }
    public static function getInstance(which:String):FlxDynamicText {
        for (named => obj in entries) {
            if (named == which) return obj;
        }
        return null;
    }
    override public function setFormat(?Font:String, Size:Int = 8, Color:flixel.util.FlxColor = 0xFFFFFF, ?Alignment, ?BorderStyle, BorderColor = FlxColor.WHITE, EmbeddedFont:Bool = true):FlxDynamicText {
        super.setFormat(Font, Size, Color, Alignment, BorderStyle, BorderColor, EmbeddedFont);
        // Derived from original cuz return stuff :/
        BorderStyle = (BorderStyle == null) ? NONE : BorderStyle;
		if (EmbeddedFont)
		{
			font = Font;
		}
		else if (Font != null)
		{
			systemFont = Font;
		}

		size = Size;
		color = Color;
		if (Alignment != null)
			alignment = Alignment;
		setBorderStyle(BorderStyle, BorderColor);

		updateDefaultFormat();

		return this;
    }
}
/**
    Created because I need to reference stuff for memory alloc    
*/
class FlxTagSprite extends FlxSprite {
    //IMPORTANT
    public var init_X:Float;
    public var init_Y:Float;
    public var name:String;
    public static var entries:Map<String, FlxTagSprite> = [];
    public function new(name:String, ?x:Float = 0, ?y:Float = 0) {
        super(x, y);
        this.name = name;
        this.init_X = x;
        this.init_Y = y;
        entries.set(name, this);
    }
    public static function get(which:String):FlxTagSprite {
        for (named => obj in entries) {
            if (named == which) return obj;
        }
        return null;
    }
}

class FlxAnimButton extends FlxSpriteButton {
    public var init_X(default, set):Float;
    public var init_Y(default, set):Float;
    public static var entries:Map<String, FlxAnimButton> = [];
    public var cd:Bool = false;
    public function new(name:String, x:Float, y:Float, label:String, ?func:()->Void) {
        super(x, y, null, func);
        this.init_X = x;
        this.init_Y = y;
        this.loadGraphic(label);
        entries.set(name, this);
    }
    public static function get(which:String):FlxAnimButton {
        for (named => obj in entries) {
            if (named == which) return obj;
        }
        return null;
    }
    public function setCallbacks(clickFUNC:()->Void, ?clickHOLD:()->Void, ?hoverOn:()->Void, ?hoverOff:()->Void) {
        this.onUp.callback = () -> if (!cd) clickFUNC();
        this.onDown.callback = () -> if (!cd) clickHOLD();
        this.onOver.callback = () -> if (!cd) hoverOn();
        this.onOut.callback = () -> if (!cd) hoverOff();
    }
    function set_init_X(value:Float):Float {
        this.init_X = value;
        this.x = value;
        return value;
    }
    function set_init_Y(value:Float):Float {
        this.init_Y = value;
        this.y = value;
        return value;
    }
}
class FlxGroupButton extends FlxSpriteGroup {
    public static var entries:Map<String, FlxGroupButton> = [];
    public var toggleState:Null<Bool>;
    /**
        @param name Tag name of `this` object
        @param x X-position of base
        @param y Y-position of base
        @param button Base button sprite
    */
    public function new(name:String, x:Float, y:Float, button:FlxAnimButton, toggleable:Bool = false) {
        super();
        entries.set(name, this);
        add(button);
        if (toggleable) this.toggleState = true; //go on from here
    }
    public function addElement(obj:FlxSprite) {
        this.add(obj);
    }
    public static function get(which:String):FlxGroupButton {
        for (named => obj in entries) {
            if (named == which) return obj;
        }
        return null;
    }
}