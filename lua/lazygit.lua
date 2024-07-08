local open_floating_window = require("lazygit.window").open_floating_window
local project_root_dir = require("lazygit.utils").project_root_dir
local get_root = require("lazygit.utils").get_root
local is_lazygit_available = require("lazygit.utils").is_lazygit_available
local is_symlink = require("lazygit.utils").is_symlink
local open_or_create_config = require("lazygit.utils").open_or_create_config

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
  -- lazygit -cd gives only the config dir, not the config file, so concat config.yml
  return fn.substitute(fn.system("lazygit -cd"), "\n", "", "") .. "/config.yml"
end

local function lazygitgetconfigpath()
  local default_config_path = lazygitdefaultconfigpath()
  -- if vim.g.lazygit_config_file_path is a table, check if all config files exist
  if vim.g.lazygit_config_file_path then
    if type(vim.g.lazygit_config_file_path) == "table" then
      for _, config_file in ipairs(vim.g.lazygit_config_file_path) do
        if fn.empty(fn.glob(config_file)) == 1 then
          print("lazygit: custom config file path: '" .. config_file .. "' could not be found. Returning default config")
          return default_config_path
        end
      end
      return vim.g.lazygit_config_file_path
    elseif fn.empty(fn.glob(vim.g.lazygit_config_file_path)) == 0 then
      return vim.g.lazygit_config_file_path
    else
      print("lazygit: custom config file path: '" .. vim.g.lazygit_config_file_path .. "' could not be found. Returning default config")
      return default_config_path
    end
  else
    print("lazygit: custom config file path is not set, option: 'lazygit_config_file_path' is missing")
    -- any issue with the config file we fallback to the default config file path
    return default_config_path
  end
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

  if vim.g.lazygit_use_custom_config_file_path == 1 then
    local config_path = lazygitgetconfigpath()
    if type(config_path) == "table" then
     config_path = table.concat(config_path, ",")
    end
    cmd = cmd .. " -ucf '" .. config_path .. "'" -- quote config_path to avoid whitespace errors
  end

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
  win, buffer = open_floating_window()
  local cmd = "lazygit " .. "-f " .. path
  exec_lazygit_command(cmd)
end

--- :LazyGitFilterCurrentFile entry point
local function lazygitfiltercurrentfile()
  local current_dir = vim.fn.expand("%:p:h")
  local git_root = get_root(current_dir)
  local file_path = vim.fn.expand('%:p')
  local relative_path = string.sub(file_path, #git_root + 2)
  lazygitfilter(relative_path)
end

--- :LazyGitConfig entry point
local function lazygitconfig()
  local config_file = lazygitgetconfigpath()

  if type(config_file) == "table" then
    vim.ui.select(
      config_file,
      { prompt = "select config file to edit" },
      function (path)
        open_or_create_config(path)
      end
    )
  else
    open_or_create_config(config_file)
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
