return {
  {
    'mason-org/mason.nvim',
    opts = {},
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      'mason-org/mason.nvim',
      'neovim/nvim-lspconfig',
    },
    opts = {
      ensure_installed = { 'lua_ls' },
    },
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      vim.lsp.config('rust_analyzer', {
        settings = {
          ['rust_analyzer'] = {
            check = {
              command = 'clippy',
            },
          },
        },
      })
      vim.lsp.enable 'rust_analyzer'
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = { 'stylua' },
    },
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
}
