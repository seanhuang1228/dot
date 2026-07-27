return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration

    -- Only one of these is needed.
    'nvim-telescope/telescope.nvim', -- optional
  },
  config = function()
    local neogit = require 'neogit'

    neogit.setup {
      integrations = {
        telescope = true,
      },
      kind = 'floating',
      sections = {
        untracked = {
          folded = true,
        },
      },
    }
    vim.keymap.set('n', '<leader>gs', neogit.open, { desc = '[G]earch [S]tatus' })
  end,
}
