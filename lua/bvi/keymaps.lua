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

    -- DB: Open schema, run query
  map("n", "<leader>db", ":DBUIToggle<CR>", { desc = "DB Browser" })
  map("v", "<leader>cr", "<Plug>(DBUI_ExecuteQuery)", { desc = "Run SQL" })  -- Visual select → run

  -- FORMAT: Manual if auto-save misses
  map("n", "<leader>fm", function() require("conform").format({ async = true }) end, { desc = "Format" })

  -- MARKDOWN: Preview, open link (old muscle memory)
  map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
  map("n", "<CR>", "<Plug>(Markdown_Open_Link)", { desc = "Open Markdown Link" })  -- Enter on link

  -- TASKWARRIOR: Toggle tasks
  map("n", "<leader>tw", ":TaskWarriorToggle<CR>", { desc = "TaskWarrior" })

  -- LSP: Diagnostics list
  map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
