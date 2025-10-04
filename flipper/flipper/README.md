# Transparent Window App

A SwiftUI macOS application that creates a transparent, draggable, and resizable window.

## Features

- **Transparent background** - Window shows what's behind it
- **Draggable** - Click and drag anywhere in the window to move it
- **Resizable** - Standard resize handles work normally
- **Visual border** - Blue border indicates window bounds
- **Floating window** - Stays above other windows

## Building

1. Open Xcode
2. Create a new macOS App project
3. Replace the auto-generated files with the provided Swift files
4. Set the deployment target to macOS 12.0 or later
5. Build and run (Cmd+R)

## Files

- `TransparentWindowApp.swift` - Main app entry point and window configuration
- `ContentView.swift` - SwiftUI view with transparent background and border
- `Info.plist` - App configuration

## How It Works

The app uses:
- `NSWindow` properties (`isOpaque = false`, `backgroundColor = .clear`) for transparency
- `isMovableByWindowBackground = true` for drag-anywhere functionality
- Standard SwiftUI frame modifiers for resizing
- A blue stroke border for visibility
