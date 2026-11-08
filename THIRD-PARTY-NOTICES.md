# Third-party notices

Destiny Game Bar is an unofficial companion-site widget. It is not affiliated with or endorsed by Bungie, Microsoft, or the linked websites. Website content, names, logos, and favicons belong to their respective owners; the source-code MIT license does not relicense those assets.

## Game Bar sample

App activation and package manifest code are based on Microsoft's [XboxGameBarSamples / WidgetSampleCS](https://github.com/microsoft/XboxGameBarSamples/tree/master/Samples/WidgetSampleCS). The Microsoft MIT copyright and license notice is retained in LICENSE.

## NuGet dependencies

The project uses Microsoft.Gaming.XboxGameBar, Microsoft.NETCore.UniversalWindowsPlatform, Microsoft.UI.Xaml and the transitively resolved Microsoft.Web.WebView2 SDK. Their licenses are supplied with the respective NuGet packages. Packaged runtime framework dependencies retain their original Microsoft signatures and license terms. The EXE installer includes Microsoft's signed Evergreen WebView2 bootstrapper and runs it only when the Runtime is missing. Runtime deployment follows [Microsoft's distribution guidance](https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution); Microsoft's terms apply to the Runtime.

## Website icons

Icons are included to identify navigation destinations. No ownership of these icons is claimed.

| File | Source |
|---|---|
| DimFavicon.png | https://app.destinyitemmanager.com/favicon-32x32.png |
| LightGgFavicon.png | Google's favicon cache for www.light.gg |
| DestinyReportFavicon.png | https://destiny.report/a/516d040b.png |
| D2ArmorPickerFavicon.png | https://d2armorpicker.com/favicon.ico (PNG content) |
| RaidReportFavicon.png | https://raid.report/apple-touch-icon.png |
| BrayTechFavicon.png | https://bray.tech/static/images/icons/icon-48.png |
| BlueberriesFavicon.png | https://www.blueberries.gg/wp-content/uploads/2023/04/cropped-Favicon-32x32.png |
| EngramBlueFavicon.png | https://engram.blue/favicon.png |
| GuardianReportFavicon.png | https://guardian.report/assets/favicon/favicon-32x32.png |
| DestinyTrackerFavicon.png | Google's favicon cache for destinytracker.com |

## Tests only

Tests use happy-dom, dnd-core and react-dnd-html5-backend. They are not included in the installed widget; their package licenses apply when installing test dependencies.
