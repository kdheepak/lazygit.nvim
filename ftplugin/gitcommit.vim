if g:lazygit_use_neovim_remote && executable("nvr")
    augroup lazygit_neovim_remote
      autocmd!
      autocmd WinLeave <buffer> :LazyGit
    augroup END
end
