-- Minimal Neovim Lua configuration for testing lazygit.nvim using lazy.nvim
-- Save this as init.lua and run with: nvim -u init.lua

-- Basic settings
vim.opt.compatible = false

-- Set leader key (must be set before lazy setup)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Set built-in colorscheme
vim.cmd([[colorscheme vim]])

-- Install lazy.nvim if it doesn't exist
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup using lazy.nvim
require("lazy").setup({
  {
    dir = "~/gitrepos/lazygit.nvim",
    name = "lazygit.nvim",
    config = function()
      -- Keybinding for LazyGit
      vim.keymap.set("n", "<leader>lg", ":LazyGit<CR>", {
        silent = true,
        desc = "Open LazyGit",
      })
    end,
  },
})

-- Instructions: Save this file and run `nvim -u init.lua` then type `<leader>lg` in normal mode
