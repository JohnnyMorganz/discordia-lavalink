local http = require('coro-http')
local json = require('json')
local querystring = require('querystring')
local discordia = require('discordia')
local class = discordia.class

local API = class('LavalinkAPI')

local format = string.format

function API:__init(manager)
  self._manager = manager
end

function API:_request(identifier)
  local node = self._manager._nodes[next(self._manager._nodes)]
  if not node then return nil, 'No node available to use' end

  local query = querystring.stringify({
    identifier = identifier
  })

  local res, body = http.request('GET', format('http://%s:%s/loadtracks?%s', node._host, node._port, query), {
    {'Authorization', node._password}
  })

  if res.code == 200 then
    return json.decode(body)
  else
    return nil, body
  end
end

function API:get(id)
  local body, err = self:_request(id)
  if body then
    if body.tracks then
      return body.tracks
    else
      return nil, 'Unable to find any tracks'
    end
  else
    return nil, err
  end
end

-- Helper Functions --
function API:searchYTSongs(search)
  return self:get(format('ytsearch:%s', search))
end

return API