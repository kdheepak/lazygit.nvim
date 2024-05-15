" Check if Lazygit is already opened, if it's set to use Neovim remote,
" and if the 'nvr' command is available on the system.
if exists("g:lazygit_opened") && g:lazygit_opened && g:lazygit_use_neovim_remote && executable("nvr")
  " Create a new autocmd group for handling Neovim remote integration with Lazygit.
  augroup lazygit_neovim_remote
    autocmd!  " Clear all autocmds in the current group to avoid duplicates.

    " When the buffer is unloaded, attempt to reopen Lazygit in the project's root directory.
    " This command uses a Lua function to determine the project's root directory,
    " then schedules the reopening of Lazygit asynchronously to avoid blocking the editor.
    autocmd BufUnload <buffer> :lua local root = require('lazygit').project_root_dir(); \
                                       vim.schedule(function() require('lazygit').lazygit(root) end)

    " Additionally, when the buffer is unloaded, reset the 'lazygit_opened' flag.
    " This indicates that Lazygit is no longer open, allowing it to be reopened later.
    autocmd BufUnload <buffer> :let g:lazygit_opened=0
  augroup END  " End the autocmd group definition.
endif
