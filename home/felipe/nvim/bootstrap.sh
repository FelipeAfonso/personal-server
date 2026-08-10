#!/bin/sh
# One-time setup: the language tools mason used to manage, now system-level.
set -ex

# ols/odinfmt: goblintopia (Odin); gopls/templ: niterra Go services
paru -S --needed lua-language-server rust-analyzer stylua tree-sitter-cli ols odinfmt gopls templ
# typescript pinned to 5.x: ts_ls needs tsserver.js, which the native TS 7 dropped
# svelte: writequit/crisalida/clt-roster; astro: portfolio; pyright: odysseus
bun install -g typescript-language-server typescript@5.9 @fsouza/prettierd eslint_d prettier \
  svelte-language-server @astrojs/language-server pyright
