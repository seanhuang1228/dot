-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
--  Overridden by smart-splits.nvim if it loads successfully (tmux-aware fallback)
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local telescope_builtin = require 'telescope.builtin'
    local buf = event.buf

    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = buf, desc = '[R]e[n]ame symbol' })
    vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = buf, desc = '[G]oto [D]eclaration' })
    vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
    vim.keymap.set('n', 'gI', telescope_builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
    vim.keymap.set('n', '<leader>D', telescope_builtin.lsp_type_definitions, { buffer = buf, desc = 'Type [D]efinition' })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf, desc = 'Hover Documentation' })
  end,
})
