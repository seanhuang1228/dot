-- Status line

return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      -- Also use catppuccin
      theme = 'catppuccin',
    },
  },
}
