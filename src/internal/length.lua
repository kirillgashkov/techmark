local log = require("internal.log")
local fun = require("internal.fun")

local element = require("internal.element")
local merge = element.Merge
local raw = element.Raw

local length = {}

---@param v number
---@return pandoc.Inline
local function makeNumberLatex(v)
  return raw(tostring(string.format("%.4f", v):gsub("%.?0+$", "")))
end

---@param a length
---@param b length
---@return length
function length.Add(a, b)
  local c = {}
  for u, v in pairs(a) do
    c[u] = v
  end
  for u, v in pairs(b) do
    c[u] = (c[u] or 0) + v
  end
  return c
end

---@param a length
---@param b length
---@return length
function length.Subtract(a, b)
  local c = {}
  for u, v in pairs(a) do
    c[u] = v
  end
  for u, v in pairs(b) do
    c[u] = (c[u] or 0) - v
  end
  return c
end

---@param a length
---@param b length
---@return boolean
function length.IsEqual(a, b)
  local units = {}
  for u, _ in pairs(a) do
    units[u] = true
  end
  for u, _ in pairs(b) do
    units[u] = true
  end
  for u, _ in pairs(units) do
    local av = a[u] or 0
    local bv = b[u] or 0
    if av ~= bv then
      return false
    end
  end
  return true
end

---@return length
function length.Zero()
  return {}
end

---@param l length
---@return boolean
function length.IsZero(l)
  return length.IsEqual(l, length.Zero())
end

---@param u string
local function makeUnitRegex(u)
  return re.compile([[ { %d+ ( "." %d+ )? } "]] .. u .. [[" ]])
end

local unitRegexes = {}
for _, u in ipairs({ "pt", "%" }) do
  unitRegexes[u] = makeUnitRegex(u)
end

---Returns nil if the string is not a valid length.
---@param s string
---@return length | nil
function length.Parse(s)
  for u, r in pairs(unitRegexes) do
    local v = r:match(s)
    if v then
      return { [u] = tonumber(v) }
    end
  end
  return nil
end

---@param l length
---@return pandoc.Inline
function length.MakeWidthLatex(l)
  local toAdd = pandoc.Inlines({})
  local toSubtract = pandoc.Inlines({})

  for u, v in pairs(l) do
    local component
    if u == "pt" then
      component = merge({ makeNumberLatex(math.abs(v)), raw("pt") })
    elseif u == "%" then
      component = merge({ makeNumberLatex(math.abs(v / 100)), raw([[\textwidth]]) })
    else
      log.Error("unsupported width unit: " .. u)
      assert(false)
    end

    if v > 0 then
      toAdd:insert(component)
    elseif v < 0 then
      toSubtract:insert(component)
    end
  end

  if #toAdd == 0 and #toSubtract == 0 then
    return raw("0pt")
  end

  return merge({
    #toAdd + #toSubtract > 1 and merge({ raw([[\dimexpr]]), raw([[(]]) }) or merge({}),
    #toAdd > 0 and merge(fun.Intersperse(toAdd, raw(" + "))) or merge({}),
    #toSubtract > 0 and merge({ raw(" - "), merge(fun.Intersperse(toSubtract, raw(" - "))) }) or merge({}),
    #toAdd + #toSubtract > 1 and merge({ raw([[)]]), raw([[\relax]]) }) or merge({}),
  })
end

---@param l length
---@return pandoc.Inline
function length.MakeHeightLatex(l)
  return length.MakeLatex(l)
end

---@param l length
---@return pandoc.Inline
function length.MakeLatex(l)
  local toAdd = pandoc.Inlines({})
  local toSubtract = pandoc.Inlines({})

  for u, v in pairs(l) do
    local component
    if u == "pt" then
      component = merge({ makeNumberLatex(math.abs(v)), raw("pt") })
    else
      log.Error("unsupported width unit: " .. u)
      assert(false)
    end

    if v > 0 then
      toAdd:insert(component)
    elseif v < 0 then
      toSubtract:insert(component)
    end
  end

  if #toAdd == 0 and #toSubtract == 0 then
    return raw("0pt")
  end

  return merge({
    #toAdd > 0 and merge(fun.Intersperse(toAdd, raw(" + "))) or merge({}),
    #toSubtract > 0 and merge({ raw(" - "), merge(fun.Intersperse(toSubtract, raw(" - "))) }) or merge({}),
  })
end

return length
