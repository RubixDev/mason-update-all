local registry = require('mason-registry')

local M = {}

local function check_installed(pkg)
    local installed = false
    local install_counter = 0

    -- Check if installation still running
    repeat
        install_counter = install_counter + 1
        pkg:check_new_version(function(new, _)
            if new then
                installed = false
                vim.wait(2000, function() end)
            else
                installed = true
            end
        end)
    until installed == true or install_counter >= 10
end

local function update_all(sync)
    local any_update = false -- Whether any package was updated
    local update_list = {} -- list of pacakges to udpate

    print('[mason-update-all] Fetching updates')

    -- Iterate installed packages
    for _, pkg in ipairs(registry.get_installed_packages()) do

        -- Fetch for new version
        pkg:check_new_version(function(new_available, version)
            if new_available then
                table.insert(update_list, pkg)
                any_update = true
                print(
                    ('[mason-update-all] Updating %s from %s to %s'):format(
                        pkg.name,
                        version.current_version,
                        version.latest_version
                    )
                )
                pkg:install()
            end
        end)
    end

    -- Verify packages finished installation in async mode
    if sync then
        for _,pkg in ipairs(update_list) do
            check_installed(pkg)
            print(('[mason-update-all] Updated %s'):format(pkg.name))
        end
    end

    -- Done
    if any_update then
        print('[mason-update-all] Finished updating all packages')
    else
        print('[mason-update-all] Nothing to update')
    end

    -- Trigger autocmd for async mode
    if sync then
      vim.schedule(function()
          vim.api.nvim_exec_autocmds('User', {
              pattern = 'MasonUpdateAllComplete',
          })
      end)
    end
end

function M.update_async()
    update_all(false)
end

function M.update_sync()
    update_all(true)
end

function M.setup()
    vim.api.nvim_create_user_command('MasonUpdateAll', M.update_async, {})
    vim.api.nvim_create_user_command('MasonUpdateAllSync', M.update_sync, {})
end

return M
