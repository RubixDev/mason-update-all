local registry = require('mason-registry')

local M = {}

---@class MasonUpdateAllSettings
local defaultSettings = {
    -- If a notification should be shown if there are no updates.
    ---@type boolean
    showNoUpdatesNotification = true,
}

M.current = defaultSettings

---@param running_count number
---@param any_update boolean
---@param showNoUpdatesNotification boolean
local function check_done(running_count, any_update, showNoUpdatesNotification)
    if running_count == 0 then
        if any_update then
            print('[mason-update-all] Finished updating all packages')
        elseif showNoUpdatesNotification then
            print('[mason-update-all] Nothing to update')
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

    print('[mason-update-all] Fetching updates')
    -- Update the registry
    registry.update(function(success, err)
        if not success then
            print('[mason-update-all] Error fetching updates: ' .. err)

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
            pkg:check_new_version(function(new_available, version)
                if new_available then
                    any_update = true
                    print(
                        ('[mason-update-all] Updating %s from %s to %s'):format(
                            pkg.name,
                            version.current_version,
                            version.latest_version
                        )
                    )
                    pkg:install():on('closed', function()
                        running_count = running_count - 1
                        print(('[mason-update-all] Updated %s to %s'):format(pkg.name, version.latest_version))

                        -- Done
                        check_done(running_count, any_update, M.current.showNoUpdatesNotification)
                    end)
                else
                    running_count = running_count - 1
                end

                -- Done
                if done_launching_jobs then
                    check_done(running_count, any_update, M.current.showNoUpdatesNotification)
                end
            end)
        end

        -- If all jobs are immediately done, do the checking here
        if running_count == 0 then
            check_done(running_count, any_update, M.current.showNoUpdatesNotification)
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
