local setmetatable = setmetatable
local ipairs = ipairs

local _M = {}

local mt = { __index = _M }

local function add_value(reports, credential, metric, value)
  reports[credential] = reports[credential] or {}
  reports[credential][metric] = reports[credential][metric] or 0
  reports[credential][metric] = reports[credential][metric] + value
end

local function classify_by_user_key(reports)
  local res = {}

  for _, report in ipairs(reports) do
    if report.user_key then
      add_value(res, report.user_key, report.metric, report.value)
    end
  end

  return res
end

local function classify_by_app_id_and_key(reports)
  local res = {}

  for _, report in ipairs(reports) do
    if report.app_id then
      add_value(res, report.app_id, report.metric, report.value)
    end
  end

  return res
end

local function classify_by_access_token(reports)
  local res = {}

  for _, report in ipairs(reports) do
    if report.access_token then
      add_value(res, report.access_token, report.metric, report.value)
    end
  end

  return res
end

function _M.new(service_id, reports)
  local self = setmetatable({}, mt)

  self.service_id = service_id

  self.by_user_key = classify_by_user_key(reports)
  self.by_app_id = classify_by_app_id_and_key(reports)
  self.by_access_token = classify_by_access_token(reports)

  return self
end

return _M
