#!/bin/bash

# Script para desarrollo rápido de RunAI
echo "🏃‍♂️ RunAI - Quick Run"

# Evitar múltiples instancias
pkill -f "Simulator" 2>/dev/null || true
xcrun simctl shutdown all 2>/dev/null || true

# Usar iPhone 16
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16" | head -1 | grep -o '[A-F0-9-]\{36\}')

if [ -z "$DEVICE_ID" ]; then
    echo "❌ iPhone 16 no encontrado"
    exit 1
fi

echo "📱 iPhone 16 ($DEVICE_ID)"

# Compilar, instalar y lanzar
echo "🔨 Compilando..."
xcodebuild -project runai.xcodeproj -scheme runai -destination "platform=iOS Simulator,id=$DEVICE_ID" build -quiet && \
xcrun simctl boot "$DEVICE_ID" 2>/dev/null && \
open -a Simulator && \
sleep 2 && \
xcrun simctl install "$DEVICE_ID" ~/Library/Developer/Xcode/DerivedData/runai-*/Build/Products/Debug-iphonesimulator/runai.app && \
xcrun simctl launch "$DEVICE_ID" barreiro.runai

echo "✅ RunAI ejecutándose"
