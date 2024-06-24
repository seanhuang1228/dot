return {
  'lervag/vimtex',
  init = function()
    vim.g.vimtex_toggle_fractions = {
      INLINE = 'dfrac',
      frac = 'INLINE',
      dfrac = 'INLINE',
    }
    -- vim.g.vimtex_compiler_method =
    -- Use init for configuration, don't use the more common "config".
  end,
  config = function()
    vim.fn['vimtex#imaps#add_map'] {
      lhs = 'b',
      rhs = 'vimtex#imaps#style_math("textbf")',
      expr = 1,
      leader = '#',
      wrapper = 'vimtex#imaps#wrap_math',
    }
  end,
}
