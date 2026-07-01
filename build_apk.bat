@echo off
echo Dang build APK thong qua Docker...
docker run --rm -v "%cd%:/app" -w /app ghcr.io/cirruslabs/flutter:3.29.0 bash -c "flutter build apk --release"
echo Hoan tat! File APK nam o: build/app/outputs/flutter-apk/app-release.apk
pause
