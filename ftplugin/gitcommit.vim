if g:lazygit_use_neovim_remote && executable("nvr")
    augroup GIT
      autocmd!
      autocmd WinLeave <buffer> :LazyGit
    augroup END
end
