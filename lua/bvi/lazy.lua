local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  -- Manual clone with error handling for Nix weirdness
  local clone_cmd = { 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath }
  local result = vim.fn.system(clone_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('Lazy.nvim clone failed: ' .. result, vim.log.levels.ERROR)
    return
  end
end
vim.opt.rtp:prepend(lazypath)

-- INLINE your core specs here (from core.lua) — no import needed
local specs = {
  { 'nvim-lua/plenary.nvim', lazy = true },
  { 'echasnovski/mini.nvim', version = false }, -- the swiss army knife
  -- { 'folke/lazy.nvim', version = false }, -- Already bootstrapped, don't load twice

  -- IMMORTALITY
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = { options = { 'buffers', 'curdir', 'tabpages', 'winsize' } } },

  -- LAYERS FOREVER (with your BAUX cond from earlier)
  { 
    'christoomey/vim-tmux-navigator', 
    cond = function() return os.getenv("BAUX_SESSION") == "1" end,
    lazy = false,
  },

  -- ESSENTIALS
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' } },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', opts = { ensure_installed = { 'bash', 'c', 'lua', 'vim', 'python', 'arduino' } } },
  { 'neovim/nvim-lspconfig' },
  { 'lewis6991/gitsigns.nvim' },
  { 'mbbill/undotree' },
  { 'folke/which-key.nvim' },
}

require('lazy').setup(specs, {
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'tohtml',
        'zipPlugin',
      },
    },
  },
})
require 'bvi.options'
require 'bvi.keymaps'
require 'bvi.autocmds'
require 'bvi.ui'
