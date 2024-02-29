local utils = require("lazygit.utils")
local window = require("lazygit.window")

local vim_fn = vim.fn
local api = vim.api
local cmd = vim.cmd

local LAZYGIT = {
  buffer = nil,
  loaded = false,
  opened = vim.g.lazygit_opened or 0,
  prev_win = -1,
  win = -1
}

local function on_exit(code)
  if code ~= 0 then return end

  LAZYGIT = {buffer = nil, loaded = false, opened = 0, prev_win = -1, win = -1}
  cmd("silent! :checktime")

  if api.nvim_win_is_valid(LAZYGIT.prev_win) then
    api.nvim_win_close(LAZYGIT.win, true)
    api.nvim_set_current_win(LAZYGIT.prev_win)
    if api.nvim_buf_is_valid(LAZYGIT.buffer) and api.nvim_buf_is_loaded(LAZYGIT.buffer) then
      api.nvim_buf_delete(LAZYGIT.buffer, {force = true})
    end
  end
end

local function termopen_with_exit(cmd)
  if not LAZYGIT.loaded then
    LAZYGIT.opened = 1
    vim_fn.termopen(cmd, {on_exit = on_exit})
    cmd("startinsert")
  end
end

local function get_config_path()
  local default_path = utils.lazygit_default_config_path()
  local config_path = utils.resolve_config_path(vim.g.lazygit_config_file_path)
  if config_path then return config_path end
  print("Using default config path: " .. default_path)
  return default_path
end

local function exec_lazygit(cmd, path)
  if not utils.is_lazygit_available() then
    print("Please install lazygit. Check documentation for more information.")
    return
  end

  LAZYGIT.prev_win = api.nvim_get_current_win()
  LAZYGIT.win, LAZYGIT.buffer = window.open_floating_window()

  local config_path = vim.g.lazygit_use_custom_config_file_path == 1 and get_config_path() or ""
  if config_path ~= "" then
    cmd = string.format("%s -ucf '%s'", cmd, config_path)
  end

  if path and vim_fn.isdirectory(path) == 1 then
    cmd = string.format("%s -p %s", cmd, path)
  end

  termopen_with_exit(cmd)
end

local function lazygit(path)
  path = path or utils.resolve_project_path()
  exec_lazygit("lazygit", path)
end

local function lazygit_current_file()
  local path = utils.get_git_root(vim_fn.expand("%:p:h"))
  lazygit(path)
end

local function lazygit_filter(path)
  path = path or utils.project_root_dir()
  exec_lazygit("lazygit -f", path)
end

local function lazygit_filter_current_file()
  local path = vim_fn.expand("%")
  lazygit_filter(path)
end

local function lazygit_config()
  local config_file = get_config_path()
  utils.open_or_create_config(config_file)
end

return {
  lazygit = lazygit,
  lazygitcurrentfile = lazygit_current_file,
  lazygitfilter = lazygit_filter,
  lazygitfiltercurrentfile = lazygit_filter_current_file,
  lazygitconfig = lazygit_config,
  project_root_dir = utils.project_root_dir,
}
