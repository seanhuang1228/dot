return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'
        vim.keymap.set('n', 'gn', function()
          gitsigns.nav_hunk 'next'
        end, { buffer = bufnr, desc = '[G]it change [N]ext' })
        vim.keymap.set('n', 'gp', function()
          gitsigns.nav_hunk 'prev'
        end, { buffer = bufnr, desc = '[G]it change [P]rev' })
        vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { buffer = bufnr, desc = '[H]unk [s]tage' })
        vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { buffer = bufnr, desc = '[H]unk [r]eset' })
        vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { buffer = bufnr, desc = '[H]unk [p]review' })
      end,
    },
  },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    cmd = 'Neogit',
    keys = {
      {
        '<leader>gg',
        function()
          require('neogit').open()
        end,
        desc = '[G]it',
      },
    },
    opts = {
      integrations = {
        telescope = true,
      },
      kind = 'floating',
      sections = {
        untracked = {
          folded = true,
        },
      },
    },
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [d]iff view' },
    },
  },
}
