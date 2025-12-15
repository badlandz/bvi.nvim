-- lua/bvi/keymaps.lua
local M = {}

function M.setup(config)
  local map = vim.keymap.set
  local opts = { noremap = true, silent = true }

  -- Only set leader if not already set
  if not vim.g.mapleader or vim.g.mapleader == '' then
    vim.g.mapleader = ' '
  end
  if not vim.g.maplocalleader or vim.g.maplocalleader == '' then
    vim.g.maplocalleader = ' '
  end

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

  -- Telescope – the real file finder (only if available)
  local telescope_ok = pcall(require, 'telescope.builtin')
  if telescope_ok then
    local builtin = require 'telescope.builtin'
    map('n', '<leader>ff', builtin.find_files, opts)
    map('n', '<leader>fg', builtin.live_grep, opts)
    map('n', '<leader>fb', builtin.buffers, opts)
    map('n', '<leader>fh', builtin.help_tags, opts)
  end

  -- Persistence (immortality) - only if available
  local persistence_ok = pcall(require, 'persistence')
  if persistence_ok then
    map('n', '<leader>qs', function()
      require('persistence').load()
    end, opts)
    map('n', '<leader>ql', function()
      require('persistence').load { last = true }
    end, opts)
  end

  -- THE SACRED LATTICE — leader + 1–9 → jump to buffer 1–9
  -- This is the final unification of the entire OS keymap
  for i = 1, 9 do
    map("n", "<leader>" .. i, function()
      local ok, buf = pcall(vim.api.nvim_win_get_buf, 0)
      if not ok then return end

      -- Try to go to buffer i in the current window first
      local wins = vim.api.nvim_list_wins()
      for _, win in ipairs(wins) do
        if vim.api.nvim_win_is_valid(win) then
          local win_buf = vim.api.nvim_win_get_buf(win)
          if vim.api.nvim_buf_is_loaded(win_buf) and vim.fn.bufname(win_buf) ~= "" then
            local listed = vim.api.nvim_buf_get_option(win_buf, "buflisted")
            if listed then
              local num = vim.api.nvim_buf_get_number(win_buf)
              if num == i then
                vim.api.nvim_set_current_win(win)
                return
              end
            end
          end
        end
      end

      -- Fallback: select the i-th listed buffer (classic behaviour)
      vim.cmd(i .. "buffer")
    end, { desc = "Jump to buffer " .. i })
  end

  -- Bonus: leader-0 → last buffer (like tmux last-window)
  map("n", "<leader>0", "<C-^>", { desc = "Alternate/last buffer" })

  -- DB: Open schema, run query (only if available)
  if vim.fn.exists(':DBUIToggle') == 2 then
    map("n", "<leader>db", ":DBUIToggle<CR>", { desc = "DB Browser" })
    map("v", "<leader>cr", "<Plug>(DBUI_ExecuteQuery)", { desc = "Run SQL" })
  end

  -- FORMAT: Manual if auto-save misses (only if conform available)
  local conform_ok = pcall(require, 'conform')
  if conform_ok then
    map("n", "<leader>fm", function() require("conform").format({ async = true }) end, { desc = "Format" })
  end

  -- MARKDOWN: Preview, open link (only if available)
  if vim.fn.exists(':MarkdownPreviewToggle') == 2 then
    map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
    map("n", "<CR>", "<Plug>(Markdown_Open_Link)", { desc = "Open Markdown Link" })
  end

  -- TASKWARRIOR: Toggle tasks (only if available)
  if vim.fn.exists(':TaskWarriorToggle') == 2 then
    map("n", "<leader>tw", ":TaskWarriorToggle<CR>", { desc = "TaskWarrior" })
  end

  -- LSP: Diagnostics list (only if trouble available)
  if vim.fn.exists(':Trouble') == 2 then
    map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
  end

  -- AI ASSISTANCE: Enhanced context-aware AI help with direct BAUXD integration
  map("n", "<leader>ai", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI module not available", vim.log.levels.WARN)
      return
    end
    ai.smart_assist()
  end, { desc = "Smart AI Assistance" })

  map("v", "<leader>ai", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI module not available", vim.log.levels.WARN)
      return
    end
    -- Get visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])
    local selection = table.concat(lines, "\n")
    ai.smart_assist("Help with this code selection: " .. selection)
  end, { desc = "AI on Selection" })

  -- SPECIALIZED AI COMMANDS
  map("n", "<leader>aa", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI requires BAUXD. Install BAUX ecosystem for full functionality.", vim.log.levels.WARN)
      return
    end
    ai.analyze_code()
  end, { desc = "Analyze Code" })

  map("n", "<leader>ar", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI requires BAUXD. Install BAUX ecosystem for full functionality.", vim.log.levels.WARN)
      return
    end
    ai.smart_assist("Suggest refactoring improvements for this code")
  end, { desc = "Refactoring Suggestions" })

  map("n", "<leader>ad", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI requires BAUXD. Install BAUX ecosystem for full functionality.", vim.log.levels.WARN)
      return
    end
    ai.smart_assist("Help debug this code - identify potential issues")
  end, { desc = "Debug Assistance" })

  -- AI CONTEXT & STATUS
  map("n", "<leader>ac", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI module not available", vim.log.levels.WARN)
      return
    end
    ai.show_context()
  end, { desc = "Show AI Context" })

  map("n", "<leader>as", function()
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if not ai_ok then
      vim.notify("BVI AI module not available", vim.log.levels.WARN)
      return
    end
    ai.show_status()
  end, { desc = "AI System Status" })
end

return M
