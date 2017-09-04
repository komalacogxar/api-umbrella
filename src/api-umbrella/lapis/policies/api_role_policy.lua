local startswith = require("pl.stringx").startswith
local throw_authorization_error = require "api-umbrella.lapis.policies.throw_authorization_error"

local _M = {}

function _M.authorize_roles(current_admin, roles)
  assert(current_admin)
  assert(roles)

  if current_admin.superuser then
    return true
  end

  local disallowed_roles = {}
  for _, disallowed_role in ipairs(current_admin:disallowed_role_ids()) do
    disallowed_roles[disallowed_role] = true
  end

  for _, role in ipairs(roles) do
    if role ~= "api-umbrella-key-creator" and startswith(role, "api-umbrella") then
      return throw_authorization_error(current_admin)
    elseif disallowed_roles[role] then
      return throw_authorization_error(current_admin)
    end
  end

  return true
end

return _M
