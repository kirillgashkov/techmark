local element = {}

local mdFormat = "gfm-yaml_metadata_block"

---@param e { attr: pandoc.Attr }
---@return string|nil
function element.GetSource(e)
  return e.attr.attributes["data-pos"]
end

---@param e { attr: pandoc.Attr }
---@return nil
local function removeSource(e)
  e.attr.attributes["data-pos"] = nil
end

---@param e pandoc.Div | pandoc.Span
---@return boolean
local function isMerge(e)
  return e.attr.attributes["data-template--is-merge"] == "1"
end

---@param e pandoc.Div | pandoc.Span
---@return boolean
local function isRedundant(e)
  if e.attr.identifier ~= "" then
    return false
  end
  if #e.attr.classes > 0 then
    return false
  end
  for _ in pairs(e.attr.attributes) do
    return false
  end
  if #e.content > 1 then
    return false
  end
  return true
end

---@param inlines pandoc.Inlines
---@return pandoc.Inline
function element.Merge(inlines)
  local i = pandoc.Span(inlines)
  i.attr.attributes["data-template--is-merge"] = "1"
  return i
end

---@param blocks pandoc.Blocks
---@return pandoc.Block
function element.MergeBlock(blocks)
  local b = pandoc.Div(blocks)
  b.attr.attributes["data-template--is-merge"] = "1"
  return b
end

---@param s string
---@return pandoc.Inline
function element.Raw(s)
  return pandoc.RawInline("latex", s)
end

---@param s string
---@return pandoc.Inline
function element.Md(s)
  return element.Merge(pandoc.utils.blocks_to_inlines(pandoc.read(s, mdFormat).blocks))
end

---@param s string
---@return pandoc.Block
function element.MdBlock(s)
  return element.MergeBlock(pandoc.read(s, mdFormat).blocks)
end

---@param document pandoc.Pandoc
---@return pandoc.Pandoc
function element.RemoveMerges(document)
  return document:walk({
    ---@param d pandoc.Div
    ---@return pandoc.Div | pandoc.Blocks
    Div = function(d)
      if isMerge(d) then
        return d.content
      end
      return d
    end,

    ---@param s pandoc.Span
    ---@return pandoc.Span | pandoc.Inlines
    Span = function(s)
      if isMerge(s) then
        return s.content
      end
      return s
    end,
  })
end

---Creates redundant Divs and Spans.
---@param document pandoc.Pandoc
---@return pandoc.Pandoc
function element.RemoveSources(document)
  return document:walk({
    ---@param b pandoc.Block
    ---@return pandoc.Block
    Block = function(b)
      if b["attr"] ~= nil then
        removeSource(b)
      end
      return b
    end,

    ---@param i pandoc.Inline
    ---@return pandoc.Inline
    Inline = function(i)
      if i["attr"] ~= nil then
        removeSource(i)
      end
      return i
    end,
  })
end

---@param document pandoc.Pandoc
---@return pandoc.Pandoc
function element.RemoveRedundants(document)
  return document:walk({
    ---@param d pandoc.Div
    ---@return pandoc.Div | pandoc.Blocks
    Div = function(d)
      if isRedundant(d) then
        return d.content
      end
      return d
    end,

    ---@param s pandoc.Span
    ---@return pandoc.Span | pandoc.Inlines
    Span = function(s)
      if isRedundant(s) then
        return s.content
      end
      return s
    end,
  })
end

return element
