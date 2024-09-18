# lazygit.nvim

Plugin for calling [lazygit](https://github.com/jesseduffield/lazygit) from within neovim.

![](https://user-images.githubusercontent.com/1813121/87866391-79fcfe00-c93e-11ea-94a9-204947de1b39.gif)

See [akinsho/nvim-toggleterm](https://github.com/akinsho/nvim-toggleterm.lua#custom-terminals) or [voldikss/vim-floaterm](https://github.com/voldikss/vim-floaterm) as an alternative to this package.

### Install

Install using [`vim-plug`](https://github.com/junegunn/vim-plug):

```vim
" nvim v0.7.2
Plug 'kdheepak/lazygit.nvim'
```

Install using [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
-- nvim v0.7.2
use({
    "kdheepak/lazygit.nvim",
    -- optional for floating window border decoration
    requires = {
        "nvim-lua/plenary.nvim",
    },
})
```

Install using [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
-- nvim v0.8.0
return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- setting the keybinding for LazyGit with 'keys' is recommended in
  -- order to load the plugin when the command is run for the first time
  keys = {
    { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
  }
}
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
let g:lazygit_floating_window_border_chars = ['╭','─', '╮', '│', '╯','─', '╰', '│'] " customize lazygit popup window border characters
let g:lazygit_floating_window_use_plenary = 0 " use plenary.nvim to manage floating window if available
let g:lazygit_use_neovim_remote = 1 " fallback to 0 if neovim-remote is not installed

let g:lazygit_use_custom_config_file_path = 0 " config file path is evaluated if this value is 1
let g:lazygit_config_file_path = '' " custom config file path
" OR
let g:lazygit_config_file_path = [] " list of custom config file paths
```

```lua
vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window
vim.g.lazygit_floating_window_scaling_factor = 0.9 -- scaling factor for floating window
vim.g.lazygit_floating_window_border_chars = {'╭','─', '╮', '│', '╯','─', '╰', '│'} -- customize lazygit popup window border characters
vim.g.lazygit_floating_window_use_plenary = 0 -- use plenary.nvim to manage floating window if available
vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed

vim.g.lazygit_use_custom_config_file_path = 0 -- config file path is evaluated if this value is 1
vim.g.lazygit_config_file_path = '' -- custom config file path
-- OR
vim.g.lazygit_config_file_path = {} -- table of custom config file paths
```

Call `:LazyGit` to start a floating window with `lazygit` in the current working directory.
And set up a mapping to call `:LazyGit`:

```vim
" setup mapping to call :LazyGit
nnoremap <silent> <leader>gg :LazyGit<CR>
```

Call `:LazyGitCurrentFile` to start a floating window with `lazygit` in the project root of the current file.

Open the configuration file for `lazygit` directly from vim.

```vim
:LazyGitConfig<CR>
```

If the file does not exist it'll load the defaults for you.

![](https://user-images.githubusercontent.com/1813121/78830902-46721580-79d8-11ea-8809-291b346b6c42.gif)

Open project commits with `lazygit` directly from vim in floating window.

```vim
:LazyGitFilter<CR>
```

Open buffer commits with `lazygit` directly from vim in floating window.

```vim
:LazyGitFilterCurrentFile<CR>
```

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

**Using nvim --listen and nvim --server to edit files in same process**

You can use vanilla nvim server to edit files in the same nvim instance when you use `e` inside `lazygit`.

1. You have to start nvim with the `--listen` parameter. An easy way to ensure this is to use an alias:
```bash
# ~/.bashrc
alias vim='nvim --listen /tmp/nvim-server.pipe'
```

2. You have to modify lazygit to attempt connecting to existing nvim instance on edit:
```yml
# ~/.config/jesseduffield/lazygit/config.yml
os:
  editCommand: 'nvim'
  editCommandTemplate: '{{editor}} --server /tmp/nvim-server.pipe --remote-tab "$(pwd)/{{filename}}"'
```

### Telescope Plugin

The Telescope plugin is used to track all git repository visited in one nvim session.

**Why a telescope Plugin** ?

Assuming you have one or more submodule(s) in your project and you want to commit changes in both the submodule(s)
and the main repo.
Though switching between submodules and main repo is not straight forward.
A solution at first could be:

1. open a file inside the submodule
2. open lazygit
3. do commit
4. then open a file in the main repo
5. open lazygit
6. do commit

That is really annoying.
Instead, you can open it with telescope.

**How to use**

Install using [`packer.nvim`](https://github.com/wbthomason/packer.nvim):

```lua
-- nvim v0.7.2
use({
    "kdheepak/lazygit.nvim",
    requires = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("telescope").load_extension("lazygit")
    end,
})
```

Install using [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
-- nvim v0.8.0
require("lazy").setup({
    {
        "kdheepak/lazygit.nvim",
        dependencies =  {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim"
        },
        config = function()
            require("telescope").load_extension("lazygit")
        end,
    },
})
```

Lazy loading `lazygit.nvim` for telescope functionality is not supported. Open an issue if you wish to have this feature.

If you are not using Packer, to load the telescope extension, you have to add this line to your configuration:

```lua
require('telescope').load_extension('lazygit')
```

By default the paths of each repo is stored only when lazygit is triggered.
Though, this may not be convenient, so it possible to do something like this:

```vim
autocmd BufEnter * :lua require('lazygit.utils').project_root_dir()
```

That makes sure that any opened buffer which is contained in a git repo will be tracked.

Once you have loaded the extension, you can invoke the plugin using:

```lua
lua require("telescope").extensions.lazygit.lazygit()
```

### Highlighting groups

| Highlight Group   | Default Group | Description                              |
| ------------------| --------------| -----------------------------------------|
| **LazyGitFloat**  | **_Normal_**  | Float terminal foreground and background |
| **LazyGitBorder** | **_Normal_**  | Float terminal border                    |
