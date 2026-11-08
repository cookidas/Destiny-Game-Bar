using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Security.Principal;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;

internal static class Setup
{
    [STAThread]
    private static int Main(string[] args)
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        try
        {
            if (args.Length == 1 && args[0] == "--trust-certificate")
            {
                if (!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))
                    throw new InvalidOperationException("인증서 등록에는 관리자 권한이 필요합니다.");
                using (var certificate = ReadCertificate())
                using (var store = new X509Store(StoreName.TrustedPeople, StoreLocation.LocalMachine))
                {
                    store.Open(OpenFlags.ReadWrite);
                    store.Add(certificate);
                }
                return 0;
            }
            if (args.Length == 1 && args[0] == "--verify-payload")
            {
                VerifyResources();
                return 0;
            }
            if (args.Length != 0) return 2;
            Application.Run(new SetupWindow());
            return 0;
        }
        catch (Exception error)
        {
            if (args.Length != 1 || args[0] != "--verify-payload")
                MessageBox.Show(error.Message, "Destiny Game Bar 설치", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    internal static byte[] Resource(string name)
    {
        using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
        using (var buffer = new MemoryStream())
        {
            if (stream == null) throw new InvalidDataException("설치 파일이 손상됐습니다: " + name);
            stream.CopyTo(buffer);
            return buffer.ToArray();
        }
    }

    internal static void CheckHash(byte[] bytes, string expected)
    {
        using (var sha = SHA256.Create())
        {
            var actual = BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "");
            if (!String.Equals(actual, expected, StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("설치 파일 무결성 검사에 실패했습니다. 다시 다운로드해 주세요.");
        }
    }

    internal static X509Certificate2 ReadCertificate()
    {
        var bytes = Resource("DestinyGameBar.Certificate");
        CheckHash(bytes, BuildInfo.CertificateSha256);
        var certificate = new X509Certificate2(bytes);
        if (certificate.HasPrivateKey || certificate.Subject != "CN=DimGameBar" ||
            certificate.NotBefore > DateTime.Now || certificate.NotAfter < DateTime.Now)
        {
            certificate.Dispose();
            throw new InvalidDataException("설치 인증서 또는 PC의 날짜를 확인해 주세요.");
        }
        return certificate;
    }

    internal static byte[] VerifyResources()
    {
        var payload = Resource("DestinyGameBar.Payload");
        CheckHash(payload, BuildInfo.PayloadSha256);
        CheckHash(Resource("DestinyGameBar.WebView2Setup"), BuildInfo.RuntimeSha256);
        using (var certificate = ReadCertificate()) { }
        return payload;
    }

    internal static string SafePath(string root, string entry)
    {
        var path = Path.GetFullPath(Path.Combine(root, entry));
        if (!path.StartsWith(Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar) +
            Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            throw new InvalidDataException("설치 압축 파일의 경로가 올바르지 않습니다.");
        return path;
    }

    internal static void Extract(byte[] bytes, string root)
    {
        using (var memory = new MemoryStream(bytes))
        using (var zip = new ZipArchive(memory, ZipArchiveMode.Read))
        {
            foreach (var entry in zip.Entries)
            {
                var path = SafePath(root, entry.FullName);
                if (String.IsNullOrEmpty(entry.Name)) { Directory.CreateDirectory(path); continue; }
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                using (var source = entry.Open())
                using (var target = new FileStream(path, FileMode.CreateNew, FileAccess.Write))
                    source.CopyTo(target);
            }
        }
    }

    internal static bool CertificateTrusted()
    {
        using (var certificate = ReadCertificate())
        using (var store = new X509Store(StoreName.TrustedPeople, StoreLocation.LocalMachine))
        {
            store.Open(OpenFlags.ReadOnly);
            return store.Certificates.Find(X509FindType.FindByThumbprint, certificate.Thumbprint, false).Count != 0;
        }
    }

    internal static bool RuntimeInstalled()
    {
        const string client = @"\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}";
        foreach (var key in new[] { @"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node" + client,
                                   @"HKEY_CURRENT_USER\Software" + client })
        {
            Version version;
            if (Version.TryParse(Registry.GetValue(key, "pv", null) as string, out version) && version.Major > 0)
                return true;
        }
        return false;
    }

    internal static void PowerShell(string script)
    {
        var start = new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
            @"WindowsPowerShell\v1.0\powershell.exe"));
        var command = "[Console]::OutputEncoding=[Text.Encoding]::UTF8;$ErrorActionPreference='Stop';try{" +
            script + "}catch{[Console]::Error.WriteLine($_.Exception.Message);exit 1}";
        start.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand " +
            Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
        start.UseShellExecute = false;
        start.CreateNoWindow = true;
        start.RedirectStandardOutput = start.RedirectStandardError = true;
        start.StandardOutputEncoding = start.StandardErrorEncoding = Encoding.UTF8;
        using (var process = Process.Start(start))
        {
            var output = process.StandardOutput.ReadToEndAsync();
            var errors = process.StandardError.ReadToEndAsync();
            process.WaitForExit();
            Task.WaitAll(output, errors);
            if (process.ExitCode != 0)
                throw new InvalidOperationException(errors.Result + "\n" + output.Result);
        }
    }

    internal static void Install(IProgress<string> progress)
    {
        int build;
        if (!Environment.Is64BitOperatingSystem || !Int32.TryParse(Registry.GetValue(
            @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CurrentBuildNumber", null)
            as string, out build) || build < 22000)
            throw new InvalidOperationException("Windows 11 x64가 필요합니다.");
        progress.Report("설치 파일 확인 중...");
        var bytes = VerifyResources();
        progress.Report("Xbox Game Bar 확인 중...");
        PowerShell("if(-not (Get-AppxPackage -Name Microsoft.XboxGamingOverlay)){throw 'Microsoft Store에서 Xbox Game Bar를 먼저 설치해 주세요.'}");
        var root = SafePath(Path.GetTempPath(), "DestinyGameBar-Setup-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        try
        {
            Extract(bytes, root);
            progress.Report("설치 인증서 등록 중... Windows 권한 확인을 승인해 주세요.");
            if (!CertificateTrusted())
            {
                // Elevate only the embedded certificate import; install the widget as the original user.
                var helper = new ProcessStartInfo(Application.ExecutablePath, "--trust-certificate");
                helper.UseShellExecute = true;
                helper.Verb = "runas";
                using (var process = Process.Start(helper))
                {
                    process.WaitForExit();
                    if (process.ExitCode != 0 || !CertificateTrusted())
                        throw new InvalidOperationException("인증서 등록을 완료하지 못했습니다.");
                }
            }
            if (!RuntimeInstalled())
            {
                progress.Report("Microsoft WebView2 설치 중... 인터넷 연결이 필요합니다.");
                var runtime = Path.Combine(root, "MicrosoftEdgeWebview2Setup.exe");
                File.WriteAllBytes(runtime, Resource("DestinyGameBar.WebView2Setup"));
                var start = new ProcessStartInfo(runtime, "/silent /install");
                start.UseShellExecute = false;
                start.CreateNoWindow = true;
                using (var process = Process.Start(start))
                {
                    process.WaitForExit();
                    if (!RuntimeInstalled())
                        throw new InvalidOperationException("WebView2를 설치하지 못했습니다. 오류 코드: " + process.ExitCode);
                }
            }
            progress.Report("Destiny Game Bar와 필수 구성 요소 설치 중...");
            PowerShell("& '" + Path.Combine(root, "Install.ps1").Replace("'", "''") + "'");
        }
        finally
        {
            // root is a newly created GUID directory under the user's temporary directory.
            try { Directory.Delete(root, true); } catch (IOException) { } catch (UnauthorizedAccessException) { }
        }
    }
}

internal sealed class SetupWindow : Form
{
    private readonly Label status;
    private readonly Button install;
    private readonly ProgressBar progress;
    private bool busy;
    private bool complete;

    internal SetupWindow()
    {
        Text = "Destiny Game Bar 설치";
        Font = new Font("Segoe UI", 10);
        AutoScaleDimensions = new SizeF(96, 96);
        AutoScaleMode = AutoScaleMode.Dpi;
        ClientSize = new Size(540, 300);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        var title = new Label { Text = "Destiny Game Bar " + BuildInfo.Version, AutoSize = true,
            Font = new Font("Segoe UI", 18, FontStyle.Bold), Location = new Point(24, 22) };
        var description = new Label { Text = "설치를 누르면 위젯과 필수 구성 요소를 설치합니다.\n" +
            "자체 서명 인증서를 이 PC의 ‘신뢰할 수 있는 사용자’ 저장소에\n" +
            "등록합니다. Windows 권한 확인이 표시될 수 있습니다.\n\n" +
            "실행 중인 Destiny Game Bar 위젯은 먼저 닫아 주세요.",
            Location = new Point(24, 76), Size = new Size(492, 110) };
        status = new Label { Text = "설치 준비가 완료됐습니다.", Location = new Point(24, 194), Size = new Size(492, 28) };
        progress = new ProgressBar { Location = new Point(24, 230), Size = new Size(344, 24),
            Style = ProgressBarStyle.Marquee, Visible = false };
        install = new Button { Text = "설치", Location = new Point(388, 226), Size = new Size(128, 36) };
        install.Click += InstallClicked;
        Controls.AddRange(new Control[] { title, description, status, progress, install });
        AcceptButton = install;
        FormClosing += delegate(object sender, FormClosingEventArgs e) { if (busy) e.Cancel = true; };
    }

    private async void InstallClicked(object sender, EventArgs args)
    {
        if (complete) { Close(); return; }
        busy = true;
        install.Enabled = false;
        progress.Visible = true;
        try
        {
            var updates = new Progress<string>(delegate(string text) { status.Text = text; });
            await Task.Run(delegate { Setup.Install(updates); });
            status.Text = "설치 완료! Win+G → 위젯 메뉴 → Destiny Game Bar";
            install.Text = "닫기";
            complete = true;
        }
        catch (Win32Exception error)
        {
            status.Text = error.NativeErrorCode == 1223 ? "관리자 권한 요청을 취소했습니다." : "설치를 완료하지 못했습니다.";
            if (error.NativeErrorCode != 1223) MessageBox.Show(this, error.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        catch (Exception error)
        {
            status.Text = "설치를 완료하지 못했습니다. 오류를 확인해 주세요.";
            MessageBox.Show(this, error.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally { busy = false; install.Enabled = true; progress.Visible = false; }
    }
}
