scriptencoding utf-8

if exists('g:loaded_lazygit_vim') | finish | endif

let s:save_cpo = &cpoptions
set cpoptions&vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:lazygit_lua_loc =  expand('<sfile>:h:r') . '/../lua/'

exe "lua package.path = package.path .. ';". s:lazygit_lua_loc."?/init.lua'"
exe "lua package.path = package.path .. ';". s:lazygit_lua_loc."?.lua'"

command! LazyGit lua require'lazygit'.lazygit()

""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &cpoptions = s:save_cpo
unlet s:save_cpo

let g:loaded_lazygit_vim = 1
