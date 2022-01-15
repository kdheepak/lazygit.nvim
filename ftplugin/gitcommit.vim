if exists("g:lazygit_opened") && g:lazygit_opened && g:lazygit_use_neovim_remote && executable("nvr")
    augroup lazygit_neovim_remote
      autocmd!
      autocmd BufUnload <buffer> :lua local root = require('lazygit').project_root_dir(); vim.schedule(function() require('lazygit').lazygit(root) end)
      autocmd BufUnload <buffer> :let g:lazygit_opened=0
    augroup END
end
