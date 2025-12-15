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
| **Real-Time AI Integration** (BAUXD) | No | Basic (!ollama) | **Yes (Direct HTTP)** | **BAUX ecosystem** |
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

## 🤖 Real-Time AI Integration (BAUX Ecosystem)

BVI provides seamless integration with the BAUX AI ecosystem through direct HTTP communication with BAUXD (port 9999). No shell commands or external dependencies required - everything happens in real-time within your editor.

### AI Features (Neovim Mode Only)

#### **Smart AI Assistance** (`<leader>ai`)
- **Context-Aware**: Automatically analyzes your current buffer, cursor position, LSP diagnostics, and git status
- **Smart Routing**: Chooses between Grok (complex reasoning) and Ollama (fast queries) based on context
- **Rich Context**: Includes file type, visual selections, error diagnostics, and project structure
- **Real-Time**: Direct HTTP communication with BAUXD (no shell delays)

#### **Specialized AI Commands**
- **`<leader>aa`** - **Analyze Code**: Comprehensive code analysis with bug detection and best practices
- **`<leader>ar`** - **Refactor Suggestions**: Intelligent refactoring recommendations
- **`<leader>ad`** - **Debug Help**: AI-assisted debugging with issue identification
- **`<leader>ac`** - **Show Context**: Display detailed editor context for AI debugging
- **`<leader>as`** - **System Status**: Check BAUXD and AI service health

#### **Visual Selection AI** (`<leader>ai` in visual mode)
- Highlight code and get AI assistance on the specific selection
- Contextual analysis of selected functions, classes, or code blocks
- Preserves your current workflow without leaving visual mode

### Technical Architecture

#### **Direct BAUXD Integration**
```lua
-- Real-time HTTP communication (no shell commands)
BAUXD → localhost:9999/ai/assistant
BAUXD → localhost:9999/ai/analyze
BAUXD → localhost:9999/health
```

#### **Rich Context Gathering**
- **Buffer Content**: Current file with configurable line limits
- **LSP Diagnostics**: Error and warning information from language servers
- **Git Status**: Branch, staged changes, and modification state
- **Cursor Context**: Current position and visual selections
- **Project Awareness**: File type, directory structure, and workspace info

#### **UI Enhancements**
- **Loading Spinners**: Visual feedback during AI processing
- **Floating Windows**: AI responses in dedicated, dismissible windows
- **Split Integration**: AI results in split windows for detailed analysis
- **Status Integration**: AI status in statusline when processing

### Setup Requirements

#### **BAUXD Connection**
```bash
# Ensure BAUXD is running
curl http://localhost:9999/health

# Test AI endpoints
curl "http://localhost:9999/ai/assistant?q=test"
```

#### **Dependencies**
- **plenary.nvim**: Required for HTTP communication
- **BAUXD**: Running on localhost:9999 (automatically detected)
- **BAUX Ecosystem**: Full AI integration with Grok and Ollama backends

### Configuration

#### **Default Settings**
```lua
require('bvi.ai').setup({
  bauxd_host = "localhost",    -- BAUXD server
  bauxd_port = 9999,           -- BAUXD port
  timeout = 5000,              -- Request timeout (ms)
  max_context_lines = 100,     -- Context line limit
  enable_completion = true,    -- AI completion integration
  enable_diagnostics = true    -- LSP diagnostic inclusion
})
```

#### **Keybindings**
```lua
-- AI Assistance
<leader>ai  - Smart AI help (normal/visual mode)
<leader>aa  - Analyze current code
<leader>ar  - Refactoring suggestions
<leader>ad  - Debug assistance
<leader>ac  - Show AI context
<leader>as  - System status
```

### AI Backend Intelligence

#### **Automatic Backend Selection**
- **Grok (x.ai)**: Complex reasoning, code generation, architectural decisions
- **Ollama (Local)**: Fast queries, simple explanations, quick debugging
- **Smart Routing**: Context-aware selection based on task complexity

#### **Context Types Detected**
- **Editor Context**: File type, cursor position, buffer content
- **Code Context**: Functions, classes, imports, syntax analysis
- **Project Context**: Git status, file structure, dependencies
- **Error Context**: LSP diagnostics, compilation errors

### Performance Characteristics

- **Response Time**: <500ms simple queries, <2s complex analysis
- **Memory Usage**: Minimal overhead, lazy-loaded modules
- **Network**: Direct localhost communication, no external dependencies
- **Fallback**: Graceful degradation when BAUXD unavailable

### Integration with BAUX Ecosystem

#### **Mesh Compatibility**
- Works across all BAUX mesh nodes (ranchden, touchy, zerow01)
- Automatic node discovery and routing
- Session continuity when roaming between devices

#### **BAUX Commands**
```bash
baux ai        # Opens AI pane (complements BVI <leader>ai)
baux context   # Shows TMUX context (complements BVI <leader>ac)
baux roam      # Session roaming with AI continuity
baux persist   # AI conversation state management
```

### Troubleshooting

#### **BAUXD Connection Issues**
```bash
# Check BAUXD status
curl http://localhost:9999/health

# Test AI endpoints
curl "http://localhost:9999/ai/assistant?q=test"

# Restart BAUXD if needed
sudo systemctl restart bauxd
```

#### **Plugin Loading Issues**
```bash
# Verify plenary installation
:lua require('plenary.curl')

# Check BVI AI module
:lua require('bvi.ai')

# Test AI setup
:lua require('bvi.ai').setup()
```

#### **Performance Issues**
- Reduce `max_context_lines` for faster responses
- Check network connectivity to BAUXD
- Verify AI backends (Grok/Ollama) are responding

### Future Enhancements

- **AI Completion**: Real-time code completion powered by AI
- **Inline Suggestions**: GitHub Copilot-style AI suggestions
- **Multi-Language Support**: Enhanced analysis for different filetypes
- **Learning Mode**: AI adapts to your coding patterns and preferences

---

### BVI Official Tagline
“BVI is to your editor what BAUX is to your shell: bvi wraps all vi, baux wraps bash with tmux for the fastest keystroke to an immortal coding universe—from vi.tiny on a bare USB stick to Kickstart-powered Neovim madness with AI, DB introspection, and tmux harmony—all without forgetting a single buffer or undo step. It just works, and it never dies.”

This is the locked-in vision for BVI: Pragmatic, extensible, and ready for v0.1 packaging. With the rename and LunarVim-inspired isolation, it's a standalone powerhouse for RoxieOS users.

For now, testing:
```
git clone https://github.com/badlandz/bvi.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

For maximum useage bling/bloat, I have this on my workstation to use it:
```
sudo apt update
sudo apt install -y build-essential git make gcc curl wget unzip gzip tar nodejs npm ripgrep fd-find postgresql-client texlive-full zathura taskwarrior ca-certificates```

Still debugging

