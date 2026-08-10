vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>c', '<cmd>noh<cr>')

-- Diagnostics ([d / ]d navigation are defaults since 0.11)
vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Terminal
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Buffers
vim.keymap.set('n', '<leader>d', '<cmd>bd<cr>')
vim.keymap.set('n', '<leader>h', '<C-6>')

-- Black-hole deletes
vim.keymap.set('v', 'd', '"_d')
vim.keymap.set('n', 'dd', '"_dd')

-- Ctrl-S is the window prefix; Ctrl-W closes
vim.keymap.set('n', '<C-s>', '<C-W>')
vim.keymap.set({ 'n', 'v' }, '<C-W>', '<cmd>q<cr>')

-- Increment (tmux.nvim overrides <C-l> in normal mode for pane navigation,
-- so this effectively lives in v/x/o — same as the old config)
vim.keymap.set({ 'n', 'v', 'x', 'o' }, '<C-l>', '<C-a>')
vim.keymap.set({ 'n', 'v' }, 'g<C-l>', 'g<C-a>')

-- Move visual selection
vim.keymap.set('v', 'j', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'k', ":m '<-2<CR>gv=gv")

-- Strip surrounding tag chars
vim.keymap.set('i', '<C-x>', '<C-c>f<lt>vf>x')
vim.keymap.set('n', '<C-x>', 'f<lt>vf>x')

-- Motions
vim.keymap.set({ 'n', 'v' }, 'J', '0')
vim.keymap.set({ 'n', 'v' }, ';', '$')

-- jj to escape (replaces better-escape.nvim)
vim.keymap.set('i', 'jj', '<Esc>')

vim.keymap.set('n', '<C-T>t', function()
  vim.cmd 'LspRestart'
end)

-- Drop 0.11+ default diagnostic window maps that collide with the <C-W> habit
pcall(vim.keymap.del, 'n', '<C-W><C-D>')
pcall(vim.keymap.del, 'n', '<C-W>d')

-- vim: ts=2 sts=2 sw=2 et
