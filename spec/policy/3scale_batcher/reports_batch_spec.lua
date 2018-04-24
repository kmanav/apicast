local ReportsBatch = require 'apicast.policy.3scale_batcher.reports_batch'
local insert = table.insert
local pairs = pairs

describe('reports batch', function()
  local reports_with_user_key = {
    { user_key = 'uk1', metric = 'm1', value = 1 },
    { user_key = 'uk2', metric = 'm2', value = 2 }
  }

  local reports_with_app_id = {
    { app_id = 'id1', metric = 'm1', value = 1 },
    { app_id = 'id2', metric = 'm2', value = 2 }
  }

  local reports_with_access_token = {
    { access_token = 't1', metric = 'm1', value = 1 },
    { access_token = 't2', metric = 'm2', value = 2 }
  }

  local all_reports = {}
  for _, report in pairs(reports_with_user_key) do insert(all_reports, report) end
  for _, report in pairs(reports_with_app_id) do insert(all_reports, report) end
  for _, report in pairs(reports_with_access_token) do insert(all_reports, report) end

  describe('.by_user_key', function()
    it('return the reports that have a user key', function()
      local batch = ReportsBatch.new('s1', all_reports)

      local expected = { uk1 = { m1 = 1 }, uk2 = { m2 = 2 } }
      assert.same(expected, batch.by_user_key)
    end)
  end)

  describe('.by_app_id', function()
    it('returns the reports that have an app ID', function()
      local batch = ReportsBatch.new('s1', all_reports)

      local expected = { id1 = { m1 = 1 }, id2 = { m2 = 2 } }
      assert.same(expected, batch.by_app_id)
    end)
  end)

  describe('.by_access_token', function()
    it('returns the reports that have an access token', function()
      local batch = ReportsBatch.new('s1', all_reports)

      local expected = { t1 = { m1 = 1 }, t2 = { m2 = 2 } }
      assert.same(expected, batch.by_access_token)
    end)
  end)
end)
