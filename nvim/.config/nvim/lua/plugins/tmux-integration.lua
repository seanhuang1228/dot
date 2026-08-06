return {
  'mrjones2014/smart-splits.nvim',
  config = function()
    local smart_splits = require 'smart-splits'
    vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left, { desc = 'Move focus left (tmux-aware)' })
    vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down, { desc = 'Move focus down (tmux-aware)' })
    vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up, { desc = 'Move focus up (tmux-aware)' })
    vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right, { desc = 'Move focus right (tmux-aware)' })
  end,
}
