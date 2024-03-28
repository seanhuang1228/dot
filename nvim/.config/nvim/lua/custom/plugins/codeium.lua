return {
  'Exafunction/codeium.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
  },
  -- run :Lazy load codeium.nvim to load
  lazy = true,
  config = function()
    require('codeium').setup {}
  end,
}
