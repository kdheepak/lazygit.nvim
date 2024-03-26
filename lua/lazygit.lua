-- Load necessary modules and create shortcuts for API functions
local utils = require("lazygit.utils")
local window = require("lazygit.window")
local vim_fn = vim.fn
local api = vim.api
local cmd = vim.cmd

-- LAZYGIT table to hold state information for lazygit integration
local LAZYGIT = {
  buffer = nil,      -- Buffer ID for lazygit output
  loaded = false,    -- Flag to track if lazygit is loaded
  opened = vim.g.lazygit_opened or 0, -- Counter for opened instances
  prev_win = -1,     -- Previous window ID
  win = -1           -- Current window ID for lazygit
}

-- Handles clean up after lazygit exits
local function on_exit(code)
  -- If exit code is non-zero, do nothing
  if code ~= 0 then return end

  -- Reset LAZYGIT state and close the window if valid
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

-- Opens a terminal window with lazygit and sets up an exit handler
local function termopen_with_exit(cmd)
  -- Proceed only if lazygit hasn't been loaded already
  if not LAZYGIT.loaded then
    LAZYGIT.opened = 1
    vim_fn.termopen(cmd, {on_exit = on_exit})
    cmd("startinsert")
  end
end

-- Resolves the configuration path for lazygit, defaults if not found
local function get_config_path()
  local default_path = utils.lazygit_default_config_path()
  local config_path = utils.resolve_config_path(vim.g.lazygit_config_file_path)
  if config_path then return config_path end
  print("Using default config path: " .. default_path)
  return default_path
end

-- Executes lazygit command with optional custom config and path
local function exec_lazygit(cmd, path)
  -- Verify if lazygit is available in the system
  if not utils.is_lazygit_available() then
    print("Please install lazygit. Check documentation for more information.")
    return
  end

  -- Setup and open a floating window for lazygit
  LAZYGIT.prev_win = api.nvim_get_current_win()
  LAZYGIT.win, LAZYGIT.buffer = window.open_floating_window()

  -- Use custom config path if specified
  local config_path = vim.g.lazygit_use_custom_config_file_path == 1 and get_config_path() or ""
  if config_path ~= "" then
    cmd = string.format("%s -ucf '%s'", cmd, config_path)
  end

  -- Append project path to the command if specified
  if path and vim_fn.isdirectory(path) == 1 then
    cmd = string.format("%s -p %s", cmd, path)
  end

  termopen_with_exit(cmd)
end

-- Main function to open lazygit for a given path or resolve it
local function lazygit(path)
  path = path or utils.resolve_project_path()
  exec_lazygit("lazygit", path)
end

-- Opens lazygit focused on the current file's Git repository
local function lazygit_current_file()
  local path = utils.get_git_root(vim_fn.expand("%:p:h"))
  lazygit(path)
end

-- Filters repositories in lazygit based on a given path
local function lazygit_filter(path)
  path = path or utils.project_root_dir()
  exec_lazygit("lazygit -f", path)
end

-- Opens lazygit with a filter based on the current file
local function lazygit_filter_current_file()
  local path = vim_fn.expand("%")
  lazygit_filter(path)
end

-- Opens or creates the lazygit config file
local function lazygit_config()
  local config_file = get_config_path()
  utils.open_or_create_config(config_file)
end

-- Expose functions to the outside
return {
  lazygit = lazygit,
  lazygitcurrentfile = lazygit
