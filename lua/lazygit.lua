local open_floating_window = require("lazygit.window").open_floating_window
local project_root_dir = require("lazygit.utils").project_root_dir
local get_root = require("lazygit.utils").get_root
local is_lazygit_available = require("lazygit.utils").is_lazygit_available
local is_symlink = require("lazygit.utils").is_symlink

local fn = vim.fn

LAZYGIT_BUFFER = nil
LAZYGIT_LOADED = false
vim.g.lazygit_opened = 0
local prev_win = -1
local win = -1
local buffer = -1

--- on_exit callback function to delete the open buffer when lazygit exits in a neovim terminal
local function on_exit(job_id, code, event)
  if code ~= 0 then
    return
  end

  LAZYGIT_BUFFER = nil
  LAZYGIT_LOADED = false
  vim.g.lazygit_opened = 0
  vim.cmd("silent! :checktime")

  if vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_set_current_win(prev_win)
    prev_win = -1
    if vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
    buffer = -1
    win = -1
  end
end

--- Call lazygit
local function exec_lazygit_command(cmd)
  if LAZYGIT_LOADED == false then
    -- ensure that the buffer is closed on exit
    vim.g.lazygit_opened = 1
    vim.fn.termopen(cmd, { on_exit = on_exit })
  end
  vim.cmd("startinsert")
end

local function lazygitdefaultconfigpath()
  local os_name = vim.loop.os_uname().sysname

  -- TODO: not surer if vim.loop.os_uname() has the same result
  -- check before replacing the following line
  local os = fn.substitute(fn.system("uname"), "\n", "", "")
  if os == "Darwin" then
    return "~/Library/Application Support/lazygit/config.yml"
  else
    if string.find(os_name, "Window") then
      return "%APPDATA%/lazygit/config.yml"
    else
      return "~/.config/lazygit/config.yml"
    end
  end
end

local function lazygitgetconfigpath()
  if vim.g.lazygit_use_custom_config_file_path == 1 then
    if vim.g.lazygit_config_file_path then
      -- if file exists
      if fn.empty(fn.glob(vim.g.lazygit_config_file_path)) == 0 then
        return vim.g.lazygit_config_file_path
      end

      print("lazygit: custom config file path: '" .. vim.g.lazygit_config_file_path .. "' could not be found")
    else
      print("lazygit: custom config file path is not set, option: 'lazygit_config_file_path' is missing")
    end
  end

  -- any issue with the config file we fallback to the default config file path
  return lazygitdefaultconfigpath()
end

--- :LazyGit entry point
local function lazygit(path)
  if is_lazygit_available() ~= true then
    print("Please install lazygit. Check documentation for more information")
    return
  end

  prev_win = vim.api.nvim_get_current_win()

  win, buffer = open_floating_window()

  local cmd = "lazygit"

  -- set path to the root path
  _ = project_root_dir()

  -- print(lazygitgetconfigpath())

  cmd = cmd .. " -ucf " .. lazygitgetconfigpath()

  if path == nil then
    if is_symlink() then
      path = project_root_dir()
    end
  else
    if fn.isdirectory(path) then
      cmd = cmd .. " -p " .. path
    end
  end

  exec_lazygit_command(cmd)
end

--- :LazyGitCurrentFile entry point
local function lazygitcurrentfile()
  local current_dir = vim.fn.expand("%:p:h")
  local git_root = get_root(current_dir)
  lazygit(git_root)
end

--- :LazyGitFilter entry point
local function lazygitfilter(path)
  if is_lazygit_available() ~= true then
    print("Please install lazygit. Check documentation for more information")
    return
  end
  if path == nil then
    path = project_root_dir()
  end
  prev_win = vim.api.nvim_get_current_win()
  open_floating_window()
  local cmd = "lazygit " .. "-f " .. path
  exec_lazygit_command(cmd)
end

--- :LazyGitFilterCurrentFile entry point
local function lazygitfiltercurrentfile()
  local current_file = vim.fn.expand("%")
  lazygitfilter(current_file)
end

--- :LazyGitConfig entry point
local function lazygitconfig()
  local config_file = lazygitgetconfigpath()

  if fn.empty(fn.glob(config_file)) == 1 then
    -- file does not exist
    -- check if user wants to create it
    local answer = fn.confirm(
      "File "
        .. config_file
        .. " does not exist.\nDo you want to create the file and populate it with the default configuration?",
      "&Yes\n&No"
    )
    if answer == 2 then
      return nil
    end
    if fn.isdirectory(fn.fnamemodify(config_file, ":h")) == false then
      -- directory does not exist
      fn.mkdir(fn.fnamemodify(config_file, ":h"), "p")
    end
    vim.cmd("edit " .. config_file)
    vim.cmd([[execute "silent! 0read !lazygit -c"]])
    vim.cmd([[execute "normal 1G"]])
  else
    vim.cmd("edit " .. config_file)
  end
end

return {
  lazygit = lazygit,
  lazygitcurrentfile = lazygitcurrentfile,
  lazygitfilter = lazygitfilter,
  lazygitfiltercurrentfile = lazygitfiltercurrentfile,
  lazygitconfig = lazygitconfig,
  project_root_dir = project_root_dir,
}
