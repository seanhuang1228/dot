return {
  'michaelrommel/nvim-silicon',
  lazy = true,
  cmd = 'Silicon',
  init = function()
    vim.keymap.set({ 'n', 'v' }, '<leader>ms', ':Silicon<cr>', {
      desc = '[M]isc: Code [S]napshot',
    })
  end,
  config = function()
    require('silicon').setup {
      font = 'Hurmit Nerd Font Mono=20',
      theme = 'Nord',
      background = '#20b2aa',
      pad_horiz = 60,
      pad_vert = 48,
      tab_width = 2,
    }
  end,
}
