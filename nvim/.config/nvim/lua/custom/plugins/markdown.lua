return {
  {
    'iamcco/markdown-preview.nvim',
    lazy = true,
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && npm install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown', 'mdx' }
    end,
    config = function()
      vim.keymap.set('n', '<Leader>mm', ':MarkdownPreviewToggle<CR>', { desc = '[M]isc: [M]arkdown Preview' })
    end,
    ft = { 'markdown', 'mdx' },
  },
}
