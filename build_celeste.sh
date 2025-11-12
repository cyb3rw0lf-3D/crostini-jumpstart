#!/bin/bash
set -e

echo "🚀 Building Celeste-WASM single HTML build..."

# Clone if missing, else update
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

# 🩹 Hard patch epoxy.ts to fix Blob typing
echo "🩹 Applying epoxy.ts patch..."
PATCH_FILE="frontend/src/epoxy.ts"
if grep -q "new Blob" "$PATCH_FILE"; then
  # replace all instances of new Blob([payload]) and variants
  sed -i 's/new Blob(\[payload[^\]]*\])/new Blob([new Uint8Array(payload.buffer)])/g' "$PATCH_FILE"
fi

# verify it applied
grep "new Uint8Array(payload.buffer)" "$PATCH_FILE" || {
  echo "❌ Patch failed to apply, please check epoxy.ts manually."
  exit 1
}

echo "🔨 Building project..."
npm run build

# Inline everything into one file
echo "🧩 Combining all files into one..."
npm install -g inliner
inliner dist/index.html > ../celeste.html

cd ..

echo ""
echo "✅ Build complete!"
echo "Your offline-ready file is here:"
echo "   $(pwd)/celeste.html"
echo ""
echo "💡 You can double-click it in Chrome — no server needed."
