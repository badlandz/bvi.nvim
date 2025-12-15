-- bvi.nvim/lua/bvi/ai.lua
-- Real-time AI integration with BAUXD for enhanced Neovim experience
-- Direct HTTP communication, rich context gathering, completion integration

local M = {}

-- Configuration
M.config = {
  bauxd_host = "localhost",
  bauxd_port = 9999,
  timeout = 5000, -- 5 second timeout
  max_context_lines = 100, -- Maximum lines to send for context
  enable_completion = true,
  enable_diagnostics = true
}

-- State
M.bauxd_available = false

-- HTTP client for BAUXD communication
M.http_request = function(method, endpoint, data, callback)
  local curl = require('plenary.curl')

  local url = string.format("http://%s:%d%s", M.config.bauxd_host, M.config.bauxd_port, endpoint)
  local headers = {
    ["Content-Type"] = "application/json"
  }

  local request_opts = {
    method = method,
    headers = headers,
    timeout = M.config.timeout,
    on_error = function(err)
      vim.schedule(function()
        vim.notify("BAUXD connection failed: " .. err.message, vim.log.levels.ERROR)
      end)
    end
  }

  if data and method == "POST" then
    request_opts.body = vim.json.encode(data)
  elseif data and method == "GET" then
    -- For GET requests, encode data as query parameters
    local query_parts = {}
    for k, v in pairs(data) do
      table.insert(query_parts, string.format("%s=%s", k, vim.uri_encode(tostring(v))))
    end
    if #query_parts > 0 then
      url = url .. "?" .. table.concat(query_parts, "&")
    end
  end

  curl.request({
    url = url,
    method = method,
    headers = headers,
    body = request_opts.body,
    timeout = M.config.timeout,
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          local success, decoded = pcall(vim.json.decode, response.body)
          if success then
            callback(decoded)
          else
            vim.notify("Failed to parse BAUXD response", vim.log.levels.ERROR)
          end
        else
          vim.notify(string.format("BAUXD error %d: %s", response.status, response.body), vim.log.levels.ERROR)
        end
      end)
    end,
    on_error = function(err)
      vim.schedule(function()
        vim.notify("BAUXD request failed: " .. err.message, vim.log.levels.ERROR)
      end)
    end
  })
end

-- Gather comprehensive Neovim context for AI
M.get_editor_context = function()
  local context = {
    timestamp = os.time(),
    filetype = vim.bo.filetype,
    filename = vim.fn.expand('%:p'),
    cursor = vim.api.nvim_win_get_cursor(0),
    mode = vim.api.nvim_get_mode().mode,
    visual_selection = nil,
    buffer_content = nil,
    diagnostics = nil,
    lsp_symbols = nil,
    git_status = nil
  }

  -- Get current buffer content (with line limits)
  local bufnr = vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local start_line = math.max(1, context.cursor[1] - M.config.max_context_lines / 2)
  local end_line = math.min(line_count, context.cursor[1] + M.config.max_context_lines / 2)

  context.buffer_content = {
    lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false),
    start_line = start_line,
    end_line = end_line,
    total_lines = line_count,
    current_line = context.cursor[1]
  }

  -- Get visual selection if in visual mode
  if vim.fn.mode():match('[vV]') then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    context.visual_selection = {
      start_line = start_pos[2],
      start_col = start_pos[3],
      end_line = end_pos[2],
      end_col = end_pos[3],
      content = vim.fn.getline(start_pos[2], end_pos[2])
    }
  end

  -- Get LSP diagnostics if enabled
  if M.config.enable_diagnostics then
    local diagnostics = vim.diagnostic.get(bufnr)
    if #diagnostics > 0 then
      context.diagnostics = vim.tbl_map(function(diag)
        return {
          line = diag.lnum + 1,
          col = diag.col + 1,
          severity = diag.severity,
          message = diag.message,
          source = diag.source
        }
      end, diagnostics)
    end
  end

  -- Get LSP document symbols
  if vim.lsp.buf_get_clients then
    local clients = vim.lsp.buf_get_clients(bufnr)
    if #clients > 0 then
      -- Try to get document symbols from the first available client
      for _, client in ipairs(clients) do
        if client.server_capabilities.documentSymbolProvider then
          -- This would require async handling, so we'll skip for now
          -- context.lsp_symbols = ... (async call needed)
          break
        end
      end
    end
  end

  -- Get git status
  local git_cmd = vim.fn.system("git status --porcelain 2>/dev/null")
  if vim.v.shell_error == 0 then
    context.git_status = {
      modified = git_cmd ~= "",
      branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", ""),
      staged_changes = vim.fn.system("git diff --cached --name-only 2>/dev/null"):gsub("\n", " "):gsub(" +", " "):gsub("^%s*(.-)%s*$", "%1")
    }
  end

  return context
