-- Native LSP (0.11+): nvim-lspconfig is installed as a data-only dependency —
-- its lsp/ definitions provide cmd/filetypes/root_markers, never setup() calls.

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      completion = { callSnippet = 'Replace' },
      workspace = {
        library = { '${3rd}/love2d/library' },
      },
    },
  },
})

-- Workspace typescript wins; bun-global install is the single-file fallback
vim.lsp.config('ts_ls', {
  init_options = {
    tsserver = { fallbackPath = vim.fn.expand '~/.bun/install/global/node_modules/typescript/lib' },
  },
})

vim.lsp.enable { 'lua_ls', 'gopls', 'rust_analyzer', 'ts_ls', 'svelte', 'astro', 'ols', 'pyright' }

vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = { source = 'if_many', spacing = 2 },
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
    local function map(keys, func, desc, mode)
      vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Defaults since 0.11 cover grr (references), gra (code action), grn
    -- (rename), gri (implementation), K (hover), [d/]d. The maps below are
    -- the personal layer on top, pickers via mini.extra.
    local lsp_pick = function(scope)
      return function()
        MiniExtra.pickers.lsp { scope = scope }
      end
    end
    map('gd', lsp_pick 'definition', 'Goto definition')
    map('gi', lsp_pick 'implementation', 'Goto implementation')
    map('gO', lsp_pick 'document_symbol', 'Document symbols')
    map('gW', lsp_pick 'workspace_symbol', 'Workspace symbols')
    map('<leader>D', lsp_pick 'type_definition', 'Type definition')
    map('<leader>ds', lsp_pick 'document_symbol', 'Document symbols')
    map('<leader>ws', lsp_pick 'workspace_symbol', 'Workspace symbols')
    map('<F2>', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'v' })
    map('gD', vim.lsp.buf.declaration, 'Goto declaration')

    -- Native completion feeds the 0.12 autocomplete option (set in options.lua)
    if client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, event.buf)
    end

    -- Highlight references of the word under the cursor on hold
    if client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }, { bufnr = event.buf })
      end, 'Toggle inlay hints')
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
