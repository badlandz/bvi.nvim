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
