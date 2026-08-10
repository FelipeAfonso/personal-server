-- Setup for the ~11 packs declared in init.lua. Ordered: colorscheme first.

-- ── neopywal + wallust ──────────────────────────────────────────────────────
require('neopywal').setup {
  -- Wallust-generated palette from ~/.cache/wallust/colors_neopywal.vim
  use_palette = 'wallust',
  transparent_background = true, -- matches ghostty opacity
  dim_inactive = true,
  terminal_colors = true,
  default_plugins = true,
  plugins = {
    gitsigns = true,
    treesitter = true,
    mini = {
      pick = true,
    },
  },
}
pcall(vim.cmd.colorscheme, 'neopywal')

-- ── mini.nvim: ai, surround, pairs, pick, extra ─────────────────────────────
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup()
require('mini.pairs').setup() -- also handles <CR> confirm when the pum is open
require('mini.icons').setup()
require('mini.extra').setup()
require('mini.pick').setup()
vim.ui.select = MiniPick.ui_select

-- Auto preview beside the picker while navigating, when there's enough room.
-- mini.pick emits no event on item navigation, so a timer polls the current
-- match; rendering reuses MiniPick.default_preview into a side float.
local pick_preview = {}

local function pick_preview_close()
  if pick_preview.timer then
    pick_preview.timer:stop()
    pick_preview.timer:close()
  end
  if pick_preview.win and vim.api.nvim_win_is_valid(pick_preview.win) then
    vim.api.nvim_win_close(pick_preview.win, true)
  end
  if pick_preview.buf and vim.api.nvim_buf_is_valid(pick_preview.buf) then
    vim.api.nvim_buf_delete(pick_preview.buf, { force = true })
  end
  pick_preview = {}
end

local function pick_preview_win_config()
  local main_win = MiniPick.get_picker_state().windows.main
  if not vim.api.nvim_win_is_valid(main_win) then return nil end
  local pos = vim.api.nvim_win_get_position(main_win)
  local col = pos[2] + vim.api.nvim_win_get_width(main_win) + 2
  local width = vim.o.columns - col - 1
  if width < 40 then return nil end -- not enough space, keep <Tab> toggle only
  return {
    relative = 'editor',
    anchor = 'NW',
    row = pos[1],
    col = col,
    width = width,
    height = vim.api.nvim_win_get_height(main_win),
    border = 'single',
    style = 'minimal',
    focusable = false,
  }
end

local function pick_preview_update()
  local ok, matches = pcall(MiniPick.get_picker_matches)
  if not ok or matches == nil or matches.current == nil then return end
  if matches.current == pick_preview.last then return end
  if pick_preview.win == nil or not vim.api.nvim_win_is_valid(pick_preview.win) then
    local win_config = pick_preview_win_config()
    if win_config == nil then return end
    pick_preview.buf = pick_preview.buf or vim.api.nvim_create_buf(false, true)
    pick_preview.win = vim.api.nvim_open_win(pick_preview.buf, false, win_config)
    vim.wo[pick_preview.win].winhighlight = 'NormalFloat:MiniPickNormal,FloatBorder:MiniPickBorder'
  end
  pick_preview.last = matches.current
  pcall(MiniPick.default_preview, pick_preview.buf, matches.current)
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniPickStart',
  group = vim.api.nvim_create_augroup('pick-auto-preview', { clear = true }),
  callback = function()
    pick_preview.timer = vim.uv.new_timer()
    pick_preview.timer:start(50, 80, vim.schedule_wrap(pick_preview_update))
  end,
})
vim.api.nvim_create_autocmd('User', { pattern = 'MiniPickStop', group = 'pick-auto-preview', callback = pick_preview_close })
vim.api.nvim_create_autocmd('VimResized', {
  group = 'pick-auto-preview',
  callback = function()
    -- drop the stale float; the timer recreates it with fresh geometry (or
    -- not at all, if the resize left too little room)
    if pick_preview.win and vim.api.nvim_win_is_valid(pick_preview.win) then
      vim.api.nvim_win_close(pick_preview.win, true)
    end
    pick_preview.win, pick_preview.last = nil, nil
  end,
})

