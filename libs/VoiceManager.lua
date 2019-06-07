local discordia = require('discordia')
local json = require('json')
local class = discordia.class

local Player = require('Player')
local Node = require('Node')
local API = require('API')
local VoiceManager, get = class('LavalinkVoiceManager')

local format = string.format
-- Nodes are used if you have multiple voice servers, in order to split the load

function VoiceManager:__init(client, nodes)
  self._client = assert(client, 'client not provided')
  self._api = API(self)
  self._nodes = {}
  self._players = {}

  self._client:on('raw', function(data)
    data = json.decode(data)
    if data.t == 'VOICE_SERVER_UPDATE' then
      data = data.d
      local guild = self._client:getGuild(data.guild_id)
      if not guild then return end

      local player = self._players[guild.id]
      if not player then return end

      local user = guild.me or guild:getMember(self._client.user.id)
      if not user then return end

      -- RELYING ON INTERNAL DATA STORES --
      local state = guild._voice_states[user.id]
      if not state then return end

      player:_connect(state.session_id, data)
    end
  end)

  for _, node in pairs(nodes) do
    -- {host = 'host', port = port, password = password}
    self:_createNode(node)
  end
end

function VoiceManager:_createNode(options)
  assert(options.host, 'node host not provided')
  if self._nodes[options.host] then return false, format('Already have node at %s', options.host) end
  self._nodes[options.host] = Node(self._client, options)
end

function VoiceManager:_deleteNode(host)
  -- TODO Get Node By Host
  -- TODO Clear Event Emitters from Node
  -- TODO Delete Node
end

function VoiceManager:_spawnPlayer(guild, channel, host)
  if self._players[guild.id] then return self._players[guild.id] end
  local node
  if host then
    node = assert(self._nodes[host], format('no available node with host %s', host))
  else
    node = self._nodes[next(self._nodes)]
  end
  assert(node, 'no nodes available')
  local player = Player(self, node, guild, channel)
  self._players[guild.id] = player
  return player
end

function VoiceManager:join(channel, host)
  if class.type(channel) ~= 'GuildVoiceChannel' then return false, 'Not a Voice Channel' end
  local guild = channel.guild
  if not guild then return false, 'Could not find guild' end
  if self._players[guild.id] then return self._players[guild.id] end

  -- Join to Channel
  local success, err = self._client._shards[guild.shardId]:updateVoice(guild.id, channel.id)
  if not success then return nil, err end
  return self:_spawnPlayer(guild, channel, host)
end

function VoiceManager:leave(guild)
  if class.type(guild) == 'GuildVoiceChannel' then guild = guild.guild end -- Accepts GuildVoiceChannel
  if class.type(guild) ~= 'Guild' then return false, 'Not a Guild' end

  local success, err = self._client._shards[guild.shardId]:updateVoice(guild.id)
  if not success then return nil, err end

  local player = self._players[guild.id]
  if player then
    player:removeAllListeners()
    player:_destroy()
    self._players[guild.id] = nil
  end
  return true
end

function VoiceManager:getPlayer(guild)
  if class.type(guild) == 'GuildVoiceChannel' then guild = guild.guild end -- Accepts GuildVoiceChannel
  if class.type(guild) ~= 'Guild' then return false, 'Not a Guild' end

  return self._players[guild.id]
end

function get.api(self)
  return self._api
end

return VoiceManager