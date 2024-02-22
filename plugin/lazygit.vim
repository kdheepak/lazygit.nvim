scriptencoding utf-8

if exists('g:loaded_lazygit_vim') | finish | endif

let s:save_cpo = &cpoptions
set cpoptions&vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists('g:lazygit_floating_window_winblend')
    let g:lazygit_floating_window_winblend = 0
endif

if !exists('g:lazygit_floating_window_scaling_factor')
  let g:lazygit_floating_window_scaling_factor = 0.9
endif

if !exists('g:lazygit_use_neovim_remote')
  let g:lazygit_use_neovim_remote = executable('nvr') ? 1 : 0
endif

if exists('g:lazygit_floating_window_corner_chars')
  echohl WarningMsg
  echomsg "`g:lazygit_floating_window_corner_chars` is deprecated. Please use `g:lazygit_floating_window_border_chars` instead."
  echohl None
  if !exists('g:lazygit_floating_window_border_chars')
    let g:lazygit_floating_window_border_chars = g:lazygit_floating_window_corner_chars
  endif
endif

if !exists('g:lazygit_floating_window_border_chars')
  let g:lazygit_floating_window_border_chars = ['╭','─', '╮', '│', '╯','─', '╰', '│']
endif

" if lazygit_use_custom_config_file_path is set to 1 the
" lazygit_config_file_path option will be evaluated
if !exists('g:lazygit_use_custom_config_file_path')
  let g:lazygit_use_custom_config_file_path = 0
endif
" path to custom config file
if !exists('g:lazygit_config_file_path')
  let g:lazygit_config_file_path = ''
endif

command! LazyGit lua require'lazygit'.lazygit()

command! LazyGitCurrentFile lua require'lazygit'.lazygitcurrentfile()

command! LazyGitFilter lua require'lazygit'.lazygitfilter()

command! LazyGitFilterCurrentFile lua require'lazygit'.lazygitfiltercurrentfile()

command! LazyGitConfig lua require'lazygit'.lazygitconfig()

""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &cpoptions = s:save_cpo
unlet s:save_cpo

let g:loaded_lazygit_vim = 1
