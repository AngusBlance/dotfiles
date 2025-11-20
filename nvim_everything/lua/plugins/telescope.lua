return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.x', -- use stable release
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    local builtin = require('telescope.builtin')

    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files (Root Dir)' })
    vim.keymap.set('n', '<leader>fF', function()
      require('telescope.builtin').find_files {
        cwd = vim.fn.expand("~") }
    end, { desc = 'Find Files (Root Dir)' })
    vim.keymap.set('n', '<leader>fg', builtin.git_files, { desc = 'Find Git Files' })
    vim.keymap.set('n', '<leader>fp', builtin.live_grep, { desc = 'Search in Project (grep)' })
    vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent Files' })
    vim.keymap.set('n', '<leader>fR', function()
      builtin.oldfiles({ cwd = vim.fn.getcwd() })
    end, { desc = 'Recent Files (cwd)' })
    vim.keymap.set('n', '<leader>,', builtin.buffers, { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>/', builtin.live_grep, { desc = 'Grep (Root Dir)' })
  end
}