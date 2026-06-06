package classes;

import flixel.FlxG;
import openfl.Lib;

#if cpp
@:cppFileCode('#include <windows.h>')
@:buildXml('
<target id="haxe">
    <lib name="user32.lib" />
</target>
')
#end

class WindowsTransparency
{
    #if cpp

    public static function enableTransparency():Void
    {
        FlxG.camera.bgColor = 0xFF000000;

        untyped __cpp__('
            HWND hwnd = GetActiveWindow();
            LONG exStyle = GetWindowLongA(hwnd, GWL_EXSTYLE);
            SetWindowLongA(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED);
            SetLayeredWindowAttributes(hwnd, 0x2B2B2B, 0, LWA_COLORKEY);
        ');
        
        //Lib.application.window.borderless = true;
    }

    /**
    public static function disableTransparency():Void
    {
        FlxG.camera.bgColor = 0xFF100000;

        untyped __cpp__('
            HWND hwnd = GetActiveWindow();
            LONG exStyle = GetWindowLongA(hwnd, GWL_EXSTYLE);
            SetWindowLongA(hwnd, GWL_EXSTYLE, exStyle & ~WS_EX_LAYERED);
        ');

        //Lib.application.window.borderless = false;
    }
    **/

    #end
}