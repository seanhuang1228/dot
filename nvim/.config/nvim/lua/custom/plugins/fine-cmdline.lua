return {
  {
    'VonHeikemen/fine-cmdline.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    config = function()
      require('fine-cmdline').setup()

      vim.keymap.set('n', ':', '<cmd>FineCmdline<cr>', { noremap = true }, { desc = 'FineCmdline: Start' })
    end,
  },
}
