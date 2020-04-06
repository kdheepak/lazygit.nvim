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

lua require 'lazygit'.setup()

let s:lazygit_lua_loc =  expand('<sfile>:h:r') . '/../lua/'

exe "lua package.path = package.path .. ';". s:lazygit_lua_loc."?/init.lua'"
exe "lua package.path = package.path .. ';". s:lazygit_lua_loc."?.lua'"

command! LazyGit lua require'lazygit'.lazygit()

""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &cpoptions = s:save_cpo
unlet s:save_cpo

let g:loaded_lazygit_vim = 1
