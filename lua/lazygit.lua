vim = vim
local api = vim.api
local fn = vim.fn

local function execute(cmd, ...)
  cmd = cmd:format(...)
  vim.cmd(cmd)
end

local function is_lazygit_available()
    return fn.executable("lazygit") == 1
end

local function project_root_dir()

    -- try file location first
    local gitdir = fn.system('cd ' .. fn.expand('%:p:h') .. ' && git rev-parse --show-toplevel')
    local isgitdir = fn.matchstr(gitdir, '^fatal:.*') == ""
    if isgitdir then
        return gitdir
    end

    -- try symlinked file location instead
    local gitdir = fn.system('cd ' .. fn.fnamemodify(fn.resolve(fn.expand('%:p')), ':h') .. ' && git rev-parse --show-toplevel')
    local isgitdir = fn.matchstr(gitdir, '^fatal:.*') == ""
    if isgitdir then
        return gitdir
    end

    -- just return current working directory
    return fn.getcwd(0, 0)
end

local function on_exit(job_id, code, event)
    if code == 0 then
        -- delete terminal buffer
        vim.cmd("silent! bdelete!")
    end
end

local function exec_lazygit_command(cmd)
    if ( fn.has("win64") == 0 and fn.has("win32") == 0 and fn.has("win16") == 0 ) then
        cmd = "GIT_EDITOR=nvim " .. cmd
    end
    -- ensure that the buffer is closed on exit
    vim.fn.termopen(cmd, { on_exit = on_exit })
    vim.cmd "startinsert"
end

local function open_floating_window()

    local floating_window_scaling_factor = vim.g.lazygit_floating_window_scaling_factor

    if type(floating_window_scaling_factor) == 'table' then
        floating_window_scaling_factor = floating_window_scaling_factor[false]
    end

    local height = math.ceil(vim.o.lines * floating_window_scaling_factor) - 1
    local width = math.ceil(vim.o.columns * floating_window_scaling_factor)

    local row = math.ceil(vim.o.lines - height) / 2
    local col = math.ceil(vim.o.columns - width) / 2

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
    local file_buffer = api.nvim_create_buf(false, true)
    -- create file window
    local file_window = api.nvim_open_win(file_buffer, true, opts)

    vim.bo[file_buffer].filetype = 'lazygit'

    vim.cmd('setlocal nocursorcolumn')
    vim.cmd('set winblend=' .. vim.g.lazygit_floating_window_winblend)

    -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
    local cmd = [[autocmd WinLeave <buffer> silent! execute 'silent bdelete! %s %s']]
    vim.cmd(cmd:format(file_buffer, border_buffer))
end

local function lazygit(path)
    if is_lazygit_available() ~= true then
        print("Please install lazygit. Check documentation for more information")
        return
    end
    if path == nil then
        path = project_root_dir()
    end
    open_floating_window()
    local cmd = "lazygit " .. "-p " .. path
    exec_lazygit_command(cmd)
end


local function lazygitfilter(path)
    if is_lazygit_available() ~= true then
        print("Please install lazygit. Check documentation for more information")
        return
    end
    if path == nil then
        path = project_root_dir()
    end
    open_floating_window()
    local cmd = "lazygit " .. "-f " .. path
    exec_lazygit_command(cmd)
end

local function lazygitconfig()
    local os = fn.substitute(fn.system('uname'), '\n', '', '')
    local config_file = ""
    if os == "Darwin" then
        config_file = "~/Library/Application Support/jesseduffield/lazygit/config.yml"
    else
        config_file = "~/.config/jesseduffield/lazygit/config.yml"
    end
    if fn.empty(fn.glob(config_file)) == 1 then
        -- file does not exist
        -- check if user wants to create it
        local answer = fn.confirm("File " .. config_file .. " does not exist.\nDo you want to create the file and populate it with the default configuration?", "&Yes\n&No")
        if answer == 2 then
            return nil
        end
        if fn.isdirectory(fn.fnamemodify(config_file, ":h")) == false then
            -- directory does not exist
            fn.mkdir(fn.fnamemodify(config_file, ":h"))
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
    lazygitfilter = lazygitfilter,
    lazygitconfig = lazygitconfig,
    on_exit = on_exit,
    on_buf_leave = on_buf_leave,
}
