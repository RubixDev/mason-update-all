local registry = require('mason-registry')

local M = {}

---@class MasonUpdateAllSettings
local default_settings = {
    -- Whether a notification should be shown when there are no updates.
    ---@type boolean
    show_no_updates_notification = true,
}

M.current = default_settings

-- Cache headless mode at startup to avoid unsafe calls inside event loop
local IS_HEADLESS = #vim.api.nvim_list_uis() == 0

-- Smart message printer:
-- - uses io.stdout in headless mode for clean CLI output
-- - uses vim.notify in interactive mode if available
-- - falls back to print() otherwise
local function print_message(message)
    if IS_HEADLESS then
        io.stdout:write('[mason-update-all]' .. message .. '\n')
    elseif vim.notify then
        vim.notify(message, vim.log.levels.INFO, { title = 'Mason Update All' })
    else
        print('[mason-update-all]' .. message)
    end
end

---@param running_count number
---@param any_update boolean
---@param show_no_updates_notification boolean
local function check_done(running_count, any_update, show_no_updates_notification)
    if running_count == 0 then
        if any_update then
            print_message('Finished updating all packages')
        elseif show_no_updates_notification then
            print_message('Nothing to update')
        end

        -- Trigger autocmd
        vim.schedule(function()
            vim.api.nvim_exec_autocmds('User', {
                pattern = 'MasonUpdateAllComplete',
            })
        end)
    end
end

function M.update_all()
    local any_update = false -- Whether any package was updated
    local running_count = 0 -- Currently running jobs
    local done_launching_jobs = false

    print_message('Fetching updates')

    -- Update the registry
    registry.update(function(success, err)
        if not success then
            print_message('Error fetching updates: ' .. err)

            -- Trigger autocmd
            vim.schedule(function()
                vim.api.nvim_exec_autocmds('User', {
                    pattern = 'MasonUpdateAllComplete',
                })
            end)
            return
        end

        -- Iterate installed packages
        for _, pkg in ipairs(registry.get_installed_packages()) do
            running_count = running_count + 1

            -- Fetch for new version
            local latest_version = pkg:get_latest_version()
            local current_version = pkg:get_installed_version()
            if current_version ~= latest_version then
                any_update = true
                print_message(('Updating %s from %s to %s'):format(pkg.name, current_version, latest_version))
                pkg:install():on('closed', function()
                    running_count = running_count - 1
                    print_message(('Updated %s to %s'):format(pkg.name, latest_version))

                    -- Done
                    check_done(running_count, any_update, M.current.show_no_updates_notification)
                end)
            else
                running_count = running_count - 1
            end

            -- Done
            if done_launching_jobs then
                check_done(running_count, any_update, M.current.show_no_updates_notification)
            end
        end

        -- If all jobs are immediately done, do the checking here
        if running_count == 0 then
            check_done(running_count, any_update, M.current.show_no_updates_notification)
        end
        done_launching_jobs = true
    end)
end

---@param opts MasonUpdateAllSettings
function M.setup(opts)
    M.current = vim.tbl_deep_extend('force', M.current, opts)
    vim.api.nvim_create_user_command('MasonUpdateAll', M.update_all, {})
end

return M
