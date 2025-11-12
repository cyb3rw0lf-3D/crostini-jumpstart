#!/bin/bash
set -e

echo "🚀 Building Celeste-WASM single HTML build..."

# Clone if missing
if [ ! -d "celeste-wasm" ]; then
  git clone https://github.com/MercuryWorkshop/celeste-wasm.git
fi

cd celeste-wasm

echo "📦 Installing npm dependencies..."
npm install

# 🩹 Patch the epoxy.ts Blob type issue (auto-fix)
echo "🩹 Patching epoxy.ts type issue..."
sed -i 's/new Blob(\[payload[^)]*\])/new Blob([new Uint8Array(payload.buffer)])/g' frontend/src/epoxy.ts || true

echo "🔨 Building project..."
npm run build

# Inline everything
echo "🧩 Combining all files into one..."
npm install -g inliner
inliner dist/index.html > ../celeste.html

cd ..

echo ""
echo "✅ Build complete!"
echo "Open the file:"
echo "   $(pwd)/celeste.html"
echo ""
echo "💡 Works offline — just double-click it in Chrome."
