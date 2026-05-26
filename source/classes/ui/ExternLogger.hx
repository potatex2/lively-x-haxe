package classes.ui;
import openfl.Vector;
import openfl.system.Capabilities;
import openfl.geom.Rectangle;
import openfl.Lib;
import flixel.FlxG;
import openfl.events.MouseEvent;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

class ExternLogger extends Sprite {
    public static var logs:TextField = new TextField();
    public var windowText:TextField = new TextField();
    static var mouse_X:Float;
    static var mouse_Y:Float;
    public static function init() {
        WallpaperState.bindToUpdate(() -> {
            mouse_X = Lib.current.stage.mouseX;
            mouse_Y = Lib.current.stage.mouseY;
        });
    }
    public function new(x:Float, y:Float, width:Int = 100, height:Int = 100, size:Int = 20) {
        super();

        var call = this.graphics;
        this.x = x;
        this.y = y + 30;
        call.beginFill(0x5C5C5C, 1);
        call.drawRoundRect(0, 0, width, height, 12);
        call.endFill();

        call.beginGradientFill(openfl.display.GradientType.LINEAR, [0x00F535, 0x009FB4], [1, 1], [0, 255]);
        call.drawRoundRect(0, 0, width, 30, 12);
        call.endFill();

        call.beginFill(0x464646);
        call.drawRect(0, 26, width, 4);
        call.endFill();

        this.addChild(windowText);
        windowText.x = 6;
        windowText.y = 4;
        windowText.type = DYNAMIC;
        windowText.text = " > Console";
        windowText.setTextFormat(new TextFormat("PhantomMuff 1.5", 14, 0x000000, true));

        this.addChildAt(logs, 1);
        logs.type = DYNAMIC;
        logs.text = "// Console logs will pop up here.\n// -----------------\n";
        logs.y += 30; logs.width = width; logs.height = height - 30;
        logs.multiline = true; logs.wordWrap = true;
        logs.addEventListener(MouseEvent.MOUSE_WHEEL, (scrl:MouseEvent) -> {
            if (logs.hitTestPoint(Lib.current.stage.mouseX, Lib.current.stage.mouseY)) {
                if (scrl.delta < 0) {
                    logs.scrollV += 1;
                } else if (scrl.delta > 0) {
                    logs.scrollV -= 1;
                }
            }
        });
        logs.setTextFormat(new TextFormat("PhantomMuff 1.5", size, 0x66ff33));

        this.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, (click:MouseEvent) -> {
            if (this.hitTestPoint(mouse_X, mouse_Y)) {
                this.startDrag(false, new Rectangle(0, 0, Capabilities.screenResolutionX - this.width / 2, Capabilities.screenResolutionY - this.height / 2));
            }
        });
        this.addEventListener(MouseEvent.RIGHT_MOUSE_UP, (click:MouseEvent) -> {
            this.stopDrag();
        });
        //This is a placeholder and has no effect.
        this.graphics.beginFill(0xC72E00);
        this.graphics.drawRect(this.width - 3, 3, -19, 19);
        this.graphics.endFill();
    }
    /** Helper function for logging and console tracing. */
    public function trace(v:Dynamic, exTrace:Bool) {
        var toTrace:String = exTrace ? "EXTRACE | \x1b[36m" + v + "\x1b[37m" : v;
        Sys.println(toTrace);
        logs.appendText("\n"+Std.string(v));
    }

    public inline function toggle() {
        if (FlxG.stage.contains(this))
            FlxG.stage.removeChild(this);
        else FlxG.stage.addChild(this);
    }
}