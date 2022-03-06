# lazygit.nvim

Plugin for calling [lazygit](https://github.com/jesseduffield/lazygit) from within neovim.

![](https://user-images.githubusercontent.com/1813121/87866391-79fcfe00-c93e-11ea-94a9-204947de1b39.gif)

See [akinsho/nvim-toggleterm](https://github.com/akinsho/nvim-toggleterm.lua#custom-terminals) as an alternative to this package.

### Install

Install using [`vim-plug`](https://github.com/junegunn/vim-plug):

```vim
" nvim v0.5.0
Plug 'kdheepak/lazygit.nvim'
```

Feel free to use any plugin manager.
Just remember that if you are not using the latest neovim release, you will need to use [the `nvim-v0.4.3` branch](https://github.com/kdheepak/lazygit.vim/tree/nvim-v0.4.3).
Integration with `nvr` works better on the `main` branch.

You can check what version of `neovim` you have:

```bash
nvim --version
```

### Usage

The following are configuration options and their defaults.

```vim
let g:lazygit_floating_window_winblend = 0 " transparency of floating window
let g:lazygit_floating_window_scaling_factor = 0.9 " scaling factor for floating window
let g:lazygit_floating_window_corner_chars = ['╭', '╮', '╰', '╯'] " customize lazygit popup window corner characters
let g:lazygit_floating_window_use_plenary = 0 " use plenary.nvim to manage floating window if available
let g:lazygit_use_neovim_remote = 1 " fallback to 0 if neovim-remote is not installed
```

Call `:LazyGit` to start a floating window with `lazygit`.
And set up a mapping to call `:LazyGit`:

```vim
" setup mapping to call :LazyGit
nnoremap <silent> <leader>gg :LazyGit<CR>
```

Open the configuration file for `lazygit` directly from vim.

```vim
:LazyGitConfig<CR>
```

If the file does not exist it'll load the defaults for you.

![](https://user-images.githubusercontent.com/1813121/78830902-46721580-79d8-11ea-8809-291b346b6c42.gif)

**Using neovim-remote**

If you have [neovim-remote](https://github.com/mhinz/neovim-remote) and have configured to use it in neovim, it'll launch the commit editor inside your neovim instance when you use `C` inside `lazygit`.

1. `pip install neovim-remote`

2. Add the following to your `~/.bashrc`:

```bash
if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    alias nvim=nvr -cc split --remote-wait +'set bufhidden=wipe'
fi
```

3. Set `EDITOR` environment variable in `~/.bashrc`:

```bash
if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
    export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
else
    export VISUAL="nvim"
    export EDITOR="nvim"
fi
```

4. Add the following to `~/.vimrc`:

```vim
if has('nvim') && executable('nvr')
  let $GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
endif
```

If you have `neovim-remote` and don't want `lazygit.nvim` to use it, you can disable it using the following configuration option:

```vim
let g:lazygit_use_neovim_remote = 0
```

### Telescope Plugin

the telescope Plugin is used to track all git repository visited in one nvim session.

![lazygittelplugin](https://user-images.githubusercontent.com/10464534/156933468-c89abee4-6afb-457c-8b02-55b67913aef2.png)
(background image is not included :smirk:)


__why a telescope Plugin__ ?
Assuming you have one or more submodule(s) in your project and you want to commit changes in both the submodule(s)
and the main repo. Though switching between submodules and main repo is not strait forward. My solution was at first,
1. open a file inside the submodule
2. open lazygit
3. do commit
4. then open a file in the main repo
5. open lazygit
6. do commit

that was really ennoying for me so I though about traking all repo I worked on, then I can choose from the list where I want to commit and open it with lazygit.

__how to use__
to load the telescope extension you have to add this line to your configuration
``` lua
require('telescope').load_extension('lazygit_telescope')
```

by default the paths of each repo is stored only when lazygit is triggered. Though, this may not be convenient, so it possible to do something like this:
``` vim
    autocmd BufEnter * :lua require('lazygit.utils').project_root_dir()
```

that make sure that any opened buffer which is contained in a git repo will be tracked.

invoke the plugin:
```lua
lua require("telescope").extensions.lazygit_telescope.lazygit()
```
