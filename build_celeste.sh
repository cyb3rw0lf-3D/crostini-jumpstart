#!/bin/bash
set -e

# --- Setup ---
echo "🚀 Building Celeste-WASM single HTML build..."

# Clone repo if not already there
if [ ! -d "celeste-wasm" ]; then
  git clone https://github.com/MercuryWorkshop/celeste-wasm.git
fi

cd celeste-wasm

# --- Install dependencies ---
echo "📦 Installing npm dependencies..."
npm install

# --- Build the web version ---
echo "🔨 Building project..."
sed -i 's/new Blob(\[payload\])/new Blob([payload as Uint8Array])/g' frontend/src/epoxy.ts
npm run build

# --- Inline everything into a single HTML file ---
echo "🧩 Combining all files into one..."
npm install -g inliner
inliner dist/index.html > ../celeste.html

cd ..

# --- Done ---
echo ""
echo "✅ Build complete!"
echo "Open the file:"
echo "   $(pwd)/celeste.html"
echo ""
echo "💡 Tip: You can open it directly in Chrome or any browser — it works offline."
