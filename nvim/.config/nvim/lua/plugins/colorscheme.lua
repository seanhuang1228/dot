return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha',
      integrations = {
        telescope = true,
        treesitter = true,
        gitsigns = true,
        which_key = true,
        neogit = true,
        noice = true,
        native_lsp = {
          enabled = true,
        },
      },
    }
    vim.cmd.colorscheme 'catppuccin'
  end,
}
