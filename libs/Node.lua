local discordia = require('discordia')
local websocket = require('coro-websocket')
local json = require('json')
local timer = require('timer')

local Emitter = discordia.Emitter
local class = discordia.class

local Node, get = class('Node', Emitter)

local format = string.format

function Node:__init(client, options)
  Emitter.__init(self)
  assert(options, 'options not provided')

  self._client = assert(client, 'Discordia Client not provided')
  self._host = assert(options.host, 'options.host not provided')
  self._port = options.port or 2333
  self._address = options.address or format('ws://%s:%s/', self._host, self._port)
  self._password = options.password or 'youshallnotpass'

  self._connected = false
  self._res = nil
  self._read = nil
  self._write = nil
  self._reconnectInterval = options.reconnectInterval or 15000
  self._reconnectAttempts = 0
  self._stats = {}

  self:connect()
end

function Node:connect()
  if self._connected then return false, 'Already connected' end

  local options = websocket.parseUrl(self._address)
  options.headers = {
    {'Authorization', self._password},
    {'Num-Shards', self._client.shardCount},
    {'User-Id', self._client.user.id}
  }

  local res, read, write = websocket.connect(options)
  if res and res.code == 101 then
    self._connected = true
    self._res, self._read, self._write = res, read, write
    coroutine.wrap(self._handleData)(self)
    print('Lavalink Node Connected')
    return true
  end
  return false, read
end

function Node:close(forced)
  if not self._connected then return end
  self._connected = false
  self._write()
  self._res, self._read, self._write = nil, nil, nil
  if not forced then self:_reconnect() end
end

function Node:send(data)
  if not self._connected then return end
  return self._write({
    opcode = 1,
    payload = json.encode(data)
  })
end

function Node:destroy()
  -- Currently have to get all available listener names and remove them
  self:emit('killed')
  self:removeAllListeners('event')
  self:close(true)
end

function Node:_reconnect()
  print('Reconnecting')
  local success = self:connect()
  if not success then
    self._reconnectAttempts = self._reconnectAttempts + 1
    if self._reconnectAttempts > 10 then
      print('Error, could not reconnect after 10 retries')
      return self:destroy()
    end
    print(format('Could not reconnect, retrying in %sms - Attempt %s', self._reconnectInterval, self._reconnectAttempts))
    timer.sleep(self._reconnectInterval)
    self:_reconnect()
  else
    self._reconnectAttempts = 0
    print('Reconnected')
  end
end

function Node:_handleData()
  for data in self._read do
    if data.opcode == 1 then
      local payload = json.decode(data.payload)
      if payload.opcode == 'playerUpdate' then
        self:emit('event', payload)
      elseif payload.opcode == 'stats' then
        payload.op = nil
        self._stats = payload
        print('UPDATED STATS')
      elseif payload.opcode == 'event' then
        self:emit('event', payload)
      end
    elseif data.opcode == 8 then -- CLOSE sent
    end
  end
  self:close()
end

-- Getters
function get.stats(self)
  return self._stats
end

return Node