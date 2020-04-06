local api = vim.api
local fn = vim.fn

local OPTIONS = {
    lazygit_floating_window_scaling_factor = 0.9,
    lazygit_floating_window_winblend = 0,
}

local function execute(cmd, ...)
  cmd = cmd:format(...)
  api.nvim_command(cmd)
end

local function echom(message)
    execute('echom "' .. tostring(message) .. '"')
end

local function is_lazygit_available()
    return fn.executable("lazygit") == 1
end

function open_floating_window()
    -- create a unlisted scratch buffer
    local file_buffer = api.nvim_create_buf(false, true)
    -- create a unlisted scratch buffer for the border
    local border_buffer = api.nvim_create_buf(false, true)

    api.nvim_buf_set_option(file_buffer, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(file_buffer, 'filetype', 'lazygit')

    local height = math.ceil(vim.o.lines * OPTIONS.lazygit_floating_window_scaling_factor) - 1
    local width = math.ceil(vim.o.columns * OPTIONS.lazygit_floating_window_scaling_factor)

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
    -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
    api.nvim_buf_set_lines(border_buffer, 0, -1, false, border_lines)

    local border_window = api.nvim_open_win(border_buffer, true, border_opts)
    execute('set winhl=Normal:Floating')
    window = api.nvim_open_win(file_buffer, true, opts)

    execute('set winblend=' .. OPTIONS.lazygit_floating_window_winblend)

    -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
    execute('au BufWipeout <buffer> silent! execute "silent bwipeout!"' .. border_buffer)
end

local function project_root_dir()
    return fn.system('cd ' .. fn.expand('%:p:h') .. ' && git rev-parse --show-toplevel 2> /dev/null')
end

function on_exit(job_id, code, event)
    if code == 0 then
        api.nvim_command("bd!")
    end
end

local function exec_lazygit_command()
    local current_dir = fn.getcwd()
    -- TODO: ensure that it is a valid git directory
    local root_dir = project_root_dir()
    local cmd = "lazygit " .. "-p " .. root_dir
    -- ensure that the buffer is closed on exit
    execute([[
        call termopen('%s', {'on_exit': {job_id, code, event-> luaeval("require('lazygit').on_exit(" . job_id . "," . code . "," . event . ")")}})
    ]], cmd)
    execute("startinsert")
end

function lazygit()
    if is_lazygit_available() ~= true then
        print("Please install lazygit. Check documentation for more information")
        return
    end
    open_floating_window()
    exec_lazygit_command()
end

function setup()
    OPTIONS.lazygit_floating_window_winblend = api.nvim_get_var("lazygit_floating_window_winblend")
    -- api.nvim_get_var("lazygit_floating_window_scaling_factor") returns a table, with keys true and false.
    -- the value in corresponding to the false key appears to be what we want.
    OPTIONS.lazygit_floating_window_scaling_factor = api.nvim_get_var("lazygit_floating_window_scaling_factor")[false]
end

return {
    setup = setup,
    lazygit = lazygit,
    on_exit = on_exit,
}