local pick = MiniPick.builtin
local extra = MiniExtra.pickers

-- Whaler port: list subdirectories of the project roots, cd on choose.
local whaler_dirs = {
  { alias = 'work', path = '~/code/work/liftup' },
  { alias = 'work', path = '~/code/work/contactai' },
  { alias = 'pers', path = '~/code/personal' },
  { alias = 'dotf', path = '~/.config' },
  { alias = 'liftup-mono', path = '~/code/work/liftup-monorepo/frontend' },
  { alias = 'liftup-mono', path = '~/code/work/liftup-monorepo/backend' },
  { alias = 'liftup-mono', path = '~/code/work/liftup-monorepo/packages' },
}
local function whaler()
  local items = {}
  for _, dir in ipairs(whaler_dirs) do
    local root = vim.fn.expand(dir.path)
    local ok, entries = pcall(function()
      local acc = {}
      for name, type in vim.fs.dir(root) do
        if type == 'directory' then
          acc[#acc + 1] = name
        end
      end
      return acc
    end)
    if ok then
      for _, name in ipairs(entries) do
        items[#items + 1] = { text = dir.alias .. ' │ ' .. name, path = root .. '/' .. name }
      end
    end
  end
  MiniPick.start {
    source = {
      items = items,
      name = 'Projects',
      choose = function(item)
        -- after the picker window closes, so the cwd change sticks
        vim.schedule(function()
          vim.fn.chdir(item.path)
        end)
      end,
    },
  }
end

local map = vim.keymap.set
map('n', '<leader>o', function() extra.oldfiles() end, { desc = 'Find recently opened files' })
map('n', '<leader><space>', function() pick.buffers() end, { desc = 'Find existing buffers' })
map('n', '<leader>/', function() extra.buf_lines { scope = 'current' } end, { desc = 'Fuzzily search in current buffer' })
map('n', '<leader>pp', function() pick.files { tool = 'git' } end, { desc = 'Search git files' })
map('n', '<leader>pa', function() pick.files() end, { desc = 'Search all files' })
map('n', '<leader>pf', function() pick.grep_live() end, { desc = 'Search by grep' })
map('n', '<leader>pw', function() pick.grep { pattern = vim.fn.expand '<cword>' } end, { desc = 'Search current word' })
map('n', '<leader>pr', function() pick.resume() end, { desc = 'Search resume' })
map('n', '<leader>pj', whaler, { desc = 'Search projects (whaler)' })
map('n', '<leader>ph', function() pick.help() end, { desc = 'Search help' })
map('n', '<leader>pd', function() extra.diagnostic() end, { desc = 'Search diagnostics' })
map('n', '<leader>pk', function() extra.keymaps() end, { desc = 'Search keymaps' })
map('n', '<leader>gb', function() extra.git_branches() end, { desc = 'Git branches' })
map('n', '<leader>pn', function() pick.files(nil, { source = { cwd = vim.fn.stdpath 'config' } }) end, { desc = 'Search neovim config' })

-- ── treesitter (main branch) ────────────────────────────────────────────────
local function ts_try_start(buf)
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if lang and vim.treesitter.language.add(lang) then
    vim.treesitter.start(buf, lang)
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

require('nvim-treesitter')
  .install({
    'astro', 'c', 'cpp', 'css', 'go', 'html', 'http', 'javascript', 'json', 'lua',
    'markdown', 'markdown_inline', 'odin', 'python', 'rust', 'svelte', 'tsx',
    'typescript', 'vim', 'vimdoc',
  })
  :await(function()
    -- catch buffers whose FileType fired before the async install finished
    vim.schedule(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then pcall(ts_try_start, buf) end
      end
    end)
  end)

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(args)
    ts_try_start(args.buf)
  end,
})

