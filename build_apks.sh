#!/bin/bash
# build_apks.sh
# Script to generate multiple APKs for a Flutter app (split per ABI)

set -e

# Step 1: Clean old builds
echo "🧹 Cleaning old builds..."
flutter clean

# Step 2: Build split APKs
echo "⚙️ Building split APKs..."
flutter build apk --split-per-abi

# Step 3: Create output directory
OUTPUT_DIR="release_apks"
mkdir -p $OUTPUT_DIR

# Step 4: Copy and rename APKs
echo "📦 Collecting APKs..."
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk $OUTPUT_DIR/app-release-armeabi-v7a.apk
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk $OUTPUT_DIR/app-release-arm64-v8a.apk
cp build/app/outputs/flutter-apk/app-x86_64-release.apk $OUTPUT_DIR/app-release-x86_64.apk

# Optional: also keep a fat APK for testing
cp build/app/outputs/flutter-apk/app-release.apk $OUTPUT_DIR/app-release-fat.apk

echo "✅ Done! APKs are available in the $OUTPUT_DIR folder:"
ls -lh $OUTPUT_DIR
