-- bvi.nvim/lua/bvi/init.lua
-- Main BVI plugin entry point for Neovim
-- Can be used as a standalone plugin or full config

local M = {}

-- Default configuration
M.config = {
  -- AI integration settings
  ai = {
    enabled = true,
    bauxd_host = "localhost",
    bauxd_port = 9999,
    timeout = 5000,
    max_context_lines = 100,
  },

  -- UI settings
  ui = {
    enable_loading_spinners = true,
    enable_floating_windows = true,
  },

  -- Keymap settings
  keymaps = {
    enabled = true,
    prefix = "<leader>",
  },
}

-- Setup function for lazy.nvim integration
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Load core modules
  require('bvi.options').setup(M.config)
  require('bvi.autocmds').setup(M.config)

  if M.config.keymaps.enabled then
    require('bvi.keymaps').setup(M.config)
  end

  if M.config.ui.enable_loading_spinners or M.config.ui.enable_floating_windows then
    require('bvi.ui').setup(M.config)
  end

  -- Load AI integration if available and enabled
  if M.config.ai.enabled then
    local ai_ok, ai = pcall(require, 'bvi.ai')
    if ai_ok then
      ai.setup(M.config.ai)
      vim.notify("BVI AI integration loaded", vim.log.levels.INFO)
    else
      vim.notify("BVI AI integration not available (BAUXD not found)", vim.log.levels.WARN)
    end
  end

  vim.notify("BVI plugin loaded successfully", vim.log.levels.INFO)
end

-- For backward compatibility and standalone usage
if vim.g.bvi_standalone then
  -- Load as full config (legacy behavior)
  M.setup()
else
  -- Just export the setup function for plugin usage
  return M
end