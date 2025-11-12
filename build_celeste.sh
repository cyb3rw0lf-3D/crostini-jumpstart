#!/bin/bash
set -e

echo "🚀 Building Celeste-WASM single HTML build..."

# Clone if missing, else update existing repo
if [ ! -d "celeste-wasm" ]; then
  git clone https://github.com/MercuryWorkshop/celeste-wasm.git
else
  echo "🔁 Updating existing repo..."
  cd celeste-wasm
  git pull
  cd ..
fi

cd celeste-wasm

echo "📦 Installing npm dependencies..."
npm install

# 🩹 Apply patch for TypeScript Blob type issue
PATCH_FILE="frontend/src/epoxy.ts"
echo "🩹 Patching $PATCH_FILE..."
if grep -q "payload as Uint8Array" "$PATCH_FILE"; then
  sed -i 's/new Blob(\[payload as Uint8Array\])/new Blob([new Uint8Array(payload.buffer)])/g' "$PATCH_FILE"
fi

echo "🔨 Building project..."
npm run build

# 🧩 Inline all files into one HTML (install inliner only if missing)
if ! command -v inliner &> /dev/null; then
  echo "📥 Installing inliner..."
  npm install -g inliner
fi

echo "🧩 Combining all files into one..."
inliner dist/index.html > ../celeste.html

cd ..

echo ""
echo "✅ Build complete!"
echo "Your offline-ready file is here:"
echo "   $(pwd)/celeste.html"
echo ""
echo "💡 You can double-click it in Chrome — it works offline."
