local M = {}

local READ_ONLY = {
  read_file = true,
  list_dir = true,
  grep = true,
}

local state = { active = false, asking = false, allow = {} }

-- Plan mode does not try to decide whether a command is safe. There is no
-- sandbox behind it, so any list here would be advice, not a boundary -- and
-- no list of "safe" commands stays correct for long. The user classifies,
-- through the confirmation prompt.
--
-- opts.allow only skips that prompt for commands you nominate. It is there to
-- cut prompt fatigue, NOT to make anything safe. Do not "harden" it.
local function nominated(cmd)
  if type(cmd) ~= "string" then
    return false
  end
  for _, prefix in ipairs(state.allow) do
    if cmd == prefix or string.sub(cmd, 1, #prefix + 1) == prefix .. " " then
      return true
    end
  end
  return false
end

local DENY = "Plan mode is on: no edits yet. Investigate with read_file, "
  .. "list_dir and grep, and run commands when you need to -- each one is put "
  .. "to the user for approval. Then reply with a numbered plan. The user will "
  .. "approve it before you change anything."

local ASK = "Run this while planning?"

local ACCEPT = "Accept and execute"
local KEEP = "Keep planning"
local CANCEL = "Leave plan mode"

local function banner()
  uji.emit("status_changed", {})
end

function M.active()
  return state.active
end

function M.decide(tool, args)
  if not state.active then
    return nil
  end
  if READ_ONLY[tool] then
    return { allow = true }
  end
  if tool == "run_command" then
    if nominated(args and args.command) then
      return { allow = true }
    end
    return { ask = ASK }
  end
  return { deny = DENY }
end

function M.enter()
  state.active = true
  state.asking = false
  banner()
end

function M.leave()
  state.active = false
  state.asking = false
  banner()
end

local function last_plan()
  local messages = uji.session.messages()
  for i = #messages, 1, -1 do
    if messages[i].type == "assistant" and messages[i].text ~= "" then
      return messages[i].text
    end
  end
  return nil
end

function M.approve()
  M.leave()
  uji.session.submit("Approved. Execute the plan you just described.")
end

-- Offer the choice as soon as a planning turn ends, so the plan does not just
-- sit there waiting for the user to remember /approve.
local function ask_to_accept()
  if not state.active or state.asking then
    return
  end
  if not last_plan() then
    return
  end
  state.asking = true
  uji.ui.select({
    title = "Plan ready",
    items = { ACCEPT, KEEP, CANCEL },
  }, function(choice)
    state.asking = false
    if choice == ACCEPT then
      M.approve()
    elseif choice == CANCEL then
      M.leave()
      uji.notify("plan mode off")
    end
    -- KEEP, or dismissed: stay in plan mode and let the user keep talking
  end)
end

function M.setup(opts)
  opts = opts or {}
  state.allow = opts.allow or {}

  uji.agent.context("plan", function()
    if not state.active then return nil end
    return [[# Plan mode

Plan mode is active. Edits are blocked and will be denied if you attempt them.
Read freely with read_file, list_dir and grep. You may also run commands --
cargo check, git diff, whatever you need -- and the user is asked to approve
each one, so keep them few and purposeful.

Investigate the task, then reply with a short numbered plan naming the files
you would change and what you would change in them. Do not write code yet.
The user will approve the plan before anything runs.]]
  end, { priority = 10 })

  uji.status.add("plan", function()
    if not state.active then return nil end
    return { text = " PLAN ", color = "black", bg = "yellow", bold = true }
  end, { priority = 5 })

  uji.on("tool_call", function(event)
    return M.decide(event.name, event.arguments)
  end, { priority = opts.priority or 10 })

  if opts.confirm ~= false then
    uji.on("turn_finished", ask_to_accept)
  end

  uji.command("plan", function(args)
    if state.active then
      M.leave()
      uji.notify("plan mode off")
      return
    end
    M.enter()
    if args ~= "" then
      uji.session.submit("Plan only, do not edit anything yet: " .. args)
    else
      uji.notify("plan mode on — describe what you want planned")
    end
  end)

  uji.command("approve", function()
    if not state.active then
      uji.notify("not in plan mode")
      return
    end
    if not last_plan() then
      uji.notify("no plan to approve yet")
      return
    end
    M.approve()
  end)

  if opts.keys ~= false then
    uji.keymap.set("normal", "<C-b>", { command = "plan" })
  end
end

return M
