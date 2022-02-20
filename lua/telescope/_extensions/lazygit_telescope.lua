local Path = require("plenary.path")
local Window = require("plenary.window.float")
local strings = require("plenary.strings")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local utils = require("telescope.utils")
local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local lazygit = require("lazygit")


local function open_lazygit(prompt_buf)
    local entry = action_state.get_selected_entry()
    local cmd = [[lua require"lazygit".lazygit('%s')]]
    local path = entry.value
    cmd = cmd:format(path:gsub("%s", ""))
    vim.api.nvim_command(cmd)
    vim.api.nvim_buf_set_keymap(0, 't', '<Esc>', '<Esc>', {noremap = true, silent = true})
end


local lazygit_repos = function(opts)
    local displayer = require("telescope.pickers.entry_display").create {
        separator = "",
        items = {
            {width = 4},
            {width = 55},
            {remaining = true},
        },
    }

    local repos = {}
    for _, v in pairs(lazygit.lazygit_visited_git_repos) do
        local index = #repos + 1
        -- retrieve the git repo name
        local entry =
        {
            idx = index,
            value = v:gsub("%s", ""),
            repo_name= v:gsub("%s", ""):match("^.+/(.+)$"),
        }

        table.insert(repos, index, entry)
    end

    pickers.new(opts or {}, {
        prompt_title = "lazygit repos",
        finder = finders.new_table {
            results = repos,
            entry_maker = function(entry)
                local make_display = function()
                    return displayer
                    {
                        {entry.idx},
                        {entry.repo_name},
                    }
                end

                return {
                    value = entry.value,
                    ordinal = string.format("%s %s", entry.idx, entry.repo_name),
                    display = make_display,
                }
            end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(_, _)
            action_set.select:replace(open_lazygit)
            return true
        end
    }):find()
end

return require("telescope").register_extension({
    exports = {
        lazygit = lazygit_repos,
    }
})
