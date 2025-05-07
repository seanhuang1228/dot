return {
  'AckslD/nvim-neoclip.lua',
  dependencies = {
    -- you'll need at least one of these
    { 'nvim-telescope/telescope.nvim' },
    -- {'ibhagwan/fzf-lua'},
  },
  config = function()
    require('neoclip').setup {
      default_register = '"',
      keys = {
        telescope = {
          i = {
            select = {},
            paste = '<cr>',
          },
          n = {
            select = {},
            paste = '<cr>',
          },
        },
        fzf = {
          paste = '<cr>',
        },
      },
    }
    vim.keymap.set('n', '<leader>sc', ':Telescope neoclip<CR>', { desc = '[c] Find existing buf' })
  end,
}
