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

-- INLINE your core specs here (from core.lua) -- no import needed
local specs = {
  { 'nvim-lua/plenary.nvim', lazy = true },
  { 'echasnovski/mini.nvim', version = false }, -- the swiss army knife
  -- { 'folke/lazy.nvim', version = false }, -- Already bootstrapped, don't load twice

  -- TABLINE AT THE TOP – the canonical 2025 cyberdeck look
  {
    'echasnovski/mini.tabline',
    version = false,
    config = function()
      require('mini.tabline').setup {
        -- Nerd Font icons (already shipped in BAUX)
        show_icons = true,

        -- Clean spacing + modified dot
        format = function(buf_id, label)
          local modified = vim.bo[buf_id].modified and ' ●' or ''
          return ' ' .. label .. modified .. ' '
        end,

        -- Optional: hide when only one buffer (saves vertical space)
        -- set to false if you want it always visible
        show_only_current = false,
      }
    end,
  },
  -- Update myself
  {
    'badlandz/bvi.nvim',
    lazy = false, -- always load (it's the config itself)
    priority = 1000, -- highest priority
    cond = function()
      -- Only load if we are actually running from the cloned plugin folder
      return vim.fn.isdirectory(vim.fn.stdpath 'config' .. '/lua/bvi/.git') == 1
    end,
  },

  -- IMMORTALITY
  { 'folke/persistence.nvim', event = 'BufReadPre', opts = { options = { 'buffers', 'curdir', 'tabpages', 'winsize' } } },

  -- LAYERS FOREVER (with your BAUX cond from earlier)
  {
    'christoomey/vim-tmux-navigator',
    cond = function()
      return os.getenv 'BAUX_SESSION' == '1'
    end,
    lazy = false,
  },

  -- ESSENTIALS
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' } },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', opts = { ensure_installed = { 'bash', 'c', 'lua', 'vim', 'python', 'arduino' } } },
  { 'neovim/nvim-lspconfig' },
  { 'lewis6991/gitsigns.nvim' },
  { 'mbbill/undotree' },
  { 'folke/which-key.nvim' },

  -- MASON: Auto-install LSPs/formatters (clangd/lua_ls/bashls/sqls/shfmt/clang-format/sqlfmt/stylua)
  {
    'williamboman/mason.nvim',
    opts = {
      ensure_installed = { 'clangd', 'lua_ls', 'bash-language-server', 'sqls', 'shfmt', 'clang-format', 'sqlfmt', 'stylua' },
    },
    config = function(_, opts)
      require('mason').setup()
      require('mason-lspconfig').setup { automatic_installation = true }
    end,
  },

  -- LSP ENHANCEMENTS: Lua/C/Bash/SQL autocomplete/defs/hovers (live from swarm PG for SQL)
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'hrsh7th/nvim-cmp', 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local lspconfig = require 'lspconfig'
      local cmp_lsp = require 'cmp_nvim_lsp'
      local capabilities = cmp_lsp.default_capabilities()

      lspconfig.lua_ls.setup { capabilities = capabilities } -- Lua: APIs/vars
      lspconfig.clangd.setup { capabilities = capabilities } -- C: structs/defs
      lspconfig.bashls.setup { capabilities = capabilities } -- Bash: cmds/aliases
      lspconfig.sqls.setup { capabilities = capabilities } -- SQL: tables/columns
    end,
  },

  -- COMPLETIONS: Smarter autocomplete for all langs (snippets + LSP)
  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path', 'L3MON4D3/LuaSnip', 'rafamadriz/friendly-snippets' },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load() -- Snippets for C/Bash/SQL/Markdown/Lua
      local cmp = require 'cmp'
      cmp.setup {
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert { ['<C-Space>'] = cmp.mapping.complete() },
        sources = { { name = 'nvim_lsp' }, { name = 'luasnip' }, { name = 'buffer' }, { name = 'path' } },
      }
    end,
  },

  -- FORMATTER: Auto-format on save (C/Bash/SQL/Lua/Markdown)
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        c = { 'clang_format' },
        bash = { 'shfmt' },
        sql = { 'sqlfmt' },
        lua = { 'stylua' },
        markdown = { 'prettier' }, -- Or mdformat if no JS
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  -- DADBOD: PG queries in buffers (live schema browser, run selections)
  { 'tpope/vim-dadbod', ft = 'sql', cmd = { 'DBUI', 'DBUIToggle' } },
  { 'kristijanhusak/vim-dadbod-ui', ft = 'sql', dependencies = 'vim-dadbod' },
  { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'plsql' }, dependencies = 'vim-dadbod' },

  -- MARKDOWN: Syntax/folding/links (Enter opens links like old vimwiki)
  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown", "md" },
    opts = { modes = { "n", "i" } },  -- Conceal/render for headings/tables
  },
  {
    'preservim/vim-markdown',
    ft = { 'markdown', 'md' },
    init = function()
      vim.g.vim_markdown_folding_disabled = 1  -- HATE this
      vim.g.vim_markdown_autowrite = 1         -- Auto-save
      vim.g.vim_markdown_new_list_item_indent = 0
    end,
  },
  {
    'iamcco/markdown-preview.nvim',
    ft = { 'markdown', 'md' },
    build = 'cd app && npm install', -- Preview if needed (<1 MB)
    cmd = { 'MarkdownPreviewToggle' },
  },

  -- LATEX: Compile/view PDFs (tiny, your workflow)
  {
    'lervag/vimtex',
    ft = { 'tex', 'latex' },
    init = function()
      vim.g.vimtex_view_method = 'zathura' -- Or skim/general
      vim.g.vimtex_quickfix_mode = 0 -- No auto-open
    end,
  },

  -- TASKWARRIOR: Integrate tasks in Markdown (like old taskwiki)
  {
    'ribelo/taskwarrior.nvim',
    ft = { 'markdown', 'md', 'task' },
    config = true, -- <leader>tw toggles
  },

  -- TREESITTER: Enhanced syntax/indent for all langs
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'lua', 'c', 'bash', 'sql', 'markdown', 'markdown_inline', 'latex' },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
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
