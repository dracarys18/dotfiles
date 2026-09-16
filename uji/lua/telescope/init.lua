
local M = {}

local configured_editor = nil

local function editor()
  return configured_editor
    or os.getenv("UJI_EDITOR")
    or os.getenv("VISUAL")
    or os.getenv("EDITOR")
end

function M.open(path)
  local cmd = editor()
  if not cmd or cmd == "" then
    uji.notify("no editor: set $EDITOR, or pass editor = \"nvim\" to telescope.setup")
    return
  end
  uji.ui.exec({ cmd = { "sh", "-c", cmd .. ' "$1"', "sh", path } })
end

local function attach(path)
  local current = uji.input.get()
  local sep = (current == "" or current:sub(-1) == " ") and "" or " "
  uji.input.set(current .. sep .. "@" .. path .. " ")
end

local FIND = "rg --files --hidden --glob '!.git' 2>/dev/null"
  .. " || find . -type f -not -path '*/.git/*'"

local function collect(cmd, on_done)
  local lines = {}
  uji.job.start({
    cmd = cmd,
    on_stdout = function(line) lines[#lines + 1] = line end,
    on_exit = function() on_done(lines) end,
  })
end

function M.files(on_done)
  collect(FIND, on_done)
end

function M.grep(pattern, on_done)
  local escaped = pattern:gsub("'", "'\\''")
  collect("rg --line-number --no-heading --smart-case '" .. escaped .. "' | head -500", on_done)
end

function M.branches(on_done)
  collect("git branch --all --format='%(refname:short)'", on_done)
end

local function pick(title, items, on_choice, preview)
  if #items == 0 then
    uji.notify("nothing to pick")
    return
  end
  uji.ui.pick({ title = title, items = items, preview = preview }, function(choice)
    if choice then on_choice(choice) end
  end)
end

-- Live search: each settled keystroke re-runs ripgrep. `token` ties the results
-- to the query that asked for them, so a slow search cannot overwrite a newer one.
local function live_grep()
  uji.ui.pick({
    title = "Search",
    on_query = function(query, token)
      if query == "" then
        uji.ui.pick_items({}, token)
        return
      end
      local escaped = query:gsub("'", "'\\''")
      local hits = {}
      uji.job.start({
        cmd = "rg --line-number --no-heading --smart-case '" .. escaped .. "' | head -200",
        on_stdout = function(line) hits[#hits + 1] = line end,
        on_exit = function() uji.ui.pick_items(hits, token) end,
      })
    end,
  }, function(choice)
    if choice then M.open(choice:match("^([^:]+):") or choice) end
  end)
end

function M.setup(opts)
  opts = opts or {}
  configured_editor = opts.editor

  uji.action.set("telescope_search", live_grep)

  uji.command("find", function()
    M.files(function(files) pick("Open file", files, M.open) end)
  end)

  uji.command("attach", function()
    M.files(function(files) pick("Attach file", files, attach) end)
  end)

  uji.command("grep", function(args)
    if args == "" then
      live_grep()
      return
    end
    M.grep(args, function(hits)
      pick("Grep: " .. args, hits, function(hit)
        M.open(hit:match("^([^:]+):") or hit)
      end)
    end)
  end)

  uji.command("branch", function()
    M.branches(function(branches)
      pick("Git branches", branches, function(branch)
        uji.session.submit("Summarise what changed on branch " .. branch)
      end)
    end)
  end)

  -- Search the whole transcript, not only what you typed: the thing you are
  -- looking for is often in a tool result or a reply.
  uji.command("history", function()
    local items, full = {}, {}
    for _, message in ipairs(uji.session.messages()) do
      local text = (message.text or ""):gsub("%s+", " ")
      if text ~= "" then
        local label = message.type .. ": " .. text
        items[#items + 1] = label
        full[label] = message.text
      end
    end
    pick("Session history", items, function(label)
      uji.input.set(full[label] or label)
    end, function(label)
      local body = full[label] or label
      local lines = {}
      for line in body:gmatch("[^\n]+") do lines[#lines + 1] = line end
      return lines
    end)
  end)

  if opts.keys ~= false then
    uji.keymap.set("normal", "<C-p>", { command = "find" })
    uji.keymap.set("normal", "<C-a>", { command = "attach" })
    uji.keymap.set("normal", "<C-g>", { command = "branch" })
    uji.keymap.set("normal", "<C-r>", { command = "history" })
    uji.keymap.set("normal", "<C-f>", "telescope_search")
  end
end

return M
