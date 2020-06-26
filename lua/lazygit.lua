local api = vim.api
local file_buffer = nil

vim.cmd = api.nvim_command

local function trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local function execute(cmd, ...)
  cmd = cmd:format(...)
  vim.cmd(cmd)
end

local function is_lazygit_available()
    return vim.api.nvim_call_function("executable", { "lazygit" }) == 1
end

local function project_root_dir()
    -- try file location first
    local folder = trim(vim.api.nvim_call_function('expand', { '%:p:h' }))
    local gitdir = vim.api.nvim_call_function('system', {'cd "' .. folder .. '" && git rev-parse --show-toplevel'} )
    local isgitdir = vim.api.nvim_call_function('matchstr', { gitdir, '^fatal:.*' }) == ""
    if isgitdir then
        return trim(gitdir)
    end

    -- try symlinked file location instead
    local symlink = trim(vim.api.nvim_call_function('fnamemodify', { vim.api.nvim_call_function('resolve', { vim.api.nvim_call_function('expand', { '%:p' }) }), ':h' }))
    local gitdir = vim.api.nvim_call_function('system', { 'cd "' .. symlink .. '" && git rev-parse --show-toplevel' })
    local isgitdir = vim.api.nvim_call_function('matchstr', { gitdir, '^fatal:.*' }) == ""
    if isgitdir then
        return trim(gitdir)
    end

    -- just return current working directory
    return vim.api.nvim_call_function('getcwd', {0, 0})
end

local function exec_lazygit_command(root_dir)
    local cmd = 'lazygit' .. ' -p "' .. root_dir .. '"'
    if ( vim.api.nvim_call_function("has", { "win64" }) == 0 and vim.api.nvim_call_function("has", { "win32" }) == 0 and vim.api.nvim_call_function("has", { "win16" }) == 0 ) then
        cmd = "GIT_EDITOR=nvim " .. cmd
    end
    -- ensure that the buffer is closed on exit
    execute([[
        call termopen('%s', {'on_exit': {job_id, code, event-> luaeval("require('lazygit').on_exit(" . job_id . "," . code . "," . event . ")")}})
    ]], cmd)
    vim.cmd "startinsert"
end

local function open_floating_window()

    local lines = api.nvim_get_option("lines")
    local columns = api.nvim_get_option("columns")
    local floating_window_scaling_factor = api.nvim_get_var("lazygit_floating_window_scaling_factor")
    if type(floating_window_scaling_factor) == 'table' then
        floating_window_scaling_factor = floating_window_scaling_factor[false]
    end
    local floating_window_winblend = api.nvim_get_var("lazygit_floating_window_winblend")

    local height = math.ceil(lines * floating_window_scaling_factor) - 1
    local width = math.ceil(columns * floating_window_scaling_factor)

    local row = math.ceil(lines - height) / 2
    local col = math.ceil(columns - width) / 2

    local border_opts = {
        style = "minimal",
        relative = "editor",
        row = row - 1,
        col = col - 1,
        width = width + 2,
        height = height + 2,
    }

    local opts = {
        style = "minimal",
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
    }

    local border_lines = {'╭' .. string.rep('─', width) .. '╮'}
    local middle_line = '│' .. string.rep(' ', width) .. '│'
    for i = 1, height do
        table.insert(border_lines, middle_line)
    end
    table.insert(border_lines, '╰' .. string.rep('─', width) .. '╯')

    -- create a unlisted scratch buffer for the border
    local border_buffer = api.nvim_create_buf(false, true)

    -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
    api.nvim_buf_set_lines(border_buffer, 0, -1, true, border_lines)
    -- create border window
    local border_window = api.nvim_open_win(border_buffer, true, border_opts)

    vim.cmd 'set winhl=Normal:Floating'

    -- create a unlisted scratch buffer
    file_buffer = api.nvim_create_buf(false, true)
    -- create file window
    local file_window = api.nvim_open_win(file_buffer, true, opts)

    -- api.nvim_win_set_option(file_window, 'filetype', 'lazygit')

    vim.cmd('setlocal nocursorcolumn')
    vim.cmd('set winblend=' .. floating_window_winblend)

    -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
    local cmd = [[autocmd WinLeave <buffer> silent! execute 'silent bdelete! %s %s']]
    vim.cmd(cmd:format(file_buffer, border_buffer))
end

local function on_exit(job_id, code, event)
    if code == 0 then
        -- delete terminal buffer
        vim.cmd("silent! bdelete!")
        file_buffer = nil
    end
end

local function lazygit()
    if is_lazygit_available() ~= true then
        print("Please install lazygit. Check documentation for more information")
        return
    end
    -- TODO: ensure that it is a valid git directory
    local root_dir = project_root_dir()
    open_floating_window()
    exec_lazygit_command(root_dir)
end

local function lazygitconfig()
    local uname = vim.api.nvim_call_function('system', { 'uname' })
    local os = vim.api.nvim_call_function("substitute", { uname, '\n', '', '' })
    local config_file = ""
    if os == "Darwin" then
        config_file = "~/Library/Application Support/jesseduffield/lazygit/config.yml"
    else
        config_file = "~/.config/jesseduffield/lazygit/config.yml"
    end
    if vim.api.nvim_call_function('empty', { vim.api.nvim_call_function('glob', { config_file }) }) == 1 then
        -- file does not exist
        -- check if user wants to create it
        local answer = vim.api.nvim_call_function('confirm', { "File " .. config_file .. " does not exist.\nDo you want to create the file and populate it with the default configuration?", "&Yes\n&No" })
        if answer == 2 then
            return nil
        end
        if vim.api.nvim_call_function('isdirectory', { vim.api.nvim_call_function('fnamemodify', { config_file, ":h" }) }) == false then
            -- directory does not exist
            vim.api.nvim_call_function('mkdir', { vim.api.nvim_call_function('fnamemodify', { config_file, ":h" }) })
        end
        vim.cmd("edit " .. config_file)
        vim.cmd([[execute "silent! 0read !lazygit -c"]])
        vim.cmd([[execute "normal 1G"]])
    else
        vim.cmd("edit " .. config_file)
    end
end

return {
    setup = setup,
    lazygit = lazygit,
    lazygitconfig = lazygitconfig,
    on_exit = on_exit,
    on_buf_leave = on_buf_leave,
}
