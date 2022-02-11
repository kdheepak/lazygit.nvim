vim = vim
local api = vim.api
local fn = vim.fn

-- store all git repositories visited in this session
local lazygit_visited_git_repos = {}
local function append_git_repo_path(repo_path)
    -- TODO: could be done better :)
    for _, path in ipairs(lazygit_visited_git_repos) do
        if path == repo_path then
            return
        end
    end

    table.insert(lazygit_visited_git_repos, tostring(repo_path))
end

LAZYGIT_BUFFER = nil
LAZYGIT_LOADED = false
vim.g.lazygit_opened = 0

--- Strip leading and lagging whitespace
local function trim(str)
  return str:gsub('^%s+', ''):gsub('%s+$', '')
end

--- Check if lazygit is available
local function is_lazygit_available()
  return fn.executable('lazygit') == 1
end

local function is_symlink()
  local resolved = fn.resolve(fn.expand('%:p'))
  return resolved ~= fn.expand('%:p')
end

--- Get project_root_dir for git repository
local function project_root_dir()

  -- always use bash on Unix based systems.
  local oldshell = vim.o.shell
  if vim.fn.has('win32') == 0 then
      vim.o.shell = 'bash'
  end

  -- try symlinked file location instead
  local gitdir = fn.system(
               'cd "' .. fn.fnamemodify(fn.resolve(fn.expand('%:p')), ':h') .. '" && git rev-parse --show-toplevel')
  local isgitdir = fn.matchstr(gitdir, '^fatal:.*') == ''

  -- TODO: not sure the right way to do this
  if isgitdir then
    vim.o.shell = oldshell
    append_git_repo_path(gitdir)
    return trim(gitdir)
  end

  -- revert to old shell
  vim.o.shell = oldshell

  local repo_path = fn.getcwd(0, 0)
  append_git_repo_path(repo_path)

  -- just return current working directory
  return repo_path
end

--- on_exit callback function to delete the open buffer when lazygit exits in a neovim terminal
local function on_exit(job_id, code, event)
  if code == 0 then
    -- Close the window where the LAZYGIT_BUFFER is
    vim.cmd('silent! :q')
    LAZYGIT_BUFFER = nil
    LAZYGIT_LOADED = false
    vim.g.lazygit_opened = 0
  end
end

--- Call lazygit
local function exec_lazygit_command(cmd)
  if LAZYGIT_LOADED == false then
    -- ensure that the buffer is closed on exit
    vim.g.lazygit_opened = 1
    vim.fn.termopen(cmd, { on_exit = on_exit })
  end
  vim.cmd 'startinsert'
end

--- open floating window with nice borders
local function open_floating_window()
  local floating_window_scaling_factor = vim.g.lazygit_floating_window_scaling_factor

  -- Why is this required?
  -- vim.g.lazygit_floating_window_scaling_factor returns different types if the value is an integer or float
  if type(floating_window_scaling_factor) == 'table' then
    floating_window_scaling_factor = floating_window_scaling_factor[false]
  end

  local status, plenary = pcall(require, 'plenary.window.float')
  if status and vim.g.lazygit_floating_window_use_plenary and vim.g.lazygit_floating_window_use_plenary ~= 0 then
    plenary.percentage_range_window(floating_window_scaling_factor, floating_window_scaling_factor)
    return
  end

  local height = math.ceil(vim.o.lines * floating_window_scaling_factor) - 1
  local width = math.ceil(vim.o.columns * floating_window_scaling_factor)

  local row = math.ceil(vim.o.lines - height) / 2
  local col = math.ceil(vim.o.columns - width) / 2

  local border_opts = {
    style = 'minimal',
    relative = 'editor',
    row = row - 1,
    col = col - 1,
    width = width + 2,
    height = height + 2,
  }

  local opts = { style = 'minimal', relative = 'editor', row = row, col = col, width = width, height = height }

  local topleft, topright, botleft, botright
  local corner_chars = vim.g.lazygit_floating_window_corner_chars
  if type(corner_chars) == 'table' and #corner_chars == 4 then
    topleft, topright, botleft, botright = unpack(corner_chars)
  else
    topleft, topright, botleft, botright = '╭', '╮', '╰', '╯'
  end

  local border_lines = { topleft .. string.rep('─', width) .. topright }
  local middle_line = '│' .. string.rep(' ', width) .. '│'
  for i = 1, height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, botleft .. string.rep('─', width) .. botright)

  -- create a unlisted scratch buffer for the border
  local border_buffer = api.nvim_create_buf(false, true)

  -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
  api.nvim_buf_set_lines(border_buffer, 0, -1, true, border_lines)
  -- create border window
  local border_window = api.nvim_open_win(border_buffer, true, border_opts)
  vim.cmd('set winhl=Normal:Floating')

  -- create a unlisted scratch buffer
  if LAZYGIT_BUFFER == nil or vim.fn.bufwinnr(LAZYGIT_BUFFER) == -1 then
    LAZYGIT_BUFFER = api.nvim_create_buf(false, true)
  else
    LAZYGIT_LOADED = true
  end
  -- create file window, enter the window, and use the options defined in opts
  local _ = api.nvim_open_win(LAZYGIT_BUFFER, true, opts)

  vim.bo[LAZYGIT_BUFFER].filetype = 'lazygit'

  vim.cmd('setlocal bufhidden=hide')
  vim.cmd('setlocal nocursorcolumn')
  vim.cmd('set winblend=' .. vim.g.lazygit_floating_window_winblend)

  -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
  local cmd = [[autocmd WinLeave <buffer> silent! execute 'hide']]
  vim.cmd(cmd)
  cmd = [[autocmd WinLeave <buffer> silent! execute 'silent bdelete! %s']]
  vim.cmd(cmd:format(border_buffer))