-- ── harpoon ─────────────────────────────────────────────────────────────────
local harpoon = require 'harpoon'
harpoon:setup { settings = { sync_on_ui_close = true, save_on_toggle = true } }
map('n', '<leader>s', function() harpoon:list():add() end)
map('n', '<leader>r', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
for i = 1, 8 do
  map('n', '<leader>' .. i, function() harpoon:list():select(i) end)
end

-- ── oil ─────────────────────────────────────────────────────────────────────
require('oil').setup {
  keymaps = {
    ['<CR>'] = 'actions.select',
    ['<C-p>'] = 'actions.preview',
    ['<C-l>'] = 'actions.refresh',
    ['Q'] = 'actions.close',
    ['-'] = 'actions.parent',
    ['g.'] = 'actions.toggle_hidden',
  },
  -- oil ≥ 0.11 defers to vim.o.winborder (unset here), which loses the border;
  -- with a transparent background that leaves no division from the buffer below
  float = { border = 'rounded' },
  view_options = { show_hidden = true },
}
map('n', '<leader>t', function() require('oil').toggle_float() end)

-- ── gitsigns ────────────────────────────────────────────────────────────────
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    local gitsigns = require 'gitsigns'
    local function bmap(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    bmap('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gitsigns.nav_hunk 'next'
      end
    end, { desc = 'Jump to next git change' })
    bmap('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gitsigns.nav_hunk 'prev'
      end
    end, { desc = 'Jump to previous git change' })

    bmap('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git stage hunk' })
    bmap('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git reset hunk' })
    bmap('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git stage/unstage hunk' })
    bmap('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git reset hunk' })
    bmap('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git stage buffer' })
    bmap('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git reset buffer' })
    bmap('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git preview hunk' })
    bmap('n', '<leader>hb', gitsigns.blame_line, { desc = 'git blame line' })
    bmap('n', '<leader>hd', gitsigns.diffthis, { desc = 'git diff against index' })
    bmap('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'git diff against last commit' })
    bmap('n', '<leader>gB', gitsigns.toggle_current_line_blame, { desc = 'Toggle line blame' })
    bmap('n', '<leader>gD', gitsigns.preview_hunk_inline, { desc = 'Preview hunk inline' })
  end,
}

-- ── conform (format on save) ────────────────────────────────────────────────
require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettierd', 'eslint_d', lsp_format = 'never' },
    typescript = { 'prettierd', 'eslint_d', lsp_format = 'never' },
    javascriptreact = { 'prettierd', 'eslint_d', lsp_format = 'never' },
    typescriptreact = { 'prettierd', 'eslint_d', lsp_format = 'never' },
    svelte = { 'prettierd', 'prettier', stop_after_first = true, lsp_format = 'never' },
    odin = { 'odinfmt' },
    templ = { 'templ', 'prettier' },
    json = { 'prettier', 'jq', stop_after_first = true },
    jsonc = { 'prettier', stop_after_first = true },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = 500 },
}
map('', '<leader>f', function() require('conform').format { async = true } end, { desc = 'Format buffer' })

-- ── tmux navigation ─────────────────────────────────────────────────────────
require('tmux').setup {
  navigation = { enable_default_keybindings = false },
  copy_sync = { enable = false },
  resize = { enable_default_keybindings = false },
}
map('n', '<C-h>', function() require('tmux').move_left() end)
map('n', '<C-j>', function() require('tmux').move_bottom() end)
map('n', '<C-k>', function() require('tmux').move_top() end)
map('n', '<C-l>', function() require('tmux').move_right() end)
map('n', '<M-h>', function() require('tmux').resize_left() end)
map('n', '<M-j>', function() require('tmux').resize_bottom() end)
map('n', '<M-k>', function() require('tmux').resize_top() end)
map('n', '<M-l>', function() require('tmux').resize_right() end)

-- ── lazydev (lua_ls types for the nvim API) ─────────────────────────────────
require('lazydev').setup {
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
}

-- vim: ts=2 sts=2 sw=2 et