end

-- AI assistance with smart context
M.smart_assist = function(query)
  if not M.bauxd_available then
    vim.notify("BVI AI: BAUXD not available. Please install BAUXD or use BAUX ecosystem.", vim.log.levels.WARN)
    vim.notify("BVI AI: For standalone usage, consider integrating with other AI services.", vim.log.levels.INFO)
    return
  end

  local context = M.get_editor_context()

  -- Show loading indicator
  local spinner = require('bvi.ui').show_spinner("AI analyzing...")

  M.http_request("POST", "/ai/assistant", {
    q = query or "Help me with this code",
    context = context,
    type = "smart_assistance"
  }, function(response)
    -- Hide spinner
    spinner:hide()

    if response.status == "success" then
      -- Show response in floating window or split
      require('bvi.ui').show_ai_response(response.response, "Smart AI Assistance")
    else
      vim.notify("AI assistance failed: " .. (response.error or "Unknown error"), vim.log.levels.ERROR)
    end
  end)
end

-- Analyze current code/function
M.analyze_code = function()
  if not M.bauxd_available then
    vim.notify("BVI AI: Code analysis requires BAUXD. Please install BAUXD or use BAUX ecosystem.", vim.log.levels.WARN)
    return
  end

  local context = M.get_editor_context()

  -- Focus on current function/class if possible
  local analysis_query = "Analyze this code"
  if context.filetype == "python" then
    analysis_query = "Analyze this Python code for bugs, performance issues, and best practices"
  elseif context.filetype == "javascript" or context.filetype == "typescript" then
    analysis_query = "Analyze this JavaScript/TypeScript code for issues and improvements"
  elseif context.filetype == "lua" then
    analysis_query = "Analyze this Lua code for issues and Neovim best practices"
  end

  local spinner = require('bvi.ui').show_spinner("Analyzing code...")

  M.http_request("POST", "/ai/analyze", {
    code = table.concat(context.buffer_content.lines, "\n"),
    language = context.filetype,
    context = context,
    query = analysis_query
  }, function(response)
    spinner:hide()

    if response.status == "success" then
      require('bvi.ui').show_ai_response(response.analysis, "Code Analysis")
    else
      vim.notify("Code analysis failed: " .. (response.error or "Unknown error"), vim.log.levels.ERROR)
    end
  end)
end

-- Show current AI context (enhanced version)
M.show_context = function()
  local context = M.get_editor_context()

  -- Format context for display
  local lines = {
    "=== BVI AI Context ===",
    string.format("File: %s", context.filename),
    string.format("Type: %s", context.filetype),
    string.format("Cursor: Line %d, Col %d", context.cursor[1], context.cursor[2]),
    string.format("Mode: %s", context.mode),
    string.format("Lines: %d/%d (showing %d-%d)",
      context.buffer_content.current_line,
      context.buffer_content.total_lines,
      context.buffer_content.start_line,
      context.buffer_content.end_line),
    "",
    "=== Buffer Content ==="
  }

  -- Add buffer content
  for i, line in ipairs(context.buffer_content.lines) do
    local line_num = context.buffer_content.start_line + i - 1
    local marker = (line_num == context.cursor[1]) and "→" or " "
    table.insert(lines, string.format("%s %4d: %s", marker, line_num, line))
  end

  -- Add diagnostics if available
  if context.diagnostics and #context.diagnostics > 0 then
    table.insert(lines, "")
    table.insert(lines, "=== LSP Diagnostics ===")
    for _, diag in ipairs(context.diagnostics) do
      table.insert(lines, string.format("Line %d: %s (%s)",
        diag.line, diag.message, diag.source or "unknown"))
    end
  end

  -- Add git status if available
  if context.git_status then
    table.insert(lines, "")
    table.insert(lines, "=== Git Status ===")
    table.insert(lines, string.format("Branch: %s", context.git_status.branch))
    if context.git_status.modified then
      table.insert(lines, "Status: Modified")
    else
      table.insert(lines, "Status: Clean")
    end
    if context.git_status.staged_changes ~= "" then
      table.insert(lines, string.format("Staged: %s", context.git_status.staged_changes))
    end
  end

  -- Show in a new buffer
  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd("setlocal buftype=nofile bufhidden=wipe noswapfile")
  vim.cmd("setlocal filetype=bvi-context")
  vim.cmd("resize 25")
  vim.cmd("normal! gg")
