return {
  'sindrets/diffview.nvim',
  config = function()
    local diffview = require 'diffview'

    vim.keymap.set('n', '<leader>gd', diffview.open, { desc = '[G]earch [D]iff' })
  end,
}
