local discordia = require('discordia')
local Emitter = discordia.Emitter
local class = discordia.class

local Player, get = class('Player', Emitter)
local format = string.format
local function bind(t, k)
  return function(...) return t[k](t, ...) end
end

function Player:__init(manager, node, guild, channel)
  Emitter.__init(self)
  self._manager = manager
  self._client = manager._client
  self._node = node

  self._guild = guild
  self._channel = channel

  self._playing = false
  self._paused = false
  self._volume = 100
  self._track = nil
  self._trackPosition = nil
  self._lastChecked = nil
  self._startedAt = nil

  self._node:on('event', bind(self, '_onEvent'))
end

function Player:play(track, options)
  options = options or {}
  local data = {
    op = 'play',
    guildId = self._guild.id,
    track = type(track) == 'table' and track.track or track
  }
  if options.startTime then data.startTime = options.startTime end -- Start time of track (milliseconds)
  if options.endTime then data.endTime = options.endTime end -- End time of track (milliseconds)
  if options.noReplace then data.noReplace = options.noReplace end -- Ignore if already currently playing song
  self._node:send(data)
  self._track = track
  self._startedAt = os.time(os.date('!*t'))
  return self
end

function Player:pause(pause)
  if pause == nil then pause = true end
  self._node:send({
    op = 'pause',
    guildId = self._guild.id,
    pause = pause
  })
  self._paused = pause
  return self
end

function Player:resume()
  return self:pause(false)
end

function Player:stop()
  self._node:send({
    op = 'stop',
    guildId = self._guild.id
  })
  self._playing = false
  self._track = nil
  self._lastChecked = nil
  self._trackPosition = nil
  return self
end

function Player:seek(position) -- milliseconds
  if not position then return false, 'No position provided' end
  self._node:send({
    op = 'seek',
    guildId = self._guild.id,
    position = position
  })
  return self
end

function Player:volume(volume)
  volume = volume or 100
  if volume < 0 then return false, 'Min volume is 0' end
  if volume > 1000 then return false, 'Max volume is 1000' end
  self._node:send({
    op = 'volume',
    guildId = self._guild.id,
    volume = volume
  })
  return self
end

function Player:equalizer(band, gain)
  if band < 0 then return false, 'Min band is 0' end
  if band > 14 then return false, 'Max band is 14' end

  gain = gain or 0
  if gain < -0.25 then return false, 'Min gain is -0.25' end
  if gain > 1 then return false, 'Max gain is 1.0' end
  self._node:send({
    op = 'equalizer',
    guildId = self._guild.id,
    bands = {
      band = band,
      gain = gain
    }
  })
  return self
end

function Player:destroy()
  self._node:send({
    op = 'destroy',
    guildId = self._guild.id
  })
  return nil
end

function Player:moveChannel(channel)
  if channel.id == self._channel.id then return false end
  self._channel = channel
  return self._manager:joinChannel(channel, self._node.host)
end

function Player:_connect(sessionId, event)
  self._node:send({
    op = 'voiceUpdate',
    guildId = self._guild.id,
    sessionId = sessionId,
    event = event
  })
end

function Player:_onEvent(data)
  if data.guildId ~= self._guild.id then return end
  if data.op == 'playerUpdate' then
    if not self._playing then return false end
    self._trackPosition = data.state.position
    self._lastChecked = data.state.time
  elseif data.type == 'TrackEndEvent' then
    if data.reason ~= 'REPLACED' then
      self._playing = false
      self._track = nil
      self._startedAt = nil
      self._lastChecked = nil
      self._trackPosition = nil
    end
    self:emit('end', data)
  elseif data.type == 'TrackExceptionEvent' then
  elseif data.type == 'TrackStuckEvent' then
    self:stop()
    self:emit('end', data)
  else
    self:emit('warn', format('Unknown Event %s', data.type))
  end
end

function get.playing(self)
  return self._playing
end

function get.paused(self)
  return self._paused
end

function get.track(self)
  return self._track
end

function get.info(self)
  return {
    volume = self._volume,
    startedAt = self._startedAt,
    position = self._trackPosition,
    lastChecked = self._lastChecked
  }
end

return Player