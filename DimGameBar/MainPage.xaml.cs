using System;
using Microsoft.Web.WebView2.Core;
using Windows.Storage;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Automation;
using Windows.UI.Xaml.Media.Imaging;

namespace DimGameBar
{
    public sealed partial class MainPage : Page
    {
        private const string DimUrl = "https://app.destinyitemmanager.com/";
        private static readonly (string Name, string Url, string Icon)[] ShortcutSites =
        {
            ("DIM", "https://app.destinyitemmanager.com/", "DimFavicon.png"),
            ("Light.gg", "https://www.light.gg/", "LightGgFavicon.png"),
            ("Destiny Report", "https://destiny.report/", "DestinyReportFavicon.png"),
            ("D2ArmorPicker", "https://d2armorpicker.com/", "D2ArmorPickerFavicon.png"),
            ("Raid Report", "https://raid.report/", "RaidReportFavicon.png"),
            ("Bray.Tech", "https://bray.tech/", "BrayTechFavicon.png"),
            ("Blueberries.gg", "https://www.blueberries.gg/", "BlueberriesFavicon.png"),
            ("Engram.Blue", "https://engram.blue/", "EngramBlueFavicon.png"),
            ("Guardian.Report", "https://guardian.report/", "GuardianReportFavicon.png"),
            ("DestinyTracker", "https://destinytracker.com/", "DestinyTrackerFavicon.png"),
        };
        private bool started;
        private bool closed;

        public MainPage()
        {
            InitializeComponent();
            InitializeShortcuts();
        }

        private void InitializeShortcuts()
        {
            var settings = ApplicationData.Current.LocalSettings;
            for (var i = 0; i < ShortcutSites.Length; i++)
            {
                var site = ShortcutSites[i];
                var key = "Shortcut:" + site.Url;
                var selected = settings.Values[key] is bool saved ? saved : i < 3;
                var button = new Button
                {
                    Style = (Style)Resources["ToolbarButton"],
                    Tag = site.Url,
                    Content = CreateShortcutIcon(site.Icon),
                    Visibility = selected ? Visibility.Visible : Visibility.Collapsed,
                };
                button.Click += OpenShortcut;
                ToolTipService.SetToolTip(button, site.Name);
                AutomationProperties.SetName(button, site.Name + " 열기");
                ShortcutBar.Children.Add(button);

                var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
                row.Children.Add(CreateShortcutIcon(site.Icon));
                row.Children.Add(new TextBlock { Text = site.Name, VerticalAlignment = VerticalAlignment.Center });
                var option = new CheckBox { Content = row, IsChecked = selected };
                AutomationProperties.SetName(option, site.Name);
                RoutedEventHandler changed = (s, e) =>
                {
                    var enabled = option.IsChecked == true;
                    button.Visibility = enabled ? Visibility.Visible : Visibility.Collapsed;
                    settings.Values[key] = enabled;
                };
                option.Checked += changed;
                option.Unchecked += changed;
                ShortcutOptions.Children.Add(option);
            }
        }

        private static Image CreateShortcutIcon(string fileName) => new Image
        {
            Source = new BitmapImage(new Uri("ms-appx:///Assets/" + fileName)),
            Width = 24,
            Height = 24,
        };

        private async void OnLoaded(object sender, RoutedEventArgs args)
        {
            if (started)
                return;
            started = true;

            try
            {
                await Browser.EnsureCoreWebView2Async();
                if (closed)
                    return;

                var core = Browser.CoreWebView2;
                core.HistoryChanged += (s, e) => UpdateNavigation();
                core.NavigationStarting += OnNavigationStarting;
                core.NavigationCompleted += OnNavigationCompleted;
                core.NewWindowRequested += OnNewWindowRequested;
                core.ProcessFailed += (s, e) =>
                {
                    BackButton.IsEnabled = ForwardButton.IsEnabled = ReloadButton.IsEnabled = false;
                    ShowStatus("웹뷰가 중단됐습니다. 위젯을 닫고 다시 열어 주세요.");
                };
                core.Settings.IsStatusBarEnabled = false;

                var file = await StorageFile.GetFileFromApplicationUriAsync(new Uri("ms-appx:///DragBridge.js"));
                var script = await FileIO.ReadTextAsync(file);
                if (closed)
                    return;

                // Never inject the input shim into Bungie or identity-provider login pages.
                await core.AddScriptToExecuteOnDocumentCreatedAsync(
                    "if (window === window.top && location.origin === 'https://app.destinyitemmanager.com') {\n" +
                    script + "\n}");
                if (closed)
                    return;

                ReloadButton.IsEnabled = true;
                core.Navigate(DimUrl);
            }
            catch (Exception error)
            {
                if (!closed)
                    ShowStatus($"WebView2 초기화 실패 (0x{error.HResult:X8}). WebView2 Runtime 설치를 확인한 뒤 위젯을 다시 열어 주세요.");
            }
        }

        private void OnNavigationStarting(CoreWebView2 sender, CoreWebView2NavigationStartingEventArgs args)
        {
            if (!IsHttps(args.Uri))
            {
                args.Cancel = true;
                ShowStatus("HTTPS 웹 페이지만 열 수 있습니다.");
                return;
            }
            StatusText.Visibility = Visibility.Collapsed;
        }

        private void OnNavigationCompleted(CoreWebView2 sender, CoreWebView2NavigationCompletedEventArgs args)
        {
            UpdateNavigation();
            if (!args.IsSuccess && args.WebErrorStatus != CoreWebView2WebErrorStatus.OperationCanceled)
                ShowStatus($"페이지를 불러오지 못했습니다 ({args.WebErrorStatus}). 새로고침을 눌러 다시 시도하세요.");
        }

        private void OnNewWindowRequested(CoreWebView2 sender, CoreWebView2NewWindowRequestedEventArgs args)
        {
            args.Handled = true;
            // shortcut: one browsing surface; add a transient child WebView if an OAuth provider requires window.opener.
            if (IsHttps(args.Uri))
                sender.Navigate(args.Uri);
            else
                ShowStatus("HTTPS 웹 페이지만 열 수 있습니다.");
        }

        private static bool IsHttps(string address) =>
            Uri.TryCreate(address, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps;

        private void UpdateNavigation()
        {
            BackButton.IsEnabled = Browser.CoreWebView2?.CanGoBack == true;
            ForwardButton.IsEnabled = Browser.CoreWebView2?.CanGoForward == true;
        }

        private void GoBack(object sender, RoutedEventArgs args)
        {
            if (Browser.CoreWebView2?.CanGoBack == true)
                Browser.CoreWebView2.GoBack();
        }

        private void GoForward(object sender, RoutedEventArgs args)
        {
            if (Browser.CoreWebView2?.CanGoForward == true)
                Browser.CoreWebView2.GoForward();
        }

        private void Reload(object sender, RoutedEventArgs args) => Browser.CoreWebView2?.Reload();

        private void OpenShortcut(object sender, RoutedEventArgs args)
        {
            var address = (sender as Button)?.Tag as string;
            if (IsHttps(address))
                Browser.CoreWebView2?.Navigate(address);
        }

        private void ShowStatus(string message)
        {
            StatusText.Text = message;
            StatusText.Visibility = Visibility.Visible;
        }

        public void Close()
        {
            if (closed)
                return;
            closed = true;
            Browser.Close();
        }
    }
}
