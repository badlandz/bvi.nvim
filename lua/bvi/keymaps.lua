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
