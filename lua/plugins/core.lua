-- ~/.config/bvi/lua/plugins/core.lua
return {
  { 'nvim-lua/plenary.nvim', lazy = true },
  { 'echasnovski/mini.nvim', version = false }, -- the swiss army knife
  { 'folke/lazy.nvim', version = false },

  -- IMMORTALITY
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = { options = { 'buffers', 'curdir', 'tabpages', 'winsize' } } },

  -- LAYERS FOREVER
  { 'christoomey/vim-tmux-navigator', lazy = false },

  -- ESSENTIALS
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' } },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', opts = { ensure_installed = { 'bash', 'c', 'lua', 'vim', 'python', 'arduino' } } },
  { 'neovim/nvim-lspconfig' },
  { 'lewis6991/gitsigns.nvim' },
  { 'mbbill/undotree' },
  { 'folke/which-key.nvim' },
}
