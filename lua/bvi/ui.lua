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

-- 5. BVI AI UI Enhancements
local M = {}

-- Spinner for async operations
M.show_spinner = function(message)
  local spinner_chars = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local spinner_idx = 1
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, false, {
    relative = 'editor',
    width = 30,
    height = 1,
    row = vim.o.lines - 5,
    col = vim.o.columns - 35,
    style = 'minimal',
    border = 'rounded'
  })

  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        string.format("%s %s", spinner_chars[spinner_idx], message or "Loading...")
      })
      spinner_idx = (spinner_idx % #spinner_chars) + 1
    else
      timer:stop()
      timer:close()
    end
  end))

  return {
    hide = function()
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
      end
      timer:stop()
      timer:close()
    end
  }
end

-- Show AI response in a floating window
M.show_ai_response = function(content, title)
  -- Split content into lines
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)

  -- Calculate window size
  local width = math.min(80, vim.o.columns - 10)
  local height = math.min(20, #lines + 2)

  -- Create floating window
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = title or "AI Response",
    title_pos = 'center'
  })

  -- Set up keymaps for the floating window
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<ESC>', '<cmd>close<CR>', { noremap = true, silent = true })

  -- Focus the window
  vim.api.nvim_set_current_win(winid)

  return winid
end

-- Show AI response in a split window
M.show_ai_split = function(content, title, direction)
  direction = direction or 'horizontal'

  if direction == 'horizontal' then
    vim.cmd('belowright split')
  else
    vim.cmd('belowright vsplit')
  end

  -- Create new buffer
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(bufnr)

  -- Split content and set lines
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')

  -- Set window title if supported
  if vim.fn.has('nvim-0.9') == 1 then
    vim.api.nvim_win_set_option(0, 'title', title or "AI Response")
  end

  -- Resize window appropriately
  if direction == 'horizontal' then
    vim.cmd('resize ' .. math.min(15, #lines + 2))
  else
    vim.cmd('vertical resize ' .. math.min(80, vim.fn.max(vim.tbl_map(function(line) return #line end, lines)) + 5))
  end
end

-- Enhanced status line with AI status
M.update_status_with_ai = function(ai_status)
  -- This would integrate with the status line to show AI status
  -- For now, just update a global variable that could be used by statusline
  vim.g.bvi_ai_status = ai_status
end

-- Progress indicator for long operations
M.show_progress = function(current, total, message)
  local percentage = math.floor((current / total) * 100)
  local progress_bar = string.rep('█', math.floor(percentage / 10)) .. string.rep('░', 10 - math.floor(percentage / 10))

  vim.api.nvim_echo({
    { string.format("[%s] %d%% %s", progress_bar, percentage, message or ""), "Normal" }
  }, false, {})
end

return M
