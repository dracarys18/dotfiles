-- Post-install build runner.
-- Called with the plugin spec list from plugins/init.lua.
-- Reads `build` and `check` fields from each spec — vim.pack ignores unknown fields.
--
-- Spec fields:
--   build  : { 'cmd', 'arg', … }  → run as shell command in plugin dir
--            ':VimCmd'             → run as vim command (on VimEnter)
--            function()            → call as lua function (on VimEnter)
--   check  : relative path        → skip build if this path exists inside plugin dir
--            absolute path        → skip build if this path exists (for executables)
--            ''                   → truthy empty string means "already satisfied", skip

local function find_plugin(spec)
    -- derive name the same way vim.pack does: last path segment, strip .git/.nvim suffixes
    local name = spec.name or spec.src:match('/([^/]+)$'):gsub('%.git$', '')
    local hits = vim.fn.globpath(vim.o.packpath, 'pack/*/opt/' .. name, false, true)
    return hits[1], name
end

local function run_async(label, cmd, cwd)
    vim.notify('[build] ' .. label .. ' …', vim.log.levels.INFO)
    vim.system(cmd, { cwd = cwd, text = true }, function(result)
        vim.schedule(function()
            if result.code == 0 then
                vim.notify('[build] ' .. label .. ' done', vim.log.levels.INFO)
            else
                vim.notify('[build] ' .. label .. ' FAILED\n' .. (result.stderr or ''), vim.log.levels.ERROR)
            end
        end)
    end)
end

local function needs_build(spec, plugin_dir)
    if not spec.check then return true end
    local check = type(spec.check) == 'function' and spec.check() or spec.check
    if not check or check == '' then return true end
    -- absolute path or relative to plugin dir
    local path = check:sub(1, 1) == '/' and check or (plugin_dir .. '/' .. check)
    return not vim.uv.fs_stat(path)
end

local function dispatch(spec, plugin_dir, label)
    local b = spec.build
    if type(b) == 'table' then
        run_async(label, b, plugin_dir)
    elseif type(b) == 'string' then
        vim.api.nvim_create_autocmd('VimEnter', {
            once     = true,
            callback = function() vim.cmd(b) end,
        })
    elseif type(b) == 'function' then
        vim.api.nvim_create_autocmd('VimEnter', {
            once     = true,
            callback = b,
        })
    end
end

return function(specs)
    for _, spec in ipairs(specs) do
        if spec.build then
            local plugin_dir, label = find_plugin(spec)
            if plugin_dir and needs_build(spec, plugin_dir) then
                dispatch(spec, plugin_dir, label)
            end
        end
    end

    -- :PackBuild forces all build steps regardless of check
    vim.api.nvim_create_user_command('PackBuild', function()
        for _, spec in ipairs(specs) do
            if spec.build then
                local plugin_dir, label = find_plugin(spec)
                if plugin_dir then dispatch(spec, plugin_dir, label) end
            end
        end
    end, { desc = 'Re-run all plugin post-install build steps' })
end
