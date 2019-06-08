
# Lavalink for Discordia [0.1.0]
This library is a Lavalink Client for [Discordia](https://github.com/SinisterRectus/Discordia)
## What is Lavalink?
Lavalink is an alternative method for playing audio in Discord Voice Channels. You can read more about it [here](https://github.com/Frederikam/Lavalink)
To setup Lavalink, follow [these instructions](https://github.com/Frederikam/Lavalink#server-configuration)
## Installing discordia-lavalink
This library is currently in development, however it is usable to an extent. Currently, to install, download the library and place it in your 'deps' folder
I cannot guarantee that it is stable; if you find any issues, please report them.
# Documentation
## Voice Manager
`local VoiceManager = require('discordia-lavalink').VoiceManager`
### Initializing the Voice Manager:
Call the VoiceManager with your client and node settings
Node settings: 
```
{
	host = string,
	port = number,
	password = string,
	reconnectInterval? = number
}
```
`VoiceManager(client, nodes)`
### VoiceManager.api
Property to retrieve the API for Lavalink
### VoiceManager:join(channel, host?)
Join a GuildVoiceChannel
You can provide a specific host, otherwise the first host will be used
Returns: `Player`
### VoiceManager:leave(guildOrVoiceChannel)
Leave a VoiceChannel
You can provide a Guild or a GuildVoiceChannel to leave
Returns: `boolean`
### VoiceManager:getPlayer(guildOrVoiceChannel)
Get a Player for a specific Guild
You can provide a Guild or a GuildVoiceChannel
Returns: `Player | nil`

## Player

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
- Finish off all the functions for Player
- Add automatic load balancing for selecting a node for Player to join