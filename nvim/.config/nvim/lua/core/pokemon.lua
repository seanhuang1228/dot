local pokemon_win = nil

local function close_pokemon()
  if pokemon_win and vim.api.nvim_win_is_valid(pokemon_win) then
    vim.api.nvim_win_close(pokemon_win, true)
  end
  pokemon_win = nil
end

local function show_pokemon()
  -- toggle: pressing the keymap again while open just closes it
  if pokemon_win and vim.api.nvim_win_is_valid(pokemon_win) then
    close_pokemon()
    return
  end

  local width, height = 22, 13
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  pokemon_win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    anchor = 'SE',
    row = vim.o.lines - vim.o.cmdheight - 2,
    col = vim.o.columns - 1,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
  })

  -- run inside the floating window without moving focus into it
  vim.api.nvim_win_call(pokemon_win, function()
    vim.fn.jobstart('krabby name sprigatito', {
      term = true,
      on_exit = function()
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          while #lines > 0 and lines[#lines]:match '^%s*$' do
            table.remove(lines)
          end
          if #lines > 0 and lines[#lines]:match '^%[Process exited' then
            table.remove(lines)
          end
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.bo[buf].modifiable = false
        end)
      end,
    })
  end)
end

vim.keymap.set('n', '<leader>p', show_pokemon, { desc = 'Show random Pokémon' })
