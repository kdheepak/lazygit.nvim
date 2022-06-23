local api = vim.api


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

  local opts = {
    border = 'rounded',
    style = 'minimal',
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height
  }

  local border = vim.g.lazygit_border
  if border then
    opts.border = border
  end

  -- create a unlisted scratch buffer for the border
  local border_buffer = api.nvim_create_buf(false, true)

  -- create border window
  local border_window = api.nvim_open_win(border_buffer, true, opts)
  vim.cmd 'set winhl=Normal:Floating'

  -- create a unlisted scratch buffer
  if LAZYGIT_BUFFER == nil or vim.fn.bufwinnr(LAZYGIT_BUFFER) == -1 then
    LAZYGIT_BUFFER = api.nvim_create_buf(false, true)
  else
    LAZYGIT_LOADED = true
  end
  -- create file window, enter the window, and use the options defined in opts
  local _ = api.nvim_open_win(LAZYGIT_BUFFER, true, opts)

  vim.bo[LAZYGIT_BUFFER].filetype = 'lazygit'

  vim.cmd 'setlocal bufhidden=hide'
  vim.cmd 'setlocal nocursorcolumn'
  vim.cmd('set winblend=' .. vim.g.lazygit_floating_window_winblend)

  -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
  local cmd = [[autocmd WinLeave <buffer> silent! execute 'hide']]
  vim.cmd(cmd)
  cmd = [[autocmd WinLeave <buffer> silent! execute 'silent bdelete! %s']]
  vim.cmd(cmd:format(border_buffer))
end

return {
  open_floating_window = open_floating_window,
}
