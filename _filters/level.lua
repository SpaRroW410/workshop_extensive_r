-- ::: {when-level="moderate"}  -> shown in that level and every level above it
local order = { basic = 1, moderate = 2, regression = 3, advanced = 4 }
local prof = os.getenv("QUARTO_PROFILE") or ""
local cur = order[prof]
function Div(el)
  local want = el.attributes["when-level"]
  if want == nil then return nil end
  local need = order[want]
  -- profiles outside the main ladder (e.g. dataviz-*) are not filtered: show everything
  if cur == nil or need == nil or cur >= need then
    el.attributes["when-level"] = nil
    return el
  end
  return {}
end
