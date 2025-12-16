-- bvi.nvim/lua/bvi.lua
-- Standalone BVI plugin for Neovim users
-- Provides enhanced editing experience with optional BAUX AI integration

local M = {}

-- Default configuration
M.config = {
  -- AI integration settings (requires BAUXD)
  ai = {
    enabled = true,
    bauxd_host = "localhost",
    bauxd_port = 9999,
    timeout = 5000,
    max_context_lines = 100,
  },

  -- UI enhancements
  ui = {
    enable_loading_spinners = true,
    enable_floating_windows = true,
  },

  -- Keymaps
  keymaps = {
    enabled = true,
    prefix = "<leader>",
  },
}

-- Setup function for lazy.nvim
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Load core features (always available)
  require('bvi.options').setup(M.config)
  require('bvi.autocmds').setup(M.config)
  require('bvi.keymaps').setup(M.config)
  require('bvi.ui').setup(M.config)

  -- Load AI integration (optional, requires BAUXD)
  if M.config.ai.enabled then
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if ai_ok then
      ai.setup(M.config.ai)
      vim.notify("BVI AI integration active (BAUXD connected)", vim.log.levels.INFO)
    else
      vim.notify("BVI AI: BAUXD not available - install BAUX ecosystem for AI features", vim.log.levels.WARN)
    end
  end

  vim.notify("BVI plugin loaded successfully", vim.log.levels.INFO)
  return true
end

return M