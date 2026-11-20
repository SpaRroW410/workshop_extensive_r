-- Links to a page this track does not render are pointed into the track that owns it.
--
-- Each track renders only its own pages (scripts/build_profiles.R). So when, say, the Basic
-- track's Regression Analysis page links to regression-workshop/s2_simple_regression.qmd, that
-- page is not in docs/basic/. This filter rewrites the link to ../regression/regression-workshop/
-- s2_simple_regression.html (the sibling track site), using _filters/pages.json:
--   profiles: track -> pages it renders;   home: page -> the track that owns it.
-- On Cloudflare the gate then decides who may open it. Without a profile it does nothing.
local profile = os.getenv("QUARTO_PROFILE") or ""
local pages, home, here

local function load()
  if pages ~= nil then return pages ~= false end
  pages = false
  if profile == "" or not quarto.project or not quarto.project.directory then return false end
  local f = io.open(quarto.project.directory .. "/_filters/pages.json", "r")
  if not f then return false end
  local data = quarto.json.decode(f:read("a"))
  f:close()
  local list = data.profiles[profile]
  if not list then return false end
  pages = {}
  for _, p in ipairs(list) do pages[p] = true end
  home = data.home
  local input = quarto.doc.input_file or ""
  here = input:sub(#quarto.project.directory + 2)
  return true
end

-- "a/b/../c.qmd" -> "a/c.qmd"
local function normalise(path)
  local out = {}
  for part in path:gmatch("[^/]+") do
    if part == ".." then
      if #out == 0 then return nil end
      table.remove(out)
    elseif part ~= "." then
      table.insert(out, part)
    end
  end
  return table.concat(out, "/")
end

function Link(el)
  if not load() then return nil end
  local t = el.target
  if t:match("^%a[%w+.-]*:") or t:match("^//") or t:match("^#") or t:match("^/") then return nil end
  local path, rest = t:match("^([^#?]*)(.*)$")
  if not (path:match("%.qmd$") or path:match("%.html$")) then return nil end
  local dir = here:match("^(.*)/[^/]*$") or ""
  local key = normalise((dir ~= "" and (dir .. "/") or "") .. path)
  if not key then return nil end
  key = key:gsub("%.html$", ".qmd")
  if pages[key] then return nil end
  local owner = home[key]
  if type(owner) == "table" then owner = owner[1] end
  if type(owner) ~= "string" then return nil end
  local _, depth = here:gsub("/", "")
  el.target = string.rep("../", depth) .. "../" .. owner .. "/" .. key:gsub("%.qmd$", ".html") .. rest
  return el
end
