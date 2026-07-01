#!/bin/bash
echo "Đang build APK thông qua Docker..."
docker run --rm -v "$(pwd):/app" -w /app ghcr.io/cirruslabs/flutter:3.29.0 bash -c "flutter build apk --release"
echo "Hoàn tất! File APK nằm ở: build/app/outputs/flutter-apk/app-release.apk"
