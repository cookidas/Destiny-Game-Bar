# Destiny Game Bar

An unofficial widget for accessing DIM and other Destiny-related websites inside Xbox Game Bar on Windows 11. It uses a single WebView2 instance to navigate between sites and includes a workaround for the mouse drag-and-drop issues found in the standard browser widget.

## Installation

1. Download the ZIP archive from **Releases** and extract it.
2. Run **`install.bat`**.
3. Once installation is complete, press `Win+G` → open the Widget menu → select Destiny Game Bar.

For detailed manual installation instructions, see the [Manual Installation Guide](Release/INSTALL.md).

The current GitHub release is a self-signed preview. Windows may display a warning about an unverified publisher. Certificate registration takes place when you click Install and approve the Windows permission prompt. This is not a Microsoft Store release and is not signed with a publicly trusted code-signing certificate. The signing private key is not distributed.

**Requirements:** Windows 11 x64, Xbox Game Bar, and an internet connection.

After installation, press `Win+G` → open the Widget menu → select **Destiny Game Bar**.

## Features

- Back, forward, and refresh controls
- Website shortcut selection through the ⋮ menu in the upper-right corner
- Favicon shortcuts for selected websites, with your selections saved
- Horizontal scrolling in the shortcut bar when the window is narrow
- Game Bar's built-in widget resizing and pinning
- A mouse drag-and-drop workaround for DIM

DIM, Light.gg, and Destiny Report are selected by default. The widget does not keep hidden tabs open for each website. Clicking a shortcut navigates to that site in the current webview.

| Order | Website | URL |
|---|---|---|
| 1 | DIM | https://app.destinyitemmanager.com/ |
| 2 | Light.gg | https://www.light.gg/ |
| 3 | Destiny Report | https://destiny.report/ |
| 4 | D2ArmorPicker | https://d2armorpicker.com/ |
| 5 | Raid Report | https://raid.report/ |
| 6 | Bray.Tech | https://bray.tech/ |
| 7 | Blueberries.gg | https://www.blueberries.gg/ |
| 8 | Engram.Blue | https://engram.blue/ |
| 9 | Guardian.Report | https://guardian.report/ |
| 10 | DestinyTracker | https://destinytracker.com/ |

## Sign-in and Storage

Sign in directly on each website. The widget's cookies, cache, and login sessions are stored in its own WebView2 app data, separate from regular Edge or Chrome. Shortcut selections are saved in the Windows app's local settings. The app does not operate a separate account server or include password or token collection features. Each website's own policies apply to its handling of your data.

## Known Limitations

- Input response and image rendering may slow down when the game is under heavy load.
- WebView2 memory usage may increase as you navigate between websites. The cause and memory-reclamation behavior are still being investigated.
- The drag-and-drop workaround applies only to mouse input on the top-level DIM page. It does not cover touch dragging or dragging files from outside the webview.
- New-window requests open in the current webview. Some sign-in popups that require `window.opener` still need compatibility testing.
- Windows ARM64 and Windows 10 are not supported by this package.

## Build from Source

Visual Studio 2022 or later is required, with the C# UWP/.NET Native tools, Windows SDK **10.0.26100.0**, and C++ x64 tools for Release builds. An internet connection is required to restore NuGet packages. The project cannot be built using only `dotnet build` from the standard .NET SDK.

```powershell
.\Build.ps1 -Configuration Debug
```

Alternatively, open `DimGameBar.sln`, build with the Debug/x64 configuration, and right-click the project → Deploy on a PC with Developer Mode enabled. The display name is Destiny Game Bar. The internal project and package identifiers remain DimGameBar to maintain continuity with existing installations.

## License and Attribution

The MIT notice for the portions based on WidgetSampleCS from Microsoft's XboxGameBarSamples is retained in [LICENSE](LICENSE). See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the sources of website favicons and external components. This app is not an official product of Bungie, Microsoft, or any of the linked websites.
