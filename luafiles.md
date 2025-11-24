cat findme.sh  >> luafiles.md

cat ./nvim/init.lua >> luafiles.md
cat ./nvim/lua/plugins/core.lua >> luafiles.md
cat ./nvim/lua/bvi/autocmds.lua >> luafiles.md
cat ./nvim/lua/bvi/ui.lua >> luafiles.md
cat ./nvim/lua/bvi/keymaps.lua >> luafiles.md
cat ./nvim/lua/bvi/options.lua >> luafiles.md
cat ./nvim/lua/bvi/lazy.lua >> luafiles.md
-- ~/.config/nvim/init.lua
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require 'bvi.lazy' -- this sets up lazy.nvim and loads everything else
-- ~/.config/nvim/lua/plugins/core.lua
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
-- lua/bvi/autocmds.lua
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  command = [[%s/\s\+$//e]], -- strip trailing whitespace
})

-- Auto-restore session on startup (works with tmux-resurrect)
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() == 0 then
      require('persistence').load()
    end
  end,
  nested = true,
})
-- lua/bvi/ui.lua
vim.cmd.colorscheme 'gruvbox-baby' -- or catppuccin, everforest, etc.

require('mini.statusline').setup {
  content = {
    active = function()
      return require('mini.statusline').combine_groups {
        { hl = 'StatusLine', strings = { ' BVI ' } },
        '%f%m%r%h%w',
        '%=',
        '%l:%c %p%%',
      }
    end,
  },
}

require('mini.starter').setup {
  items = {
    { name = 'Restore session', action = "lua require('persistence').load()", section = 'BAUX' },
    { name = 'New file', action = 'enew', section = 'BAUX' },
    { name = 'Quit', action = 'qall', section = 'BAUX' },
  },
  header = [[
 
 

.#####...##..##..######.
.##..##..##..##....##...
.#####...##..##....##...
.##..##...####.....##...
.#####.....##....######.
........................]],
}
-- lua/bvi/keymaps.lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader is space – sacred
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Better window navigation (works with vim-tmux-navigator)
map('n', '<A-h>', '<C-w>h', opts)
map('n', '<A-j>', '<C-w>j', opts)
map('n', '<A-k>', '<C-w>k', opts)
map('n', '<A-l>', '<C-w>l', opts)

-- Resize with arrows (because Pi Zero keyboards have arrows)
map('n', '<C-Up>', ':resize +2<CR>', opts)
map('n', '<C-Down>', ':resize -2<CR>', opts)
map('n', '<C-Left>', ':vertical resize -2<CR>', opts)
map('n', '<C-Right>', ':vertical resize +2<CR>', opts)

-- Better indenting
map('v', '<', '<gv', opts)
map('v', '>', '>gv', opts)

-- Escape is CapsLock already – jk is redundant but everyone loves it
map('i', 'jk', '<ESC>', opts)

-- Leader shortcuts – Primagen / kickstart style but BAUX-aligned
map('n', '<leader>pv', ':Ex<CR>', opts) -- netrw → we’ll replace with mini.files later
map('n', '<leader>u', ':UndotreeToggle<CR>', opts)
map('n', '<leader>gs', ':Gitsigns stage_hunk<CR>', opts)
map('n', '<leader>gr', ':Gitsigns reset_hunk<CR>', opts)

-- Telescope – the real file finder
local builtin = require 'telescope.builtin'
map('n', '<leader>ff', builtin.find_files, opts)
map('n', '<leader>fg', builtin.live_grep, opts)
map('n', '<leader>fb', builtin.buffers, opts)
map('n', '<leader>fh', builtin.help_tags, opts)

-- Persistence (immortality)
map('n', '<leader>qs', function()
  require('persistence').load()
end, opts)
map('n', '<leader>ql', function()
  require('persistence').load { last = true }
end, opts)
-- lua/bvi/options.lua
local opt = vim.opt

opt.mouse = 'a'
opt.clipboard = 'unnamedplus'
opt.swapfile = false
opt.undofile = true
opt.undodir = os.getenv 'HOME' .. '/.cache/bvi/undo'
opt.termguicolors = true
opt.signcolumn = 'yes'
opt.updatetime = 100
opt.timeoutlen = 300
opt.inccommand = 'split' -- live :%s preview
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.splitright = true
opt.splitbelow = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
-- lua/bvi/lazy.lua
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  spec = {
    { import = 'bvi.plugins' }, -- later you can have bvi.plugins.extra for baux-dev
  },
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
}
require 'bvi.options'
require 'bvi.keymaps'
require 'bvi.autocmds'
require 'bvi.ui'
