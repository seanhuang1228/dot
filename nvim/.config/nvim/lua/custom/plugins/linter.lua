local linters = {
  -- check the following example to add linter
  -- cpp = { 'cpplint' },
  -- python = { 'flake8' },
}

return {
  {
    'mfussenegger/nvim-lint',
    lazy = true,
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = linters
    end,
  },
  {
    'rshkarin/mason-nvim-lint',
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-lint',
    },
    keys = {
      {
        '<leader>cl',
        function()
          require('lint').try_lint()
        end,
        desc = '[C]ode [L]inter on',
      },
    },
    config = function()
      local ensure_list = {}
      for _, v in pairs(linters) do
        for _, iv in ipairs(v) do
          table.insert(ensure_list, iv)
        end
      end

      require('mason-nvim-lint').setup {
        ensure_installed = ensure_list,
      }
    end,
  },
}
