# lazygit.vim

Plugin for calling lazygit from within neovim.

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

```vim
" lazygit
nnoremap <silent> <leader>lg :LazyGit<CR>
```

### Using neovim-remote

Add the following to your `.gitconfig` to use your current neovim instance at the commit editor for git.

```
[core]
  editor = nvr --remote-wait-silent
```
