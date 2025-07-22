local api = vim.api

local function get_window_pos()
  local floating_window_scaling_factor = vim.g.lazygit_floating_window_scaling_factor

  -- Why is this required?
  -- vim.g.lazygit_floating_window_scaling_factor returns different types if the value is an integer or float
  if type(floating_window_scaling_factor) == 'table' then
    floating_window_scaling_factor = floating_window_scaling_factor[false]
  end

  local status, plenary = pcall(require, 'plenary.window.float')
  if status and vim.g.lazygit_floating_window_use_plenary and vim.g.lazygit_floating_window_use_plenary ~= 0 then
    local ret = plenary.percentage_range_window(
      floating_window_scaling_factor,
      floating_window_scaling_factor,
      { winblend = vim.g.lazygit_floating_window_winblend }
    )
    return nil, nil, nil, nil, ret.win_id, ret.bufnr
  end

  local height = math.ceil(vim.o.lines * floating_window_scaling_factor) - 1
  local width = math.ceil(vim.o.columns * floating_window_scaling_factor)
  local row = math.ceil(vim.o.lines - height) / 2
  local col = math.ceil(vim.o.columns - width) / 2
  return width, height, row, col
end

--- open floating window with nice borders
local function open_floating_window()
  local width, height, row, col, plenary_win, plenary_buf = get_window_pos()
  if plenary_win and plenary_buf then
    return plenary_win, plenary_buf
  end

  local opts = {
    style = "minimal",
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = vim.g.lazygit_floating_window_border_chars,
  }

  -- create a unlisted scratch buffer
  if LAZYGIT_BUFFER == nil or vim.fn.bufwinnr(LAZYGIT_BUFFER) == -1 then
    LAZYGIT_BUFFER = api.nvim_create_buf(false, true)
  else
    LAZYGIT_LOADED = true
  end

  -- create file window, enter the window, and use the options defined in opts
  local win = api.nvim_open_win(LAZYGIT_BUFFER, true, opts)

  vim.bo[LAZYGIT_BUFFER].filetype = 'lazygit'

  vim.bo.bufhidden = 'hide'
  vim.wo.cursorcolumn = false
  vim.wo.signcolumn = 'no'
  vim.api.nvim_set_hl(0, "LazyGitBorder", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "LazyGitFloat", { link = "Normal", default = true })
  vim.wo.winhl = 'FloatBorder:LazyGitBorder,NormalFloat:LazyGitFloat'
  vim.wo.winblend = vim.g.lazygit_floating_window_winblend

  vim.api.nvim_create_autocmd('VimResized', {
    callback = function()
      vim.defer_fn(function()
        if not vim.api.nvim_win_is_valid(win) then
          return
        end
        local new_width, new_height, new_row, new_col = get_window_pos()
        api.nvim_win_set_config(
          win,
          {
            width = new_width,
            height = new_height,
            relative = "editor",
            row = new_row,
            col = new_col,
          }
        )
      end, 20)
    end,
  })

  return win, LAZYGIT_BUFFER
end

return {
  open_floating_window = open_floating_window,
}
