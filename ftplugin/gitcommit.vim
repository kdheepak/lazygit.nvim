if executable("nvr")
    augroup GIT
      autocmd!
      autocmd WinLeave <buffer> :LazyGit
    augroup END
end
