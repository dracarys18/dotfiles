-- Durable task list.
--
-- The list lives in this module, not in the message stream, so compaction
-- cannot lose it. uji.agent.context re-injects it into the system prompt on
-- every turn, which means the model still sees its remaining work after the
-- transcript it was written in has been summarised away.
--
-- Copy to ~/.config/uji/plugin/todo.lua to enable.

local STATUS = { pending = " ", doing = "~", done = "x" }
local ORDER = { doing = 1, pending = 2, done = 3 }

local items = {}

local function render()
    if #items == 0 then
        return {}
    end
    local lines = {}
    for _, item in ipairs(items) do
        lines[#lines + 1] = string.format("[%s] %s", STATUS[item.status] or " ", item.text)
    end
    return lines
end

local function counts()
    local done, total = 0, #items
    for _, item in ipairs(items) do
        if item.status == "done" then
            done = done + 1
        end
    end
    return done, total
end

uji.tool.register("todo", {
    description = "Record and update the task list for the current piece of work. "
        .. "Send the complete list every time; it replaces the previous one. "
        .. "Use it for multi-step work so nothing is dropped, and mark items done as you finish them.",
    subject = "task list",
    parameters = {
        type = "object",
        properties = {
            items = {
                type = "array",
                description = "The full task list, in order.",
                items = {
                    type = "object",
                    properties = {
                        text = { type = "string", description = "What needs doing." },
                        status = {
                            type = "string",
                            enum = { "pending", "doing", "done" },
                            description = "Current state of this task.",
                        },
                    },
                    required = { "text", "status" },
                },
            },
        },
        required = { "items" },
    },
    run = function(args)
        local next_items = {}
        for _, item in ipairs(args.items or {}) do
            if type(item.text) == "string" and item.text ~= "" then
                next_items[#next_items + 1] = {
                    text = item.text,
                    status = STATUS[item.status] and item.status or "pending",
                }
            end
        end
        table.sort(next_items, function(a, b)
            return (ORDER[a.status] or 9) < (ORDER[b.status] or 9)
        end)
        items = next_items
        local done, total = counts()
        local lines = render()
        if total == 0 then
            return "Task list cleared."
        end
        return string.format("Task list (%d/%d done):\n%s", done, total, table.concat(lines, "\n"))
    end,
})

-- Unknown tools default to "ask". This one only rewrites the list above, so
-- confirming every update would be pure friction.
uji.on("tool_call", function(event)
    if event.name == "todo" then
        return { allow = true }
    end
    return nil
end, { priority = 10 })

-- Survives compaction: rebuilt into the system prompt every turn.
uji.agent.context("todo", function()
    if #items == 0 then
        return nil
    end
    local done, total = counts()
    return string.format(
        "Current task list (%d/%d done). Keep it up to date with the todo tool:\n%s",
        done,
        total,
        table.concat(render(), "\n")
    )
end)

uji.command("todos", {
    desc = "show the current task list",
    handler = function()
        if #items == 0 then
            uji.notify("No tasks yet.")
            return
        end
        local done, total = counts()
        uji.ui.select({
            title = string.format("Tasks (%d/%d done)", done, total),
            items = render(),
        }, function() end)
    end,
})

uji.on("render_message", function(event)
    if event.type ~= "tool" or event.name ~= "todo" then
        return nil
    end
    local lines = {}
    for _, item in ipairs(items) do
        local mark = STATUS[item.status] or " "
        local color = item.status == "done" and "#808080"
            or (item.status == "doing" and "cyan" or nil)
        lines[#lines + 1] = {
            { text = "   [" .. mark .. "] ", color = color },
            { text = item.text, color = color },
        }
    end
    if #lines == 0 then
        lines[1] = { { text = "   task list cleared", color = "#808080" } }
    end
    return lines
end)
