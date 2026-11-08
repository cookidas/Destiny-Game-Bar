using System;
using Microsoft.Gaming.XboxGameBar;
using Windows.ApplicationModel.Activation;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace DimGameBar
{
    sealed partial class App : Application
    {
        // Keep this alive for the lifetime of the widget's CoreWindow.
        private XboxGameBarWidget widget;

        public App()
        {
            InitializeComponent();
            Suspending += (sender, args) => { widget = null; };
        }

        protected override void OnActivated(IActivatedEventArgs args)
        {
            if (args.Kind != ActivationKind.Protocol ||
                !(args is IProtocolActivatedEventArgs protocol) ||
                !string.Equals(protocol.Uri.Scheme, "ms-gamebarwidget", StringComparison.OrdinalIgnoreCase))
                return;

            var activation = args as XboxGameBarWidgetActivatedEventArgs;
            if (activation == null || !activation.IsLaunchActivation || activation.AppExtensionId != "DimWidget")
                return;

            var frame = new Frame();
            Window.Current.Content = frame;
            widget = new XboxGameBarWidget(activation, Window.Current.CoreWindow, frame);
            frame.Navigate(typeof(MainPage));
            Window.Current.Closed += OnWidgetClosed;
            Window.Current.Activate();
        }

        protected override void OnLaunched(LaunchActivatedEventArgs args)
        {
            if (args.PrelaunchActivated)
                return;

            if (Window.Current.Content == null)
                Window.Current.Content = new MainPage();
            Window.Current.Activate();
        }

        private void OnWidgetClosed(object sender, CoreWindowEventArgs args)
        {
            ((Window.Current.Content as Frame)?.Content as MainPage)?.Close();
            Window.Current.Closed -= OnWidgetClosed;
            widget = null;
        }
    }
}
