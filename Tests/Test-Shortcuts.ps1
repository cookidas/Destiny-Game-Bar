$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot '../DimGameBar'
$source = Get-Content (Join-Path $project 'MainPage.xaml.cs') -Raw
$catalogStart = $source.IndexOf('        private static readonly (')
$catalogEnd = $source.IndexOf('        private bool started;')
$methodsStart = $source.IndexOf('        private void InitializeShortcuts()')
$methodsEnd = $source.IndexOf('        private async void OnLoaded')
$production = $source.Substring($catalogStart, $catalogEnd - $catalogStart) + $source.Substring($methodsStart, $methodsEnd - $methodsStart)
# Run the production initialization and event closures against in-memory UI/storage doubles.
$stub = @'
using System;
using System.Collections.Generic;
using System.Linq;
namespace ShortcutTests {
public enum Visibility { Visible, Collapsed }
public enum Orientation { Horizontal }
public enum VerticalAlignment { Center }
public class RoutedEventArgs : EventArgs { }
public delegate void RoutedEventHandler(object sender, RoutedEventArgs e);
public class Style { }
public class Button {
 public Style Style; public object Tag, Content; public Visibility Visibility;
 public event RoutedEventHandler Click;
 public void InvokeClick() { Click?.Invoke(this, new RoutedEventArgs()); }
}
public class StackPanel { public Orientation Orientation; public double Spacing; public List<object> Children = new List<object>(); }
public class TextBlock { public string Text; public VerticalAlignment VerticalAlignment; }
public class Image { public BitmapImage Source; public double Width, Height; }
public class BitmapImage { public Uri Uri; public BitmapImage(Uri uri) { Uri = uri; } }
public class CheckBox {
 public object Content; private bool? value;
 public bool? IsChecked { get { return value; } set { if (this.value == value) return; this.value = value;
   if (value == true) Checked?.Invoke(this, new RoutedEventArgs()); else Unchecked?.Invoke(this, new RoutedEventArgs()); } }
 public event RoutedEventHandler Checked, Unchecked;
}
public static class ToolTipService { public static void SetToolTip(object target, string value) {} }
public static class AutomationProperties { public static void SetName(object target, string value) {} }
public class Values : Dictionary<string, object> { public new object this[string key] { get { object v; return TryGetValue(key, out v) ? v : null; } set { base[key] = value; } } }
public class Settings { public Values Values = new Values(); }
public class ApplicationData { public static ApplicationData Current = new ApplicationData(); public Settings LocalSettings = new Settings(); }
public class Harness {
 public Dictionary<string, object> Resources = new Dictionary<string, object> { {"ToolbarButton", new Style()} };
 public StackPanel ShortcutBar = new StackPanel(), ShortcutOptions = new StackPanel();
 private void OpenShortcut(object sender, RoutedEventArgs e) { }
 public Harness() { InitializeShortcuts(); }
'@
$checks = @'
 static void Check(bool ok, string message) { if (!ok) throw new Exception(message); }
 public static void Run() {
  var names = new[] { "DIM", "Light.gg", "Destiny Report", "D2ArmorPicker", "Raid Report", "Bray.Tech", "Blueberries.gg", "Engram.Blue", "Guardian.Report", "DestinyTracker" };
  var page = new Harness();
  Check(page.ShortcutBar.Children.Count == 10 && page.ShortcutOptions.Children.Count == 10, "Missing shortcut or checkbox");
  for (int i=0; i<10; i++) {
   var option=(CheckBox)page.ShortcutOptions.Children[i]; var row=(StackPanel)option.Content;
   Check(((TextBlock)row.Children[1]).Text == names[i], "Menu order or label changed");
   Check(row.Children[0] is Image && ((Button)page.ShortcutBar.Children[i]).Content is Image, "Favicon missing");
   Check(option.IsChecked == (i<3), "Default selection changed");
  }
  ((CheckBox)page.ShortcutOptions.Children[9]).IsChecked=true;
  ((CheckBox)page.ShortcutOptions.Children[0]).IsChecked=false;
  Check(((Button)page.ShortcutBar.Children[9]).Visibility==Visibility.Visible, "Check did not show selected icon");
  Check(((Button)page.ShortcutBar.Children[0]).Visibility==Visibility.Collapsed, "Uncheck did not hide selected icon");
  var reopened=new Harness();
  Check(((CheckBox)reopened.ShortcutOptions.Children[9]).IsChecked==true && ((CheckBox)reopened.ShortcutOptions.Children[0]).IsChecked==false, "Selections not restored");
  Check(((CheckBox)reopened.ShortcutOptions.Children[1]).IsChecked==true, "Other selection changed");
  foreach (CheckBox option in reopened.ShortcutOptions.Children) option.IsChecked=false;
  Check(new Harness().ShortcutBar.Children.Cast<Button>().All(b=>b.Visibility==Visibility.Collapsed), "Empty selection not preserved");
  foreach (CheckBox option in reopened.ShortcutOptions.Children) option.IsChecked=true;
  Check(new Harness().ShortcutBar.Children.Cast<Button>().All(b=>b.Visibility==Visibility.Visible), "All selections not preserved");
 }
}}
'@
Add-Type -TypeDefinition ($stub + $production + $checks) -CompilerOptions '/langversion:7.3'
[ShortcutTests.Harness]::Run()
[xml]$xml = Get-Content (Join-Path $project 'MainPage.xaml') -Raw
[xml]$proj = Get-Content (Join-Path $project 'DimGameBar.csproj') -Raw
$items = @($proj.SelectNodes("//*[local-name()='Content']") | ForEach-Object Include)
foreach ($match in [regex]::Matches($production, '"([A-Za-z]+Favicon\.png)"')) {
    $path = 'Assets\' + $match.Groups[1].Value
    if ($items -notcontains $path -or !(Test-Path (Join-Path $project $path))) { throw "Favicon not packaged: $path" }
    $bytes = [IO.File]::ReadAllBytes((Join-Path $project $path))
    if ([BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A') { throw "Invalid PNG: $path" }
}
Write-Output 'PASS: 10 ordered menu items; toggle show/hide; saved selection; empty/all selections; packaged PNGs; XAML XML'
