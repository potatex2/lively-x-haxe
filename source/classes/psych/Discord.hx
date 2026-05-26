package classes.psych;

import Sys.sleep;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

// Discord class ported from Psych Engine.
class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static final _defaultID:String = "1508968068959703181";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public static function check()
	{
		initialize();
	}
	
	public static function prepare()
	{
		if (!isInitialized)
			initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
	}

	public dynamic static function shutdown() {
		Discord.Shutdown();
		isInitialized = false;
	}
	
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			Sys.println('   \x1b[1;33mDiscord\x1b[0;37m Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else //Old discriminators
			Sys.println('   \x1b[1;33mDiscord\x1b[0;37m Connected to User (${cast(requestPtr.username, String)})');

		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Sys.println('\x1b[1;31mDiscord\x1b[0;33m | ERROR ($errorCode: ${cast(message, String)})\x1b[37m');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Sys.println('\x1b[1;31mDiscord\x1b[0;33m | Disconnected ($errorCode: ${cast(message, String)})\x1b[37m');
	}

	public static function initialize()
	{
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if(!isInitialized) Sys.println("   \x1b[1;33mDiscord\x1b[0m | Discord Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
	}

	/**Allows you to set Discord RPC status, if applicable to the current player/user.
	 * @param Details The main text for the status.
	 * @param State The text below that serves as a description.
	 * @param SmallImageKey The image to use on the bottom right.
	 * @param StartTimestamp Will the status have a timer or time elapsed?
	 * @param EndTimestamp When does the status timer, if applicable, end?
	 * Note that timestamps must be in full millisecond format in order for Discord
	 * to use it in Rich Presence.
	**/
	public static function changePresence(?details:String = 'AFK', ?state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "WIP";
		presence.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updatePresence()
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
	
	public static function resetClientID()
		clientID = _defaultID;

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}
}
