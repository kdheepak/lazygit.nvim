local api = vim.api

local get_scale_factor = function()
  local sf = vim.g.lazygit_floating_window_scaling_factor

  -- Why is this required? vim.g.lazygit_floating_window_scaling_factor returns different types if the value is an integer or float
  if type(sf) == "table" then
    return sf[false]
  end

  return sf
end
local get_border_chars = function()
  return vim.g.lazygit_floating_window_border_chars
end

local get_local_blend = function()
  return vim.g.lazygit_floating_window_winblend
end

local function try_load_plenary()
  local user_config_plenary = vim.g.lazygit_floating_window_use_plenary
    and vim.g.lazygit_floating_window_use_plenary ~= 0

  if not user_config_plenary then
    return false, nil
  end

  local status, plenary = pcall(require, "plenary.window.float")

  return status, plenary
end

local function open_plenary_window(buf_id, plenary)
  local win_opts = { winblend = get_local_blend() }

  if buf_id then
    win_opts.bufnr = buf_id
  end

  local sf = get_scale_factor()

  local ret = plenary.percentage_range_window(sf, sf, win_opts)
  return ret.win_id, ret.bufnr
end

local function get_window_pos()
  local sf = get_scale_factor()

  local height = math.ceil(vim.o.lines * sf) - 1
  local width = math.ceil(vim.o.columns * sf)
  local row = math.ceil(vim.o.lines - height) / 2
  local col = math.ceil(vim.o.columns - width) / 2

  return width, height, row, col
end

local function internal_open_floating_window(buf_id)
  local width, height, row, col = get_window_pos()
  local opts = {
    style = "minimal",
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = get_border_chars(),
  }

  if not buf_id then
    buf_id = api.nvim_create_buf(false, true)
  end

  -- create file window, enter the window, and use the options defined in opts
  local win = api.nvim_open_win(buf_id, true, opts)

  vim.bo[buf_id].filetype = "lazygit"
  vim.bo.bufhidden = "hide"
  vim.wo.cursorcolumn = false
  vim.wo.signcolumn = "no"
  vim.api.nvim_set_hl(0, "LazyGitBorder", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "LazyGitFloat", { link = "Normal", default = true })
  vim.wo.winhl = "FloatBorder:LazyGitBorder,NormalFloat:LazyGitFloat"
  vim.wo.winblend = get_local_blend()

  local grp = api.nvim_create_augroup("LazyGit_ResizeGrp", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = grp,
    callback = function()
      vim.defer_fn(function()
        if not vim.api.nvim_win_is_valid(win) then
          return
        end
        local new_width, new_height, new_row, new_col = get_window_pos()
        api.nvim_win_set_config(win, {
          width = new_width,
          height = new_height,
          relative = "editor",
          row = new_row,
          col = new_col,
        })
      end, 20)
    end,
  })

  return win, buf_id
end

local function open_floating_window()
  local win_id
  local buf_id
  local is_reopen = LAZYGIT_BUFFER and api.nvim_buf_is_valid(LAZYGIT_BUFFER)

  if is_reopen then
    buf_id = LAZYGIT_BUFFER
  end

  local use_plenary, plenary = try_load_plenary()

  if use_plenary then
    win_id, buf_id = open_plenary_window(buf_id, plenary)
  end

  if not win_id then
    win_id, buf_id = internal_open_floating_window(buf_id)
  end

  if is_reopen then
    LAZYGIT_LOADED = true
  end

  LAZYGIT_BUFFER = buf_id

  return win_id, buf_id
end

return {
  open_floating_window = open_floating_window,
}