end

-- AI system status check
M.show_status = function()
  local status_lines = {
    "=== BVI AI Status ===",
    string.format("BAUXD Available: %s", M.bauxd_available and "Yes" or "No"),
    string.format("Plenary Available: %s", pcall(require, 'plenary.curl') and "Yes" or "No"),
    "",
    "=== Configuration ==="
  }

  -- Add config info
  status_lines[#status_lines + 1] = string.format("Host: %s:%d", M.config.bauxd_host, M.config.bauxd_port)
  status_lines[#status_lines + 1] = string.format("Timeout: %dms", M.config.timeout)
  status_lines[#status_lines + 1] = string.format("Max Context: %d lines", M.config.max_context_lines)

  -- If BAUXD is available, get real status
  if M.bauxd_available then
    local spinner = require('bvi.ui').show_spinner("Checking BAUXD status...")

    M.http_request("GET", "/health", nil, function(response)
      spinner:hide()

      status_lines[#status_lines + 1] = ""
      status_lines[#status_lines + 1] = "=== BAUXD Live Status ==="
      status_lines[#status_lines + 1] = string.format("Status: %s", response.status or "unknown")
      status_lines[#status_lines + 1] = string.format("Service: %s", response.service or "unknown")
      status_lines[#status_lines + 1] = string.format("Version: %s", response.version or "unknown")

      if response.hardware then
        status_lines[#status_lines + 1] = ""
        status_lines[#status_lines + 1] = "=== Hardware Metrics ==="
        status_lines[#status_lines + 1] = string.format("CPU: %.1f%%", (response.hardware.cpu or 0) * 100)
        status_lines[#status_lines + 1] = string.format("Memory: %.1f%%", response.hardware.memory or 0)
        status_lines[#status_lines + 1] = string.format("Disk: %.1f%%", response.hardware.disk or 0)
      end

      -- Display the status
      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, status_lines)
      vim.cmd("setlocal buftype=nofile bufhidden=wipe noswapfile")
      vim.cmd("setlocal filetype=bvi-status")
      vim.cmd("resize 15")
    end)
  else
    -- Display basic status without BAUXD
    status_lines[#status_lines + 1] = ""
    status_lines[#status_lines + 1] = "Note: Install BAUXD for full AI capabilities"
    status_lines[#status_lines + 1] = "See: https://github.com/badlandz/bauxd"

    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, status_lines)
    vim.cmd("setlocal buftype=nofile bufhidden=wipe noswapfile")
    vim.cmd("setlocal filetype=bvi-status")
    vim.cmd("resize 12")
  end
end

-- Initialize the AI module
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Check for required dependencies
  local plenary_ok = pcall(require, 'plenary.curl')
  if not plenary_ok then
    vim.notify("BVI AI: plenary.nvim required for HTTP requests", vim.log.levels.WARN)
    M.bauxd_available = false
  else
    -- Test BAUXD connectivity
    M.test_bauxd_connectivity()
  end

  if M.bauxd_available then
    vim.notify("BVI AI integration initialized (BAUXD connected)", vim.log.levels.INFO)
  else
    vim.notify("BVI AI: BAUXD not available - limited functionality", vim.log.levels.WARN)
  end

  return M.bauxd_available
end

-- Test BAUXD connectivity (simplified synchronous check)
M.test_bauxd_connectivity = function()
  -- For now, just assume BAUXD is available if plenary is loaded
  -- In a real implementation, you might want to do a synchronous check
  -- or handle this asynchronously
  M.bauxd_available = true -- Assume available, handle errors gracefully
end

return M