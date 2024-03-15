-- Import necessary modules from `lazygit` package.
local window = require("lazygit.window")
local utils = require("lazygit.utils")
local fn = vim.fn

-- Global variables to keep track of lazygit buffer, load state, and vim global variable.
LAZYGIT_BUFFER = nil
LAZYGIT_LOADED = false
vim.g.lazygit_opened = 0

-- Variables to keep track of previous and current window and buffer IDs.
local prev_win = -1
local win = -1
local buffer = -1

--- Handles the exit event of the lazygit process.
-- Cleans up by closing buffers and windows.
-- @param job_id The job ID of the exited process.
-- @param code The exit code of the process.
-- @param event The event that triggered the exit.
local function on_exit(job_id, code, event)
  if code ~= 0 then
    return
  end

  -- Reset global variables and states.
  LAZYGIT_BUFFER = nil
  LAZYGIT_LOADED = false
  vim.g.lazygit_opened = 0
  vim.cmd("silent! :checktime")

  -- Close the floating window and delete the buffer if they are valid.
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

--- Executes the lazygit command in a terminal buffer.
-- @param cmd The lazygit command to execute.
local function exec_lazygit_command(cmd)
  if not LAZYGIT_LOADED then
    vim.g.lazygit_opened = 1
    vim.fn.termopen(cmd, { on_exit = on_exit })
  end
  vim.cmd("startinsert")
end

--- Retrieves the default config path for lazygit.
-- @return The path to the default lazygit config file.
local function lazygit_default_config_path()
  return fn.substitute(fn.system("lazygit -cd"), "\n", "", "") .. "/config.yml"
end

--- Determines the lazygit config path, handling custom configurations.
-- @return The path to the lazygit config file.
local function lazygit_get_config_path()
  local default_config_path = lazygit_default_config_path()

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
    return default_config_path
  end
end

--- Main entry point for the LazyGit command.
-- Opens lazygit in a floating window within Neovim.
-- @param path The path to open lazygit with. If nil, uses the project root.
local function lazygit(path)
  if not utils.is_lazygit_available() then
    print("Please install lazygit. Check documentation for more information")
    return
  end

  prev_win = vim.api.nvim_get_current_win()
  win, buffer = window.open_floating_window()

  local cmd = "lazygit"

  -- Determine the path to use with lazygit.
  if vim.g.lazygit_use_custom_config_file_path == 1 then
    local config_path = lazygit_get_config_path()
    if type(config_path) == "table" then
      config_path = table.concat(config_path, ",")
    end
    cmd = cmd .. " -ucf '" .. config_path .. "'"
  end

  -- Configure path if provided and valid.
  if path then
    if fn.is
