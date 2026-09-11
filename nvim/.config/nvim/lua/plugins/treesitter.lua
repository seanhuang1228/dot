return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').install { 'lua', 'vim', 'vimdoc', 'rust' }

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'lua', 'vim', 'vimdoc', 'rust' },
      callback = function()
        vim.treesitter.start()
      end,
    })
  end,
}
