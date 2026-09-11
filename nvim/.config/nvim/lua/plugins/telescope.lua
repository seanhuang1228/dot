return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
    },
    'nvim-telescope/telescope-ui-select.nvim',
  },
  keys = {
    {
      '<leader>sf',
      function()
        require('telescope.builtin').find_files()
      end,
      desc = '[S]earch [F]iles',
    },
    {
      '<leader>sh',
      function()
        require('telescope.builtin').help_tags()
      end,
      desc = '[S]earch [H]elp',
    },
    {
      '<leader>sg',
      function()
        require('telescope.builtin').live_grep()
      end,
      desc = '[S]earch by [G]rep',
    },
    {
      '<leader><leader>',
      function()
        require('telescope.builtin').buffers()
      end,
      desc = '[] Find existing buffers',
    },
  },
  config = function()
    require('telescope').setup {
      extensions = {
        ['ui-select'] = require('telescope.themes').get_dropdown(),
      },
    }

    require('telescope').load_extension 'fzf'
    require('telescope').load_extension 'ui-select'
  end,
}
