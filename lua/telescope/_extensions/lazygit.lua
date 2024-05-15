local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local lazygit_utils = require("lazygit.utils")
local entry_display = require("telescope.pickers.entry_display")

local function open_lazygit()
    local entry = action_state.get_selected_entry()
    vim.cmd('cd ' .. vim.fn.fnameescape(entry.value))
    require("lazygit").lazygit(nil)
    vim.cmd('stopinsert | startinsert')
end

local function make_entry_display(opts)
    return entry_display.create {
        separator = "",
        items = {
            {width = 4}, -- index width
            {width = opts.width_repo_name or 55}, -- repo name width
            {remaining = true},
        },
    }
end

local function make_entry_maker(displayer)
    return function(entry)
        local display = function(e)
            return displayer {
                {e.idx},
                {e.repo_name},
            }
        end

        return {
            value = entry.value,
            ordinal = string.format("%s %s", entry.idx, entry.repo_name),
            display = display,
        }
    end
end

local function lazygit_repos(opts)
    opts = opts or {}
    local displayer = make_entry_display(opts)

    local repos = {}
    for i, v in ipairs(lazygit_utils.lazygit_visited_git_repos or {}) do
        local repo_name = v:match("^.+/(.+)$")
        if repo_name then
            table.insert(repos, {
                idx = i,
                value = v,
                repo_name = repo_name,
            })
        end
    end

    pickers.new(opts, {
        prompt_title = "lazygit repos",
        finder = finders.new_table {
            results = repos,
            entry_maker = make_entry_maker(displayer),
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_buf, _)
            actions.select_default:replace(function()
                actions.close(prompt_buf)
                open_lazygit()
            end)
            return true
        end,
    }):find()
end

return require("telescope").register_extension({
    exports = {lazygit = lazygit_repos}
})
