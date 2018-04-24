local setmetatable = setmetatable
local ipairs = ipairs
local format = string.format
local insert = table.insert
local concat = table.concat
local sort = table.sort
local unpack = table.unpack

local _M = {}

local mt = { __index = _M }

local function creds_part_in_cached_auth_key(creds)
  if creds.app_id and creds.app_key then
    return format("app_id:%s,app_key:%s", creds.app_id, creds.app_key)
  elseif creds.user_key then
    return format("user_key:%s", creds.user_key)
  elseif creds.access_token then
    return format("access_token:%s", creds.access_token)
  else
    -- TODO: error unknow creds
  end
end

local function metrics_part_in_cached_auth_key(usage)
  local usages = {}

  local deltas = usage.deltas

  -- Need to sort the metrics. Otherwise, same metrics but in different order,
  -- would end up in a different key.
  local metrics = { unpack(usage.metrics) } -- Does not modify the original.
  sort(metrics)

  for _, metric in ipairs(metrics) do
    insert(usages, format("%s=%s", metric, deltas[metric]))
  end

  return format("metrics:%s", concat(usages, ';'))
end

-- TODO: check possible problems with the key format. Escaping, etc.
local function key_for_cached_auth(service_id, credentials, usage)
  local service_part = format("service_id:%s", service_id)
  local creds_part = creds_part_in_cached_auth_key(credentials)
  local metrics_part = metrics_part_in_cached_auth_key(usage)

  return format("%s,%s,%s", service_part, creds_part, metrics_part)
end

-- Note: storage needs to implement shdict interface.
function _M.new(storage, ttl)
  local self = setmetatable({}, mt)
  self.storage = storage
  self.ttl = ttl
  return self
end

function _M:get(service_id, credentials, usage)
  local key = key_for_cached_auth(service_id, credentials, usage)
  return self.storage:get(key)
end

function _M:set(service_id, credentials, usage, auth_status)
  local key = key_for_cached_auth(service_id, credentials, usage)
  self.storage:set(key, auth_status, self.ttl)
end

return _M
