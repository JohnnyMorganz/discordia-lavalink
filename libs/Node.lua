local discordia = require('discordia')
local websocket = require('coro-websocket')
local json = require('json')

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

  self._ready = false
  self._connected = false
  self._res = nil
  self._read = nil
  self._write = nil
  self._reconnect = nil
  self._reconnectInterval = options.reconnectInterval or 15000
  self._stats = {}

  coroutine.wrap(self.connect)(self)
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
    self:_onReady()
    self:_handleData()
    return true
  end
  error(format('Unable to connect to Lavalink: %s', read))
end

function Node:close()

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
  self:removeAllListeners('event')
  self:close()
end

function Node:_onReady()
  self._ready = true
end

function Node:_onClose()
  self._connected = false
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
end

-- Getters
function get.stats(self)
  return self._stats
end

return Node