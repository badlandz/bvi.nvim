-- lua/bvi/autocmds.lua
local M = {}

function M.setup(config)
  -- Strip trailing whitespace on save
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*',
    command = [[%s/\s\+$//e]], -- strip trailing whitespace
  })

  -- Auto-restore session on startup (only if persistence is available)
  local persistence_ok = pcall(require, 'persistence')
  if persistence_ok then
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        if vim.fn.argc() == 0 then
          require('persistence').load()
        end
      end,
      nested = true,
    })
  end
end

return M
