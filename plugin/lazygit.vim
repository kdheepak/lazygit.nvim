" Ensure the script is only loaded once
if exists('g:loaded_lazygit_vim') | finish | endif

" Save current 'cpoptions' and set it to Vim's default
let s:save_cpo = &cpoptions
set cpoptions&vim

" Default settings for lazygit integration
" Set default opacity of floating window if not already set
if !exists('g:lazygit_floating_window_winblend')
    let g:lazygit_floating_window_winblend = 0
endif

" Set default scaling factor for floating window if not already set
if !exists('g:lazygit_floating_window_scaling_factor')
  let g:lazygit_floating_window_scaling_factor = 0.9
endif

" Determine if neovim-remote is available and set flag accordingly
if !exists('g:lazygit_use_neovim_remote')
  let g:lazygit_use_neovim_remote = executable('nvr') ? 1 : 0
endif

" Check for deprecated corner chars setting and warn user
if exists('g:lazygit_floating_window_corner_chars')
  echohl WarningMsg
  echomsg "`g:lazygit_floating_window_corner_chars` is deprecated. Please use `g:lazygit_floating_window_border_chars` instead."
  echohl None
  " Fallback to corner chars as border chars if new setting is not present
  if !exists('g:lazygit_floating_window_border_chars')
    let g:lazygit_floating_window_border_chars = g:lazygit_floating_window_corner_chars
  endif
endif

" Set default border characters for floating window if not already set
if !exists('g:lazygit_floating_window_border_chars')
  let g:lazygit_floating_window_border_chars = ['╭','─', '╮', '│', '╯','─', '╰', '│']
endif

" Configuration file settings
" Enable/disable custom config file path
let g:lazygit_use_custom_config_file_path = 0
" Path to the custom config file
let g:lazygit_config_file_path = ''

" LazyGit commands
" Define commands to interact with LazyGit via Neovim
command! LazyGit lua require'lazygit'.lazygit()
command! LazyGitCurrentFile lua require'lazygit'.lazygitcurrentfile()
command! LazyGitFilter lua require'lazygit'.lazygitfilter()
command! LazyGitFilterCurrentFile lua require'lazygit'.lazygitfiltercurrentfile()
command! LazyGitConfig lua require'lazygit'.lazygitconfig()

" Restore original 'cpoptions' and clean up
let &cpoptions = s:save_cpo
unlet s:save_cpo

" Mark the script as loaded
let g:loaded_lazygit_vim = 1
