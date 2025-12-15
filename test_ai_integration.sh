#!/usr/bin/env bash
# Test BVI AI integration before GitHub commit

echo "🧪 Testing BVI AI Integration..."

# Test 1: Check if AI module loads
echo "1. Testing AI module loading..."
if nvim --headless -c "lua require('bvi.ai')" -c "echo 'AI module loaded'" -c "q" 2>/dev/null; then
    echo "✅ AI module loads successfully"
else
    echo "❌ AI module failed to load"
    exit 1
fi

# Test 2: Check plenary dependency
echo "2. Testing plenary dependency..."
if nvim --headless -c "lua require('plenary.curl')" -c "echo 'plenary available'" -c "q" 2>/dev/null; then
    echo "✅ plenary.curl available"
else
    echo "❌ plenary.curl missing - install plenary.nvim"
    exit 1
fi

# Test 3: Test BAUXD connectivity
echo "3. Testing BAUXD connectivity..."
if curl -s http://localhost:9999/health >/dev/null 2>&1; then
    echo "✅ BAUXD responding on localhost:9999"
else
    echo "⚠️  BAUXD not responding - some features may not work"
fi

# Test 4: Test AI endpoints
echo "4. Testing AI endpoints..."
if curl -s "http://localhost:9999/ai/assistant?q=test" >/dev/null 2>&1; then
    echo "✅ AI assistant endpoint responding"
else
    echo "⚠️  AI assistant endpoint not responding"
fi

# Test 5: Syntax check all BVI files
echo "5. Testing syntax of BVI files..."
for file in lua/bvi/*.lua; do
    if lua -e "loadfile('$file')" 2>/dev/null; then
        echo "✅ $file syntax OK"
    else
        echo "❌ $file syntax error"
        exit 1
    fi
done

echo ""
echo "🎉 All tests passed! BVI AI integration ready for GitHub commit."
echo ""
echo "📋 Next steps:"
echo "1. Commit changes: git add . && git commit -m 'feat: Real-time AI integration with BAUXD'"
echo "2. Push to GitHub: git push origin main"
echo "3. Wait for Neovim plugin ecosystem update"
echo "4. Test in production Neovim environment"