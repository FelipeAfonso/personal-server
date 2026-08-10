vim.o.mouse = 'a'
vim.o.showmode = false

-- Sync clipboard between OS and Neovim. Scheduled to not slow down startup.
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true
vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.o.colorcolumn = '80'
vim.o.number = true
vim.o.relativenumber = true
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:hor20-Cursor-blinkwait300-blinkon200-blinkoff150,r-cr-o:hor20'
vim.o.termguicolors = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.swapfile = false
vim.o.backup = false

-- Terminal title shows the project (cwd tail), kept fresh across whaler jumps
vim.o.title = true
local function set_title()
  vim.o.titlestring = string.match(vim.fn.getcwd(), '^.+/(.+)$') or vim.fn.getcwd()
end
set_title()
vim.api.nvim_create_autocmd('DirChanged', {
  group = vim.api.nvim_create_augroup('title-cwd', { clear = true }),
  callback = set_title,
})

-- Native insert-mode autocompletion (nvim 0.12)
vim.o.autocomplete = true
vim.o.completeopt = 'menu,menuone,noselect,fuzzy,nearest'
vim.o.pumheight = 15

-- vim: ts=2 sts=2 sw=2 et
