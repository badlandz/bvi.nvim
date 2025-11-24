-- ~/.config/nvim/lua/bvi/ui.lua
vim.cmd.colorscheme 'industry'

-- 1. mini.statusline – the fastest thing alive
require('mini.statusline').setup {
  use_icons = true,                     -- needs nerd-fonts (you already have them in BAUX)
  content = {
    active = function()
      local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
      local git_branch   = MiniStatusline.section_git { trunc_width = 75 }
      local git_diff     = MiniStatusline.section_diff { trunc_width = 75 }
      local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
      local lsp          = MiniStatusline.section_lsp { trunc_width = 75 }
      local filename     = MiniStatusline.section_filename { trunc_width = 140 }
      local fileinfo     = MiniStatusline.section_fileinfo { trunc_width = 120 }
      local location     = MiniStatusline.section_location { trunc_width = 75 }
      local macro       = vim.fn.reg_recording() ~= '' and (' @%s '):format(vim.fn.reg_recording()) or ''

      return MiniStatusline.combine_groups {
        { hl = mode_hl,                  strings = { mode } },
        { hl = 'StatusLine',             strings = { git_branch .. git_diff } },
        '%<', -- truncation point
        { hl = 'StatusLine',             strings = { filename } },
        '%=', -- right side
        { hl = 'StatusLineDiagnostic',  strings = { diagnostics } },
        { hl = 'StatusLine',             strings = { lsp .. macro } },
        { hl = mode_hl,                  strings = { location } },
      }
    end,
    inactive = function()
      return '%F %m'
    end,
  },
}

-- 2. Enable the git/diff integration (one extra tiny plugin)
require('mini.git').setup()

-- 3. Optional eye-candy: show current indent block (super useful on small screens)
require('mini.indentscope').setup {
  symbol = '▏',      -- or '│' or '┊'
  options = { try_as_border = true },
}

-- 4. Optional: tiny cursor line scope (looks insane with gruvbox-baby)
require('mini.cursorword').setup()
