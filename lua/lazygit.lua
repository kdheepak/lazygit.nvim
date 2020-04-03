local api = vim.api
local fn = vim.fn

local function echom(message)
  api.nvim_command('echom "' .. tostring(message) .. '"')
end

local function is_lazygit_available()
    return fn.executable("lazygit") == 1
end

function open_floating_window()

    -- create a unlisted scratch buffer
    local buffer = api.nvim_create_buf(false, true)
    -- create a unlisted scratch buffer for the border
    local border_buffer = api.nvim_create_buf(false, true)

    api.nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(buffer, 'filetype', 'lazygit')

    local columns = api.nvim_get_option("columns")
    local lines = api.nvim_get_option("lines")

    local height = math.ceil(lines * 0.8 - 4)
    local width = math.ceil(columns * 0.8)

    local row = math.ceil(lines - height) / 2 - 1
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
    -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
    api.nvim_buf_set_lines(border_buffer, 0, -1, false, border_lines)

    local border_window = api.nvim_open_win(border_buffer, true, border_opts)
    api.nvim_command('set winhl=Normal:Floating')
    local window = api.nvim_open_win(buffer, true, opts)
    api.nvim_command('set winhl=Normal:Floating')
    -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
    api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout!"' .. border_buffer)
    return window
end

local function project_root_dir()
    return fn.finddir('.git/..', fn.expand('%:p:h') .. ';')
end

local function execute(cmd, ...)
  cmd = cmd:format(...)
  vim.api.nvim_command(cmd)
end

local function exec_lazygit_command()
    local current_dir = fn.getcwd()
    -- TODO: ensure that it is a valid git directory
    local root_dir = project_root_dir()
    local cmd = "lazygit " .. "-p " .. root_dir
    -- ensure that the buffer is closed on exit
    execute([[
    call termopen('%s', {'on_exit': {-> execute(':q')}})
  ]], cmd)
end

function lazygit()
    if is_lazygit_available() ~= true then
        print("Please install lazygit. Check documentation for more information")
        return
    end
    local window = open_floating_window()
    exec_lazygit_command()
end

return {
    lazygit = lazygit,
}
