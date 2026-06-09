#!/usr/bin/env python3
"""Generate all iOS and Android app icon sizes from the 1024x1024 source."""

from PIL import Image
import os

SOURCE = '/Volumes/Toshiba /Gata-New/app_icon.png'
IOS_DIR = '/Volumes/Toshiba /Gata-New/ios/Runner/Assets.xcassets/AppIcon.appiconset'

# iOS icon sizes needed
ios_sizes = {
    'Icon-App-1024x1024@1x.png': 1024,
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
}

img = Image.open(SOURCE).convert('RGB')

for name, size in ios_sizes.items():
    resized = img.resize((size, size), Image.LANCZOS)
    path = os.path.join(IOS_DIR, name)
    resized.save(path, 'PNG')
    print(f'  {name} ({size}x{size})')

# Also save for Android
android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

android_base = '/Volumes/Toshiba /Gata-New/android/app/src/main/res'
for folder, size in android_sizes.items():
    resized = img.resize((size, size), Image.LANCZOS)
    path = os.path.join(android_base, folder, 'ic_launcher.png')
    resized.save(path, 'PNG')
    print(f'  {folder}/ic_launcher.png ({size}x{size})')

print('\nAll icons generated!')
