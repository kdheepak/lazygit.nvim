local fn = vim.fn

-- store all git repositories visited in this session
local lazygit_visited_git_repos = {}

-- TODO:check if the repo isa git repo
local function append_git_repo_path(repo_path)
  if repo_path == nil or not fn.isdirectory(repo_path) then
    return
  end

  for _, path in ipairs(lazygit_visited_git_repos) do
    if path == repo_path then
      return
    end
  end

  table.insert(lazygit_visited_git_repos, tostring(repo_path))
end


--- Strip leading and lagging whitespace
local function trim(str)
  return str:gsub('^%s+', ''):gsub('%s+$', '')
end


local function get_root(cwd)
  local status, job = pcall(require, 'plenary.job')
  if not status then
    return fn.system('git rev-parse --show-toplevel')
  end

  local gitroot_job = job:new({
    'git',
    'rev-parse',
    '--show-toplevel',
    cwd=cwd
  })

  local path, code = gitroot_job:sync()
  if (code ~= 0) then
    return nil
  end

  return table.concat(path, "")
end

--- Get project_root_dir for git repository
local function project_root_dir()
  -- always use bash on Unix based systems.
  local oldshell = vim.o.shell
  if vim.fn.has('win32') == 0 then
    vim.o.shell = 'bash'
  end

  local cwd = vim.loop.cwd()
  local root = get_root(cwd)
  if root == nil then
    vim.o.shell = oldshell
    return nil
  end

  local cmd = string.format('cd "%s" && git rev-parse --show-toplevel', fn.fnamemodify(fn.resolve(fn.expand('%:p')), ':h'), root)
  -- try symlinked file location instead
  local gitdir = fn.system(cmd)
  local isgitdir = fn.matchstr(gitdir, '^fatal:.*') == ''

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

--- Check if lazygit is available
local function is_lazygit_available()
  return fn.executable('lazygit') == 1
end

local function is_symlink()
  local resolved = fn.resolve(fn.expand('%:p'))
  return resolved ~= fn.expand('%:p')
end

local function open_or_create_config(path)
  if fn.empty(fn.glob(path)) == 1 then
    -- file does not exist
    -- check if user wants to create it
    local answer = fn.confirm(
      "File "
        .. path
        .. " does not exist.\nDo you want to create the file and populate it with the default configuration?",
      "&Yes\n&No"
    )
    if answer == 2 then
      return nil
    end
    if fn.isdirectory(fn.fnamemodify(path, ":h")) == false then
      -- directory does not exist
      fn.mkdir(fn.fnamemodify(path, ":h"), "p")
    end
    vim.cmd("edit " .. path)
    vim.cmd([[execute "silent! 0read !lazygit -c"]])
    vim.cmd([[execute "normal 1G"]])
  else
    vim.cmd("edit " .. path)
  end
end

return {
  get_root = get_root,
  project_root_dir = project_root_dir,
  lazygit_visited_git_repos = lazygit_visited_git_repos,
  is_lazygit_available = is_lazygit_available,
  is_symlink = is_symlink,
  open_or_create_config = open_or_create_config,
}
