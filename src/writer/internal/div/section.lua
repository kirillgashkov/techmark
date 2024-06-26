local function has_value(arr, val)
  for _, value in ipairs(arr) do
    if value == val then
      return true
    end
  end
  return false
end

local function get_keys(tab)
  local keys = {}
  for key, _ in pairs(tab) do
    table.insert(keys, key)
  end
  return keys
end

local function with_section_identifier_moved_to_header(
  section -- pandoc.Div
)
  local new_section = section:clone()

  for _, block in ipairs(new_section.content) do
    if block.t == "Header" then
      block.identifier = new_section.identifier
      new_section.identifier = ""
      break
    end
  end

  return new_section
end

local function render_main_section(
  section -- pandoc.Div
)
  local blocks = pandoc.Blocks({})

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\begin{scholar@section@main}",
      "\\makeatother",
    }, "")
  ))

  blocks:extend(with_section_identifier_moved_to_header(section).content)

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\end{scholar@section@main}",
      "\\makeatother",
    }, "")
  ))

  return blocks
end

local function render_contents_section(
  section -- pandoc.Div
)
  local blocks = pandoc.Blocks({})

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\begin{scholar@section@contents}",
      "\\makeatother",
    }, "")
  ))

  blocks:extend(with_section_identifier_moved_to_header(section).content)

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\end{scholar@section@contents}",
      "\\makeatother",
    }, "")
  ))

  return blocks
end

local function render_side_section(
  section -- pandoc.Div
)
  local blocks = pandoc.Blocks({})

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\begin{scholar@section@side}",
      "\\makeatother",
    }, "")
  ))

  blocks:extend(with_section_identifier_moved_to_header(section).content)

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\end{scholar@section@side}",
      "\\makeatother",
    }, "")
  ))

  return blocks
end

local function render_appendix_section(
  section -- pandoc.Div
)
  local blocks = pandoc.Blocks({})

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\begin{scholar@section@appendix}",
      "\\makeatother",
    }, "")
  ))

  blocks:extend(with_section_identifier_moved_to_header(section).content)

  blocks:insert(pandoc.RawBlock(
    "latex",
    table.concat({
      "\\makeatletter",
      "\\end{scholar@section@appendix}",
      "\\makeatother",
    }, "")
  ))

  return blocks
end

local section_renderers = {
  ["main"] = render_main_section,
  ["contents"] = render_contents_section,
  ["side"] = render_side_section,
  ["appendix"] = render_appendix_section,
}

local function is_section_div(
  div -- pandoc.Div
)
  return has_value(div.classes, "section")
end

local function render_section(
  section -- pandoc.Div
)
  local section_types = get_keys(section_renderers)
  local section_type = nil
  for _, class in ipairs(section.classes) do
    if has_value(section_types, class) then
      if section_type ~= nil then
        warn("Multiple section types specified. Using the last one.")
      end
      section_type = class
    end
  end

  if section_type == nil then
    section_type = "main"
  end

  return section_renderers[section_type](section)
end

-- FIXME: REFACTOR
-- return {
--   {
--     Pandoc = function(
--       doc -- pandoc.Pandoc
--     )
--       return pandoc.Pandoc(
--         -- Creates Divs beginning at each Header and containing
--         -- following content until the next Header of comparable level.
--         --
--         -- Each created Div gets a ".section" class and its header's
--         -- classes and identifiers. Also the identifier is moved from
--         -- the header to the Div. We will put it back later.
--         pandoc.utils.make_sections(false, nil, doc.blocks),
--         doc.meta
--       )
--     end,
--   },
-- }

local div = {}

---@param e pandoc.Div
---@return any
function div.MakeSectionLatex(e)
  if is_section_div(e) then
    return render_section(e)
  end
  return e
end

return div
