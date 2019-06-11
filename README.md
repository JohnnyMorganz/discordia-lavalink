
# Lavalink for Discordia [0.1.0]
This library is a Lavalink Client for [Discordia](https://github.com/SinisterRectus/Discordia)
## What is Lavalink?
Lavalink is an alternative method for playing audio in Discord Voice Channels. You can read more about it [here](https://github.com/Frederikam/Lavalink)
To setup Lavalink, follow [these instructions](https://github.com/Frederikam/Lavalink#server-configuration)
## Installing discordia-lavalink
This library is currently in development, however it is usable to an extent. Currently, to install, download the library and place it in your 'deps' folder
I cannot guarantee that it is stable; if you find any issues, please report them.
# Documentation
View the [wiki](https://github.com/JohnnyMorganz/discordia-lavalink/wiki) to view the Documentation

## Example Implementation
```lua
local discordia = require('discordia')
local Lavalink = require('discordia-lavalink')
local VoiceManager = Lavalink.VoiceManager

local client = discordia.Client()
local manager
local nodes = {
	{host = '127.0.0.1', port = 2333, password = 'youshallnotpass'}
}

client:on('ready', function()
	manager = VoiceManager(client, nodes)
end)

client:on('messageCreate', function(message)
	-- Handle Commands
	if command == 'joinvc' then
		manager:join(voiceChannel)
	elseif command == 'play' then
		local player = manager:getPlayer(voiceChannel)
		local info = manager.api:get(trackId)
		if info and info.tracks and #info.tracks > 0then
			player:play(info.tracks[1].track)
		end
	elseif command == 'leavevc' then
		manager:leave(voiceChannel)
	end
end)
```
### TODO:
- Add automatic load balancing for selecting a node for Player to join