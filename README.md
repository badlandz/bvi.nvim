# BVI – The Immortal, Minimal-First Editor for RoxieOS / BAUX

**Note on Naming**: A quick heads-up—while "bvi" (BAUX VI) is a clever, keystroke-efficient name symbolizing the fallback to vi/vim/nvim, it conflicts with an existing Debian package called "bvi" (a binary/hex editor based on vi, available in repos like sid and bullseye). This could cause installation confusion in RoxieOS (e.g., apt conflicts or PATH issues). Consider alternatives like "bauxvi" (to avoid overlap) or packaging with a prefix (e.g., "roxie-bvi"). Proceeding with your rename for now, but flagging for awareness.

### Core Philosophy
BVI is the editor counterpart to BAUX in the RoxieOS ecosystem: a thin, resilient wrapper that starts from the tiniest viable base (Debian's vi/vim) and scales to a feature-rich Neovim environment without ever compromising on immortality or minimalism. It resurrects your editing state—buffers, undo history, sessions—across reboots, USB boots, or machine swaps, all synced via PostgreSQL (digital twin) and SeaweedFS (file persistence). Everything is scriptable, lazy-loaded, and Pi-friendly (runs snappy on Raspberry Pi Model B). Inspired by LunarVim's isolated wrapper model, BVI lives alongside vanilla vi/nvim without conflicts, using custom paths (e.g., ~/.config/bvi) for a branded, standalone experience. Type `bvi` for the magic—one keystroke less than "nvim," symbolizing its lean vi roots.

### The Three Operating Modes (Automatic Fallback Detection)
BVI's wrapper (/usr/local/bin/bvi) detects and launches the best available editor, falling back gracefully for minimal installs or low-resource scenarios:

1. **vi.tiny Fallback** (Ultra-Minimal, <2MB; Always Works on Fresh Debian/USB):
   - Launches Debian's vi.tiny with a lightweight vimrc (~200 lines) for basic immortality: Persistent undo/files in SeaweedFS stubs, simple tmux sync (leader-bb to BAUX bot pane), and buffer lists synced to PostgreSQL.
   - Ideal for rescue USBs or root-only boots—no bloat, pure POSIX compatibility.

2. **Vim Stable Mode** (Default for RoxieOS Minimal ISO; ~4-5MB Installed):
   - Uses Debian's standard vim for 70-80% of features: Full autocmds for auto-sessions, undotree visualization, fzf fuzzy buffers, basic AI pipes (visual selection to Ollama via !commands), and PostgreSQL query execution (dbext.vim).
   - Plugins managed via vim-plug (minimalist, <50KB)—lazy equivalents for low overhead.

3. **Neovim Nightly Madness Mode** (Full Power for Development; ~8-10MB + Lazy Plugins):
   - Activated when Neovim (0.10+) is detected; forks Kickstart.nvim for a modular, performant base (LSP, treesitter, cmp autocompletions, telescope finder).
   - Adds wild features: Inline AI (gen.nvim for Ollama/DeepSeek/Grok), full PostgreSQL introspection (dadbod-ui schema browser/query builder), tmux harmony (navigator for seamless pane switching), and "cool" extras like hologram.nvim (in-buffer images/PDFs) or avante.nvim (Cursor-like code chat)—all lazy-loaded to avoid Pi halts.
   - Isolated via NVIM_APPNAME=bvi: Plugins in ~/.local/share/bvi/lazy, configs in ~/.config/bvi—zero interference with user's vanilla nvim.

### Feature Matrix: Everything Immortal and Scalable
BVI prioritizes "user might want to do that from within the editor while coding," with zero bloat unless activated. All features hook into BAUX for persistence (e.g., undodir/sessiondir in SeaweedFS).

| Feature | vi.tiny Compat | Vim Stable | Neovim Madness | Persistence Backend |
|---------|----------------|------------|----------------|---------------------|
| Immortal Buffers/Sessions (Auto-Reopen) | Partial (Manual :mks) | Yes (obsession.vim) | Yes (persistence.nvim, auto-cwd) | PostgreSQL + SeaweedFS |
| Eternal Undo History (Branching Viz) | Basic (Native undofile if +feat) | Yes (undotree) | Yes (undotree + mini.diff) | SeaweedFS |
| Tmux Pane Sync (Leader-bb Escape) | Yes (!tmux sends) | Yes (vim-tmux-navigator) | Yes (tmux.nvim + registers sync) | BAUX bot protocol |
| Visual Selection to AI (Explain/Refactor) | Basic (!ollama) | Yes (vis.vim) | Yes (gen.nvim/avante.nvim) | baux-gp.nvim (custom pipe) |
| PostgreSQL Integration (Schema Browser, Queries) | Basic (pgsql.vim syntax) | Yes (dbext.vim) | Yes (dadbod-ui + which-key menu) | baux-pg tools |
| Live Grep → Buffer → AI Chain | Partial (:grep) | Yes (grep.vim + fzf) | Yes (telescope + quickfix hooks) | PostgreSQL stubs |
| Session Resurrection on USB/Reboot | Yes (shada/SeaweedFS) | Yes | Yes (with tmux respawn) | Full BAUX integration |
| Rick-Roll Edition Boot Splash | Yes (ASCII + lolcat) | Yes | Yes (mini.starter with animations) | Startup hook |
| LSP/Treesitter/Autocompletions | No | Partial (if +feat) | Yes (Kickstart base + hundreds of langs) | Lazy.nvim |
| Wild Extras (Images in Buffer, RAG AI) | No | No | Yes (hologram.nvim, VectorCode) | Event=VeryLazy |

Total bloat: vi.tiny ~250KB; full madness <50MB (lazy plugins). Pi Model B optimized—startup <0.1s, async everything.

### Physical Layout on Disk (System-Wide, Isolated)
Inspired by LunarVim's installer/wrapper: A single .deb package installs the wrapper and base configs. On first run, it sets up user-isolated dirs without touching vanilla Neovim.

```
/usr/local/bin/bvi                   → POSIX shell wrapper (isolated launch)
/etc/bvi/
├── vimrc.tiny                       → 200-line Vimscript base (for vi/vim modes)
├── init.vim                         → Neovim bridge (rtp prepend, lua require('bvi.core'))
└── nvim/
    └── lua/bvi/                     → Kickstart.nvim fork (Lua modules)
        ├── core/                    → init.lua (Lazy setup with custom root/branding)
        ├── plugins/                 → *.lua specs (persistence, dadbod, etc.—lazy=true)
        ├── configs/                 → Overrides (keymaps, AI stubs)
        └── chadrc.lua               → Minimal UI (statusline: "BVI Immortal Mode")
```

User dirs (auto-created): ~/.config/bvi/ (sources /etc), ~/.local/share/bvi/lazy (plugins). Total system size: <10MB; user inflation minimal and optional.

### The Wrapper Script: Isolation Magic
```sh
#!/bin/sh
# BVI Wrapper - v0.1: Isolated, fallback-safe launch

. /etc/baux/profile 2>/dev/null || true  # BAUX env stubs
export NVIM_APPNAME=bvi  # Isolate Neovim paths

NVIM_BIN=$(command -v nvim)
VIM_BIN=$(command -v vim)
VI_BIN=$(command -v vi)

if [ -n "$NVIM_BIN" ]; then
    exec "$NVIM_BIN" -u /etc/bvi/init.vim "$@"
elif [ -n "$VIM_BIN" ]; then
    exec "$VIM_BIN" -u /etc/bvi/vimrc.tiny --cmd "set runtimepath^=/etc/bvi" "$@"
else
    exec "$VI_BIN" -u /etc/bvi/vimrc.tiny --cmd "set runtimepath^=/etc/bvi" "$@"
fi
```

### BVI Official Tagline
“BVI is to your editor what BAUX is to your shell: bvi wraps all vi, baux wraps bash with tmux for the fastest keystroke to an immortal coding universe—from vi.tiny on a bare USB stick to Kickstart-powered Neovim madness with AI, DB introspection, and tmux harmony—all without forgetting a single buffer or undo step. It just works, and it never dies.” 

This is the locked-in vision for BVI: Pragmatic, extensible, and ready for v0.1 packaging. With the rename and LunarVim-inspired isolation, it's a standalone powerhouse for RoxieOS users.

For now, testing:
```
git clone https://github.com/badlandz/bvi.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

Now, to actually configure the plugin.. Ugh...
```
```
