local M = {}

local DIM = "#4a4a4a"
local MUTED = "#808080"

local state = { win = nil, sep = "  ·  " }

local function compact(n)
  local value, unit = n, ""
  if n >= 1000000 then
    value, unit = n / 1000000, "M"
  elseif n >= 1000 then
    value, unit = n / 1000, "k"
  else
    return tostring(n)
  end
  return (string.format("%.1f", value):gsub("%.0$", "")) .. unit
end

local function shorten(path)
  local home = os.getenv("HOME")
  if home and home ~= "" and path:sub(1, #home) == home then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

function M.render()
  if not state.win then return end
  local parts = uji.status.segments()
  if #parts == 0 then
    uji.ui.clear(state.win)
    return
  end
  local spans = { { text = " ", color = DIM } }
  for i, part in ipairs(parts) do
    if i > 1 then
      spans[#spans + 1] = { text = state.sep, color = DIM }
    end
    spans[#spans + 1] = part
  end
  uji.ui.set_lines(state.win, { spans })
end

local function defaults()
  uji.status.add("cwd", function()
    local dir = shorten(uji.session.info().directory or "")
    if dir == "" then return nil end
    return { text = dir, color = "cyan" }
  end, { priority = 10 })

  uji.status.add("model", function()
    local provider = uji.status.provider()
    if not provider then return nil end
    return { text = provider .. "/" .. uji.status.model(), color = MUTED }
  end, { priority = 20 })

  uji.status.add("effort", function()
    local effort = uji.status.effort()
    if not effort then return nil end
    return { text = "think " .. effort, color = MUTED }
  end, { priority = 22 })

  uji.status.add("context", function()
    local ctx = uji.status.context()
    if not ctx.window or ctx.window == 0 then return nil end
    local pct = math.floor(ctx.used / ctx.window * 100 + 0.5)
    return {
      text = string.format("%s/%s ctx (%d%%)", compact(ctx.used), compact(ctx.window), pct),
      color = pct >= 80 and "yellow" or MUTED,
    }
  end, { priority = 25 })

  uji.status.add("tokens", function()
    local usage = uji.session.usage()
    if usage.total == 0 then return nil end
    return { text = compact(usage.total) .. " tok", color = MUTED }
  end, { priority = 26 })

  uji.status.add("cache", function()
    local usage = uji.session.usage()
    local read = usage.cache_read or 0
    local prefix = usage.input + read + (usage.cache_write or 0)
    if read == 0 or prefix == 0 then return nil end
    return {
      text = string.format("cache %d%%", math.floor(read / prefix * 100 + 0.5)),
      color = MUTED,
    }
  end, { priority = 27 })

  uji.status.add("turns", function()
    local turns = 0
    for _, message in ipairs(uji.session.messages()) do
      if message.type == "user" then turns = turns + 1 end
    end
    if turns == 0 then return nil end
    return { text = turns .. (turns == 1 and " turn" or " turns"), color = MUTED }
  end, { priority = 30 })
end

function M.setup(opts)
  opts = opts or {}
  state.sep = opts.separator or state.sep
  state.win = opts.win
    or uji.ui.open_win({
      split = opts.split or "bottom",
      size = 1,
      priority = opts.priority or 10,
    })
  if opts.defaults ~= false then
    defaults()
  end
  uji.on("status_changed", M.render)
  uji.on("MessageAppended", M.render)
  M.render()
end

return M
