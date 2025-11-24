-- lua/bvi/autocmds.lua
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  command = [[%s/\s\+$//e]], -- strip trailing whitespace
})

-- Auto-restore session on startup (works with tmux-resurrect)
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() == 0 then
      require('persistence').load()
    end
  end,
  nested = true,
})
