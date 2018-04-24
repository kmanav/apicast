local backend_client = require('apicast.backend_client')
local AuthsCache = require('auths_cache')
local ReportsBatcher = require('reports_batcher')
local ReportsBatch = require('reports_batch')
local policy = require('apicast.policy')
local http_ng_resty = require('resty.http_ng.backend.resty')
local semaphore = require('ngx.semaphore')

local pairs = pairs
local ipairs = ipairs
local next = next

local default_auths_ttl = 10
local default_batch_reports_seconds = 10

local _M = policy.new('Caching policy')

local new = _M.new

function _M.new(config)
  local self = new(config)

  local auths_ttl = config.auths_ttl or default_auths_ttl
  self.auths_cache = AuthsCache.new(ngx.shared.cached_auths, auths_ttl)

  self.reports_batcher = ReportsBatcher.new(
    ngx.shared.batched_reports, 'batched_reports')

  self.batch_reports_seconds = config.batch_reports_seconds or
                               default_batch_reports_seconds

  self.report_timer_on = false

  self.report_timer_on = false
  self.semaphore_report_timer = semaphore.new(1)

  return self
end

-- TODO: avoid duplicating this. It's also in proxy.lua
-- Converts a usage to the format expected by the 3scale backend client.
local function format_usage(usage)
  local res = {}

  local usage_metrics = usage.metrics
  local usage_deltas = usage.deltas

  for _, metric in ipairs(usage_metrics) do
    local delta = usage_deltas[metric]
    res['usage[' .. metric .. ']'] = delta
  end

  return res
end

-- TODO: avoid duplicating this. It's also in proxy.lua
local function error_authorization_failed(service)
  ngx.log(ngx.INFO, 'authorization failed for service ', service.id)
  ngx.var.cached_key = nil
  ngx.status = service.auth_failed_status
  ngx.header.content_type = service.auth_failed_headers
  ngx.print(service.error_auth_failed)
  return ngx.exit(ngx.HTTP_OK)
end

local function set_flags_to_avoid_auths_in_apicast(context)
  context.skip_apicast_access = true
  context.skip_apicast_post_action = true
end

local function report(_, service_id, backend_client, reports_batcher)
  local reports = reports_batcher:get_all(service_id)
  local batch = ReportsBatch.new(service_id, reports)
  backend_client:report(batch)
end

function _M:access(context)
  local backend = backend_client:new(context.service, http_ng_resty)
  local usage = context.usage
  local service = context.service
  local service_id = service.id
  local credentials = context.credentials

  -- This starts a timer on each worker.
  local check_timer, err = self.semaphore_report_timer:wait(0)

  if check_timer then
    if not self.report_timer_on then
      ngx.timer.every(self.batch_reports_seconds, report,
        service_id, backend, self.reports_batcher)

      self.report_timer_on = true
    end

    self.semaphore_report_timer:post()
  end

  local cached_auth = self.auths_cache:get(service_id, credentials, usage)

  if not cached_auth then
    local formatted_usage = format_usage(usage)
    local backend_res = backend:authorize(formatted_usage, credentials)
    local backend_status = backend_res.status

    if backend_status == 200 then
      self.auths_cache:set(service_id, credentials, usage, 200)
      self.reports_batcher:add(service_id, credentials, usage)
    elseif backend_status < 500 or backend_status > 599 then
      self.auths_cache:set(service_id, credentials, usage, backend_status)

      -- TODO: generic error for now.
      return error_authorization_failed(service)
    else
      -- TODO: Error while contacting backend. Don't cache. Return error.
    end
  else
    if cached_auth == 200 then
      self.reports_batcher:add(service_id, credentials, usage)
    else
      -- TODO: generic error for now.
      return error_authorization_failed(service)
    end
  end

  set_flags_to_avoid_auths_in_apicast(context)
end

-- TODO:
-- - Error handling everywhere.
-- - Implement mechanism to avoid performing at the same time the same auth
--   query multiple times. Just for efficiency, not correctness.
-- - Avoid doing several reports at the same time. Might not be needed.
--   The max number of parallel reports would equal the number of workers which
--   is typically not that high. Just for efficiency, not correctness.
-- - Assume user_key for now. Add the rest of credentials modes later.
-- - When not auth, distinguish type of error (rate limits, keys, etc.)

return _M
