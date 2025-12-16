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

  -- Load core features (always available) with error handling
   local options_ok, options = pcall(require, 'bvi.options')
   if options_ok and options.setup then
     vim.notify("BVI: Loading options module successfully", vim.log.levels.INFO)
     options.setup(M.config)
   else
     vim.notify("BVI: Failed to load options module - options_ok: " .. tostring(options_ok) .. ", options: " .. vim.inspect(options), vim.log.levels.ERROR)
   end

  local autocmds_ok, autocmds = pcall(require, 'bvi.autocmds')
  if autocmds_ok and autocmds.setup then
    autocmds.setup(M.config)
  else
    vim.notify("BVI: Failed to load autocmds module", vim.log.levels.WARN)
  end

  local keymaps_ok, keymaps = pcall(require, 'bvi.keymaps')
  if keymaps_ok and keymaps.setup then
    keymaps.setup(M.config)
  else
    vim.notify("BVI: Failed to load keymaps module", vim.log.levels.WARN)
  end

  local ui_ok, ui = pcall(require, 'bvi.ui')
  if ui_ok and ui.setup then
    ui.setup(M.config)
  else
    vim.notify("BVI: Failed to load ui module", vim.log.levels.WARN)
  end

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