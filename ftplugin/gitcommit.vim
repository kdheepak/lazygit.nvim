if g:lazygit_opened && g:lazygit_use_neovim_remote && executable("nvr")
    augroup lazygit_neovim_remote
      autocmd!
      autocmd WinLeave <buffer> :LazyGit
      autocmd WinLeave <buffer> :setglobal lazygit_opened=0
    augroup END
end