end

--- :LazyGit entry point
local function lazygit(path)
  if is_lazygit_available() ~= true then
    print('Please install lazygit. Check documentation for more information')
    return
  end
  if path == nil then
    if is_symlink() then
      path = project_root_dir()
    end
  end
  open_floating_window()

  -- TODO: this should be configurable and not hardcoded like this
  -- this is convinient if you want to carry your lazygit config in a custom location
  local function get_nvim_root()
      local nvim_root_path = vim.api.nvim_eval('$MYVIMRC')
      return nvim_root_path:match("(.*".."\\"..")")
  end
  local cmd = 'lazygit'
  _ = project_root_dir()

  if path ~= nil then
      cmd = cmd .. ' -p ' .. path
  end

  cmd = cmd .. ' -ucf=' .. get_nvim_root() .. '/config/config.yml'

  -- if path ~= nil and not vim.env.GIT_DIR then
  --   cmd = cmd .. ' -g "' .. path .. '/.git/"'
  -- end

  -- if path ~= nil and not vim.env.GIT_WORK_TREE then
  --   cmd = cmd .. ' -w "' .. path .. '"'
  -- end

  exec_lazygit_command(cmd)
end

--- :LazyGitFilter entry point
local function lazygitfilter(path)
  if is_lazygit_available() ~= true then
    print('Please install lazygit. Check documentation for more information')
    return
  end
  if path == nil then
    path = project_root_dir()
  end
  open_floating_window()
  local cmd = 'lazygit ' .. '-f ' .. path
  exec_lazygit_command(cmd)
end

--- :LazyGitConfig entry point
local function lazygitconfig()
  local os = fn.substitute(fn.system('uname'), '\n', '', '')
  local config_file = ''
  if os == 'Darwin' then
    config_file = '~/Library/Application Support/jesseduffield/lazygit/config.yml'
  else
    config_file = '~/.config/lazygit/config.yml'
  end
  if fn.empty(fn.glob(config_file)) == 1 then
    -- file does not exist
    -- check if user wants to create it
    local answer = fn.confirm('File ' .. config_file
                                  .. ' does not exist.\nDo you want to create the file and populate it with the default configuration?',
                              '&Yes\n&No')
    if answer == 2 then
      return nil
    end
    if fn.isdirectory(fn.fnamemodify(config_file, ':h')) == false then
      -- directory does not exist
      fn.mkdir(fn.fnamemodify(config_file, ':h'), 'p')
    end
    vim.cmd('edit ' .. config_file)
    vim.cmd([[execute "silent! 0read !lazygit -c"]])
    vim.cmd([[execute "normal 1G"]])
  else
    vim.cmd('edit ' .. config_file)
  end
end

return {
  lazygit = lazygit,
  lazygitfilter = lazygitfilter,
  lazygitconfig = lazygitconfig,
  project_root_dir = project_root_dir,
  lazygit_visited_git_repos = lazygit_visited_git_repos,
}
