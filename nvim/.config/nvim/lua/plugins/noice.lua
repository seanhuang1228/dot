return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
  opts = {
    presets = {
      bottom_search = true,
      long_message_to_split = true,
      lsp_doc_border = false,
    },
  },
}
