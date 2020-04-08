# lazygit.vim

Plugin for calling [lazygit](https://github.com/jesseduffield/lazygit) from within neovim.

![](https://user-images.githubusercontent.com/1813121/78614672-b8beea80-785e-11ea-8fd2-835b385ed6da.gif)

### Install

Use any plugin manager:

**[vim-plug](https://github.com/junegunn/vim-plug)**

```vim
Plug 'kdheepak/lazygit.vim'
```

**[dein.vim](https://github.com/Shougo/dein.vim)**

```vim
call dein#add('kdheepak/lazygit.vim')
```

**[Vundle.vim](https://github.com/junegunn/vim-plug)**

```vim
Plugin 'kdheepak/lazygit.vim'
```

### Usage

The following are configuration options and their defaults.

```vim
let g:lazygit_floating_window_winblend = 0 " transparency of floating window
let g:lazygit_floating_window_scaling_factor = 0.9 " scaling factor for floating window
```

Call `:LazyGit` to start a floating window with `lazygit`.
And set up a mapping to call `:LazyGit`:

```vim
" setup mapping to call :LazyGit
nnoremap <silent> <leader>lg :LazyGit<CR>
```

Open the configuration file for `lazygit` directly from vim.

```vim
:LazyGitConfig<CR>
```

If the file does not exist it'll load the defaults for you.

![](https://user-images.githubusercontent.com/1813121/78830902-46721580-79d8-11ea-8809-291b346b6c42.gif)
