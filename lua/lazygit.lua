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
local worktree_state = nil
local worktree_new_dir_file = nil
local path_sep = package.config:sub(1, 1)

local function normalize_path(path)
  if path == nil or path == "" then
    return nil
  end
  local normalized = fn.fnamemodify(path, ":p")
  local uv = vim.uv or vim.loop
  if uv and uv.fs_realpath then
    local realpath = uv.fs_realpath(normalized)
    if realpath ~= nil then
      normalized = realpath
    end
  else
    local resolved = fn.resolve(normalized)
    if resolved ~= nil and resolved ~= "" then
      normalized = resolved
    end
  end
  if normalized:sub(-1) == path_sep then
    normalized = normalized:sub(1, -2)
  end
  return normalized
end

local function is_path_in_root(path, root)
  if path == nil or root == nil then
    return false
  end
  if path == root then
    return false
  end
  if path:sub(1, #root) ~= root then
    return false
  end
  local next_char = path:sub(#root + 1, #root + 1)
  return next_char == path_sep
end

local function file_exists(path)
  return path ~= nil and fn.filereadable(path) == 1
end

local function capture_worktree_state()
  local root = project_root_dir()
  if root == nil then
    return nil
  end
  root = normalize_path(root)
  if root == nil then
    return nil
  end

  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        local ft = vim.bo[buf].filetype
        local path = name
        local real_path = nil
        if ft == "oil" then
          real_path = normalize_path(name:gsub("^oil://", ""))
        else
          path = normalize_path(name)
        end
        table.insert(buffers, {
          buf = buf,
          path = path,
          real_path = real_path,
          ft = ft,
          modified = vim.bo[buf].modified,
        })
      end
    end
  end

  local windows = {}
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    windows[win_id] = vim.api.nvim_win_get_buf(win_id)
  end

  return {
    root = root,
    buffers = buffers,
    windows = windows,
  }
end

local function read_new_worktree_root()
  if worktree_new_dir_file == nil then
    return nil
  end
  local ok, lines = pcall(fn.readfile, worktree_new_dir_file)
  if not ok or lines == nil or #lines == 0 then
    return nil
  end
  local new_dir = lines[1]
  if new_dir == nil then
    return nil
  end
  new_dir = new_dir:gsub("^%s+", ""):gsub("%s+$", "")
  if new_dir == "" then
    return nil
  end
  local root = get_root(new_dir) or new_dir
  return normalize_path(root)
end

local function clear_worktree_state()
  if worktree_new_dir_file ~= nil then
    pcall(os.remove, worktree_new_dir_file)
  end
  worktree_new_dir_file = nil
  worktree_state = nil
end

local function sync_worktree(state)
  local new_root = read_new_worktree_root()
  if state == nil or state.root == nil or new_root == nil or new_root == state.root then
    return
  end
  if fn.isdirectory(new_root) == 0 then
    return
  end

  local buf_to_new_path = {}
  for _, info in ipairs(state.buffers) do
    if info.ft == "oil" then
      local oil_path = info.real_path
      if oil_path then
        if oil_path == state.root then
          buf_to_new_path[info.buf] = "oil://" .. new_root
        elseif is_path_in_root(oil_path, state.root) then
          local rel = oil_path:sub(#state.root + 2)
          if rel ~= nil and rel ~= "" then
            local new_dir = new_root .. path_sep .. rel
            buf_to_new_path[info.buf] = "oil://" .. new_dir
          end
        end
      end
    elseif info.path and is_path_in_root(info.path, state.root) then
      local rel = info.path:sub(#state.root + 2)
      if rel ~= nil and rel ~= "" then
        local new_path = new_root .. path_sep .. rel
        if file_exists(new_path) then
          buf_to_new_path[info.buf] = new_path
        else
          buf_to_new_path[info.buf] = false
        end
      end
    end
  end

  local new_buf_cache = {}
  local function get_new_buf(path)
    if new_buf_cache[path] and vim.api.nvim_buf_is_valid(new_buf_cache[path]) then
      return new_buf_cache[path]
    end
    local buf = fn.bufadd(path)
    fn.bufload(buf)
    new_buf_cache[path] = buf
    return buf
  end

  for win_id, buf in pairs(state.windows) do
    if vim.api.nvim_win_is_valid(win_id) and buf_to_new_path[buf] ~= nil then
      local new_path = buf_to_new_path[buf]
      if new_path then
        local new_buf = get_new_buf(new_path)
        pcall(vim.api.nvim_win_set_buf, win_id, new_buf)
      end
    end
  end

  vim.api.nvim_set_current_dir(new_root)
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win_id) then
      pcall(vim.api.nvim_win_call, win_id, function()
        vim.cmd("silent! lcd " .. fn.fnameescape(new_root))
      end)
    end
  end

  local kept_modified = {}
  for buf, _ in pairs(buf_to_new_path) do
    if vim.api.nvim_buf_is_valid(buf) then
      if vim.bo[buf].modified then
        table.insert(kept_modified, vim.api.nvim_buf_get_name(buf))
      else
        pcall(vim.api.nvim_buf_delete, buf, { force = false })
      end
    end
  end

  if #kept_modified > 0 then
    vim.schedule(function()
      vim.notify(
        "lazygit.nvim: kept " .. #kept_modified .. " modified buffer(s) from previous worktree",
        vim.log.levels.WARN
      )
    end)
  end
end

--- on_exit callback function to delete the open buffer when lazygit exits in a neovim terminal
local function on_exit(job_id, code, event)
  if vim.g.lazygit_worktree_switch == 1 and worktree_state ~= nil then
    sync_worktree(worktree_state)
  end
  clear_worktree_state()
  if code ~= 0 then
    return
  end

  LAZYGIT_BUFFER = nil
  LAZYGIT_LOADED = false
  vim.g.lazygit_opened = 0
  vim.cmd("silent! :checktime")

  if vim.api.nvim_win_is_valid(prev_win) then
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.api.nvim_set_current_win(prev_win)
    prev_win = -1
    if vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
    buffer = -1
    win = -1
  end

  if vim.g.lazygit_on_exit_callback ~= nil then
    vim.g.lazygit_on_exit_callback()
  end
end

--- Call lazygit
local function exec_lazygit_command(cmd)
  if LAZYGIT_LOADED == false then
    -- ensure that the buffer is closed on exit
    vim.g.lazygit_opened = 1

    local command
    if type(cmd) == "string" then
      -- Split string into table of arguments
      command = {}
      for arg in string.gmatch(cmd, "%S+") do
        table.insert(command, arg)
      end
    else
      -- cmd is already a table
      command = cmd
    end

    vim.schedule(function()
      local opts = { term = true, on_exit = on_exit }
      if vim.g.lazygit_worktree_switch == 1 then
        worktree_state = capture_worktree_state()
        if worktree_state ~= nil then
          worktree_new_dir_file = fn.tempname()
          local base_env = fn.environ()
          base_env.LAZYGIT_NEW_DIR_FILE = worktree_new_dir_file
          opts.env = base_env
        end
      end
      vim.fn.jobstart(command, opts)
    end)
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
          print(
            "lazygit: custom config file path: '" .. config_file .. "' could not be found. Returning default config"
          )
          return default_config_path
        end
      end
      return vim.g.lazygit_config_file_path
    elseif fn.empty(fn.glob(vim.g.lazygit_config_file_path)) == 0 then
      return vim.g.lazygit_config_file_path
    else
      print(
        "lazygit: custom config file path: '"
          .. vim.g.lazygit_config_file_path
          .. "' could not be found. Returning default config"
      )
      return default_config_path
    end
  else
    print("lazygit: custom config file path is not set, option: 'lazygit_config_file_path' is missing")
    -- any issue with the config file we fallback to the default config file path
    return default_config_path
  end
end

--- :LazyGitLog entry point
local function lazygitlog(path)
  if is_lazygit_available() ~= true then
    print("Please install lazygit. Check documentation for more information")
    return
  end

  prev_win = vim.api.nvim_get_current_win()

  win, buffer = open_floating_window()

  local cmd = { "lazygit", "log" }

  -- set path to the root path
  _ = project_root_dir()

  if vim.g.lazygit_use_custom_config_file_path == 1 then
    local config_path = lazygitgetconfigpath()
    if type(config_path) == "table" then
      config_path = table.concat(config_path, ",")
    end
    table.insert(cmd, "-ucf")
    table.insert(cmd, config_path)
  end

  if vim.env.GIT_DIR ~= nil and vim.env.GIT_WORK_TREE ~= nil then
    table.insert(cmd, "-w")
    table.insert(cmd, vim.env.GIT_WORK_TREE)
    table.insert(cmd, "-g")
    table.insert(cmd, vim.env.GIT_DIR)
  elseif path == nil then
    if is_symlink() then
      path = project_root_dir()
    end
  else
    if fn.isdirectory(path) then
      table.insert(cmd, "-p")
      table.insert(cmd, path)
    end
  end

  exec_lazygit_command(cmd)
end

--- :LazyGit entry point
local function lazygit(path)
  if is_lazygit_available() ~= true then
    print("Please install lazygit. Check documentation for more information")
    return
  end

  prev_win = vim.api.nvim_get_current_win()

  win, buffer = open_floating_window()

  local cmd = { "lazygit" }

  -- set path to the root path
  _ = project_root_dir()

  if vim.g.lazygit_use_custom_config_file_path == 1 then
    local config_path = lazygitgetconfigpath()
    if type(config_path) == "table" then
      config_path = table.concat(config_path, ",")
    end
    table.insert(cmd, "-ucf")
    table.insert(cmd, config_path)
  end

  if vim.env.GIT_DIR ~= nil and vim.env.GIT_WORK_TREE ~= nil then
    table.insert(cmd, "-w")
    table.insert(cmd, vim.env.GIT_WORK_TREE)
    table.insert(cmd, "-g")
    table.insert(cmd, vim.env.GIT_DIR)
  elseif path == nil then
    if is_symlink() then
      path = project_root_dir()
    end
  else
    if fn.isdirectory(path) then
      table.insert(cmd, "-p")
      table.insert(cmd, path)
    end
  end

  exec_lazygit_command(cmd)
end

--- :LazyGitCurrentFile entry point
local function lazygitcurrentfile()
  local current_dir
  if vim.bo.buftype == "terminal" then
    current_dir = vim.fn.getcwd()
  else
    current_dir = vim.fn.expand("%:p:h")
  end
  local git_root = get_root(current_dir)
  lazygit(git_root)
end

--- :LazyGitFilter entry point
local function lazygitfilter(path, git_root)
  if is_lazygit_available() ~= true then
    print("Please install lazygit. Check documentation for more information")
    return
  end
  if path == nil then
    path = project_root_dir()
  end
  prev_win = vim.api.nvim_get_current_win()
  win, buffer = open_floating_window()

  local cmd = { "lazygit", "-f", path }
  if git_root and (not vim.env.GIT_DIR and not vim.env.GIT_WORK_TREE) then
    table.insert(cmd, "-p")
    table.insert(cmd, git_root)
  end

  exec_lazygit_command(cmd)
end

--- :LazyGitFilterCurrentFile entry point
local function lazygitfiltercurrentfile()
  if vim.bo.buftype == "terminal" then
    print("LazyGitFilterCurrentFile is not available from terminal buffers")
    return
  end
  local current_dir = vim.fn.expand("%:p:h")
  local git_root = get_root(current_dir)
  local file_path = vim.fn.expand("%:p")
  local relative_path = string.sub(file_path, #git_root + 2)
  lazygitfilter(relative_path, git_root)
end

--- :LazyGitConfig entry point
local function lazygitconfig()
  local config_file = lazygitgetconfigpath()

  if type(config_file) == "table" then
    vim.ui.select(config_file, { prompt = "select config file to edit" }, function(path)
      open_or_create_config(path)
    end)
  else
    open_or_create_config(config_file)
  end
end

return {
  lazygit = lazygit,
  lazygitlog = lazygitlog,
  lazygitcurrentfile = lazygitcurrentfile,
  lazygitfilter = lazygitfilter,
  lazygitfiltercurrentfile = lazygitfiltercurrentfile,
  lazygitconfig = lazygitconfig,
  project_root_dir = project_root_dir,
}
