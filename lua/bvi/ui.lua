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
