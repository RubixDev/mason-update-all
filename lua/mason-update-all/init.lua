local registry = require('mason-registry')

local M = {}

local messages = vim.log.levels

local notification_options = {
  title = "mason-update-all"
}

local notifiers = {
  [messages.ERROR] = function(message)
    vim.notify(
      string.format(
        '[mason-update-all] Error during update: %s',
        message
      ),
      messages.ERROR,
      notification_options
    )
  end,
  [messages.INFO] = function(message)
    vim.notify(
      string.format(
        '[mason-update-all] %s',
        message
      ),
      vim.log.levels.INFO,
      notification_options
    )
  end
}

local function notify(message, level)
  notifiers[level](message)
end

local function check_done(running_count, any_update)
    if running_count == 0 then
        if any_update then
            notify('Finished updating all packages', messages.INFO)
        else
            notify('Nothing to update', messages.INFO)
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

    notify('Fetching updates', messages.INFO)
    -- Update the registry
    registry.update(function(success, err)
        if not success then
            notify(err, messages.ERROR)

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
                    local update_message = ('Updating %s from %s to %s'):format(
                        pkg.name,
                        version.current_version,
                        version.latest_version
                    )
                    notify(update_message, messages.INFO)

                    pkg:install():on('closed', function()
                        running_count = running_count - 1
                        local updated_message = ('Updated %s to %s'):format(pkg.name, version.latest_version)
                        notify(updated_message, messages.INFO)

                        -- Done
                        check_done(running_count, any_update)
                    end)
                else
                    running_count = running_count - 1
                end

                -- Done
                if done_launching_jobs then
                    check_done(running_count, any_update)
                end
            end)
        end

        -- If all jobs are immediately done, do the checking here
        if running_count == 0 then
            check_done(running_count, any_update)
        end
        done_launching_jobs = true
    end)
end

function M.setup()
    vim.api.nvim_create_user_command('MasonUpdateAll', M.update_all, {})
end

return M
