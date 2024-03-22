-- Hop everywhere
return {
  {
    'hadronized/hop.nvim',
    config = function()
      require('hop').setup()

      local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { desc = 'Hop: ' .. desc })
      end

      map('<leader>hw', ':HopWord<cr>', '[H]op [W]ord')
    end,
  },
}
