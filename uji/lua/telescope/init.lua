
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

local function pick(title, items, on_choice)
  if #items == 0 then
    uji.notify("nothing to pick")
    return
  end
  uji.ui.select({ title = title, items = items }, function(choice)
    if choice then on_choice(choice) end
  end)
end

function M.setup(opts)
  opts = opts or {}
  configured_editor = opts.editor

  uji.command("find", function()
    M.files(function(files) pick("Open file", files, M.open) end)
  end)

  uji.command("attach", function()
    M.files(function(files) pick("Attach file", files, attach) end)
  end)

  uji.command("grep", function(args)
    if args == "" then
      uji.notify("usage: /grep <pattern>")
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

  uji.command("history", function()
    local items = {}
    for _, message in ipairs(uji.session.messages()) do
      if message.type == "user" then
        items[#items + 1] = message.text:gsub("\n", " ")
      end
    end
    pick("Session history", items, function(text) uji.input.set(text) end)
  end)

  if opts.keys ~= false then
    uji.keymap.set("normal", "<C-p>", { command = "find" })
    uji.keymap.set("normal", "<C-a>", { command = "attach" })
    uji.keymap.set("normal", "<C-g>", { command = "branch" })
    uji.keymap.set("normal", "<C-r>", { command = "history" })
  end
end

return M
