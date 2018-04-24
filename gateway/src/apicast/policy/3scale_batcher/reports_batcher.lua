local setmetatable = setmetatable
local ipairs = ipairs
local format = string.format
local insert = table.insert
local resty_lock = require 'resty.lock'

local _M = {}

local mt = { __index = _M }

-- TODO: Duplicated
local function creds_part_in_cached_auth_key(creds)
  -- TODO: Check right precedence
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

-- TODO: check possible problems with the key format. Escaping, etc.
local function key_for_batched_report(service_id, credentials, metric_name)
  local creds_part = creds_part_in_cached_auth_key(credentials)

  return format("service_id:%s,%s,metric:%s",
                service_id, creds_part, metric_name)
end

local function report_from_key_batched_report(key, value)
  local m = ngx.re.match(key, "service_id:(\\w+),user_key:(\\w+),metric:(\\w+)")

  if m and m[2] then
    return { service_id = m[1], user_key = m[2], metric = m[3], value = value }
  end

  m = ngx.re.match(key, "service_id:(\\w+),access_token:(\\w+),metric:(\\w+)")

  if m and m[2] then
    return { service_id = m[1], access_token = m[2], metric = m[3], value = value }
  end

  m = ngx.re.match(key, "service_id:(\\w+),app_id:(\\w+),app_key:(\\w+),metric:(\\w+)")

  if m and m[2] then
    return { service_id = m[1], app_id = m[2], app_key = m[3], metric = m[4], value = value }
  end

  -- TODO: err
end

-- Note: storage needs to implement shdict interface.
-- TODO: storage_name is only used for the lock. Better way of doing this?
function _M.new(storage, storage_name)
  local self = setmetatable({}, mt)
  self.storage = storage
  self.storage_name = storage_name
  return self
end

function _M:add(service_id, credentials, usage)
  local deltas = usage.deltas

  local lock, err = resty_lock:new(self.storage_name)
  -- TODO: err

  local elapsed, err = lock:lock(service_id)
  -- TODO: err

  for _, metric in ipairs(usage.metrics) do
    local key = key_for_batched_report(service_id, credentials, metric)
    self.storage:incr(key, deltas[metric], 0)
  end

  local ok, err = lock:unlock()
  -- TODO: err
end

-- TODO: make this more efficient. get_keys() could be slow in dicts with
-- lots of keys. Evaluate whether it's worth it to keep hash of changed keys.
function _M:get_all(service_id)
  local cached_reports = {}

  local cached_report_keys = self.storage:get_keys()

  local lock, err = resty_lock:new(self.storage_name)
  -- TODO: err

  local elapsed, err = lock:lock(service_id)
  -- TODO: err

  for _, key in ipairs(cached_report_keys) do
    local value = self.storage:get(key)

    local report = report_from_key_batched_report(key, value)

    if value and value > 0 and report.service_id == service_id then
      insert(cached_reports, report)
      self.storage:delete(key)
    end
  end

  local ok, err = lock:unlock()
  -- TODO: err

  return cached_reports
end

return _M
