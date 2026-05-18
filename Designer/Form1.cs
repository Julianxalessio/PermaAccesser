using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Renci.SshNet;
using Renci.SshNet.Common;
using System.Windows.Forms;

namespace PermaAccesser.Designer
{
    public partial class Form1 : Form
    {
        private const string ServerIp = "193.123.189.154";
        private const string ServerUser = "ubuntu";
        private const string ServerPassword = "BBZbl12345!";
        private const string LocalSshUser = "dominik";
        private const string RemotePrivateKeyPath = "/home/ubuntu/.ssh/id_ed25519_client";
        private const int RemoteRdpPort = 3389;

        private SshClient _sshClient;
        private ForwardedPortLocal _forwardedPort;
        private SshClient _sshClientRdp;
        private ForwardedPortLocal _rdpForwardedPort;
        private bool _isConnected;
        private bool _isConnectedRDP;
        private readonly List<string> _temporaryKeyFiles = new();
        private ScriptManager _scriptManager;
        private int LocalSshPort = 10100;
        private int LocalRdpPort = 3389;

        public Form1()
        {
            InitializeComponent();
            _scriptManager = new ScriptManager();
            UpdateConnectionUi();
            SetError(string.Empty);
            InitializeScriptsGrid();
            _ = LoadScriptsAsync();
        }

        private void Button1_Click(object sender, System.EventArgs e)
        {
            if (_isConnected)
            {
                DisconnectTunnel("Disconnected.");
                return;
            }

            ConnectTunnel();
        }

        private void Button3_Click(object sender, System.EventArgs e)
        {
            if (_isConnectedRDP)
            {
                DisconnectTunnelRDP("Disconnected.");
                return;
            }    
            ConnectTunnelRDP();
        }

        private void Button4_Click(object sender, System.EventArgs e)
        {
            if (!_isConnected)
            {
                SetError("Please connect the SSH tunnel first using the Connect button.");
                return;
            }

            try
            {
                SetError(string.Empty);
                string tempKeyPath = DownloadPrivateKeyToTemp();
                _temporaryKeyFiles.Add(tempKeyPath);

                string sshArgs = $"/k ssh -i \"{tempKeyPath}\" -p {LocalSshPort} {LocalSshUser}@localhost";

                Process process = new()
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "cmd.exe",
                        Arguments = sshArgs,
                        WorkingDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                        UseShellExecute = true
                    },
                    EnableRaisingEvents = true
                };

                process.Exited += (_, _) => CleanupTemporaryKeyFile(tempKeyPath);
                process.Start();
            }
            catch (Exception ex)
            {
                SetError($"Could not start SSH command: {ex.Message}");
            }
        }

        private void Button6_Click(object sender, System.EventArgs e)
        {
            if (!_isConnectedRDP)
            {
                SetError("Please connect the RDP tunnel first using the RDP Connect button.");
                return;
            }

            try
            {
                SetError(string.Empty);
                string rdpPath = Path.Combine(Path.GetTempPath(), "connection.rdp");
                string[] rdpLines = {
                    "full address:s:localhost:" + LocalRdpPort,
                    "username:s:Dominik",
                    "prompt for credentials:i:1" 
                };
                Process.Start(new ProcessStartInfo
                {
                    FileName = "mstsc.exe",
                    Arguments = rdpPath,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                SetError($"Could not start RDP: {ex.Message}");
            }
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            StopTunnel();
            StopTunnelRdp();
            CleanupAllTemporaryKeyFiles();
        }

        private void ConnectTunnel()
        {
            if (!int.TryParse(textBox2.Text.Trim(), out int localPort) || localPort < 1 || localPort > 65535)
            {
                SetError("Please enter a valid local port (1-65535).\r\nExample: Jonas = 10101, Lean = 10102, Diego = 10103, Julian = 10104, Others = 10105");
                return;
            }

            SetError(string.Empty);
            StopTunnel();

            LocalSshPort = localPort;
            if (_scriptManager != null)
            {
                _scriptManager.LocalSshPort = LocalSshPort;
            }

            try
            {
                _sshClient = new SshClient(ServerIp, ServerUser, ServerPassword);
                _sshClient.Connect();

                _forwardedPort = new ForwardedPortLocal("127.0.0.1", (uint)localPort, "localhost", 10100);
                _forwardedPort.Exception += ForwardedPort_Exception;

                _sshClient.AddForwardedPort(_forwardedPort);
                _forwardedPort.Start();

                _isConnected = true;
                UpdateConnectionUi();
            }
            catch (SshAuthenticationException)
            {
                StopTunnel();
                SetError("Authentication failed. Check fixed credentials in Form1.cs.");
            }
            catch (Exception ex)
            {
                StopTunnel();
                SetError($"Connection error: {ex.Message}");
            }
        }

        private void DisconnectTunnel(string reason)
        {
            StopTunnel();
            _isConnected = false;
            UpdateConnectionUi();
            SetError(string.Empty);
        }
        private void DisconnectTunnelRDP(string reason)
        {
            StopTunnelRdp();
            _isConnectedRDP = false;
            UpdateConnectionUi();
            SetError(string.Empty);
        }

        private void ForwardedPort_Exception(object sender, ExceptionEventArgs e)
        {
            if (InvokeRequired)
            {
                BeginInvoke(() => HandleTunnelError(e.Exception.Message));
                return;
            }

            HandleTunnelError(e.Exception.Message);
        }

        private void ForwardedPortRdp_Exception(object sender, ExceptionEventArgs e)
        {
            if (InvokeRequired)
            {
                BeginInvoke(() => HandleTunnelErrorRdp(e.Exception.Message));
                return;
            }

            HandleTunnelErrorRdp(e.Exception.Message);
        }

        private void StopTunnel()
        {
            if (_forwardedPort != null)
            {
                _forwardedPort.Exception -= ForwardedPort_Exception;

                if (_forwardedPort.IsStarted)
                {
                    _forwardedPort.Stop();
                }

                _forwardedPort.Dispose();
                _forwardedPort = null;
            }

            if (_sshClient != null)
            {
                if (_sshClient.IsConnected)
                {
                    _sshClient.Disconnect();
                }

                _sshClient.Dispose();
                _sshClient = null;
            }

            _isConnected = false;
            UpdateConnectionUi();
        }

        private void StopTunnelRdp()
        {
            if (_rdpForwardedPort != null)
            {
                _rdpForwardedPort.Exception -= ForwardedPortRdp_Exception;

                if (_rdpForwardedPort.IsStarted)
                {
                    _rdpForwardedPort.Stop();
                }

                _rdpForwardedPort.Dispose();
                _rdpForwardedPort = null;
            }

            if (_sshClientRdp != null)
            {
                if (_sshClientRdp.IsConnected)
                {
                    _sshClientRdp.Disconnect();
                }

                _sshClientRdp.Dispose();
                _sshClientRdp = null;
            }

            _isConnectedRDP = false;
            UpdateConnectionUi();
        }

        private void HandleTunnelError(string message)
        {
            StopTunnel();
            SetError($"Tunnel error: {message}");
        }

        private void HandleTunnelErrorRdp(string message)
        {
            StopTunnelRdp();
            SetError($"RDP tunnel error: {message}");
        }

        private void UpdateConnectionUi()
        {
            button1.Text = _isConnected ? "Disconnect" : "Connect";
            Status.Text = _isConnected ? "Online" : "Offline";
            Status.BackColor = _isConnected ? System.Drawing.Color.LightGreen : System.Drawing.Color.LightCoral;

            button3.Text = _isConnectedRDP ? "Disconnect" : "Connect";
            button2.Text = _isConnectedRDP ? "Online" : "Offline";
            button2.BackColor = _isConnectedRDP ? System.Drawing.Color.LightGreen : System.Drawing.Color.LightCoral;

            SetActionControlsEnabled(_isConnected);
            SetRdpControlsEnabled(_isConnectedRDP);
        }

        private void SetActionControlsEnabled(bool enabled)
        {
            button4.Enabled = enabled;
            btnCreateFile.Enabled = enabled;
            scriptsGridView.Enabled = enabled;
        }

        private void SetRdpControlsEnabled(bool enabled)
        {
            button6.Enabled = enabled;
        }

        private void SetError(string message)
        {
            textBox3.Text = message;
        }

        private void ConnectTunnelRDP()
        {
            if (!int.TryParse(textBox1.Text.Trim(), out int localPort) || localPort < 1 || localPort > 65535)
            {
                SetError("Please enter a valid RDP local port (1-65535). Example: 3390");
                return;
            }

            SetError(string.Empty);
            StopTunnelRdp();

            LocalRdpPort = localPort;

            try
            {
                _sshClientRdp = new SshClient(ServerIp, ServerUser, ServerPassword);
                _sshClientRdp.Connect();

                _rdpForwardedPort = new ForwardedPortLocal("127.0.0.1", (uint)localPort, "localhost", RemoteRdpPort);
                _rdpForwardedPort.Exception += ForwardedPortRdp_Exception;

                _sshClientRdp.AddForwardedPort(_rdpForwardedPort);
                _rdpForwardedPort.Start();

                _isConnectedRDP = true;
                UpdateConnectionUi();
            }
            catch (SshAuthenticationException)
            {
                StopTunnelRdp();
                SetError("RDP authentication failed. Check fixed credentials in Form1.cs.");
            }
            catch (Exception ex)
            {
                StopTunnelRdp();
                SetError($"RDP connection error: {ex.Message}");
            }
        }

        private string DownloadPrivateKeyToTemp()
        {
            string tempKeyPath = Path.Combine(Path.GetTempPath(), $"ssh_key_{Guid.NewGuid():N}");

            using SftpClient sftpClient = new(ServerIp, ServerUser, ServerPassword);
            sftpClient.Connect();

            using FileStream keyFileStream = File.Create(tempKeyPath);
            sftpClient.DownloadFile(RemotePrivateKeyPath, keyFileStream);

            keyFileStream.Close();
            sftpClient.Disconnect();

            return tempKeyPath;
        }

        private void CleanupTemporaryKeyFile(string keyPath)
        {
            try
            {
                if (File.Exists(keyPath))
                {
                    File.Delete(keyPath);
                }
            }
            catch
            {
            }

            lock (_temporaryKeyFiles)
            {
                _temporaryKeyFiles.Remove(keyPath);
            }
        }

        private void CleanupAllTemporaryKeyFiles()
        {
            lock (_temporaryKeyFiles)
            {
                foreach (string keyPath in _temporaryKeyFiles.ToList())
                {
                    CleanupTemporaryKeyFile(keyPath);
                }
            }
        }

        private void InitializeScriptsGrid()
        {
        }

        private async Task LoadScriptsAsync()
        {
            if (_scriptManager == null) return;

            try
            {
                await _scriptManager.LoadScriptsFromServer();
                RefreshScriptsGrid();
            }
            catch (Exception ex)
            {
                SetError($"Could not load scripts: {ex.Message}");
            }
        }

        private void RefreshScriptsGrid()
        {
            if (_scriptManager == null || scriptsGridView == null) return;

            var scripts = _scriptManager.GetScripts();
            scriptsGridView.Rows.Clear();

            foreach (var script in scripts)
            {
                if (string.IsNullOrWhiteSpace(script.Name)) continue;

                int rowIndex = scriptsGridView.Rows.Add();
                DataGridViewRow row = scriptsGridView.Rows[rowIndex];

                row.Cells["colName"].Value = script.Name;
                row.Cells["colStatus"].Value = script.Status;
                row.Cells["colAction"].Value = "Start/Stop";
                row.Cells["colDelete"].Value = "Delete";
            }
        }

        private void ScriptsGridView_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex < 0 || _scriptManager == null) return;

            string scriptName = scriptsGridView.Rows[e.RowIndex].Cells["colName"].Value?.ToString() ?? "";

            DataGridViewColumn actionColumn = scriptsGridView.Columns["colAction"];
            DataGridViewColumn deleteColumn = scriptsGridView.Columns["colDelete"];

            if (actionColumn != null && e.ColumnIndex == actionColumn.Index)
            {
                _ = ToggleScriptAsync(scriptName);
            }
            else if (deleteColumn != null && e.ColumnIndex == deleteColumn.Index)
            {
                if (MessageBox.Show($"Delete script '{scriptName}'?", "Confirm", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    _ = DeleteScriptAsync(scriptName);
                }
            }
        }

        private Task ToggleScriptAsync(string scriptName)
        {
            if (_scriptManager == null) return Task.CompletedTask;

            try
            {
                var script = _scriptManager.GetScripts().FirstOrDefault(s => s.Name == scriptName);
                if (script == null) return Task.CompletedTask;

                if (script.Status == "Running")
                {
                    _scriptManager.StopScript(scriptName);
                    SetError($"Script '{scriptName}' stopped.");
                }
                else
                {
                    _scriptManager.StartScript(scriptName);
                    SetError($"Script '{scriptName}' started.");
                }

                RefreshScriptsGrid();
            }
            catch (Exception ex)
            {
                SetError($"Error toggling script: {ex.Message}");
            }

            return Task.CompletedTask;
        }

        private async Task DeleteScriptAsync(string scriptName)
        {
            if (_scriptManager == null) return;

            try
            {
                await _scriptManager.DeleteScript(scriptName);
                RefreshScriptsGrid();
                SetError($"Script '{scriptName}' deleted.");
            }
            catch (Exception ex)
            {
                SetError($"Error deleting script: {ex.Message}");
            }
        }

        private void btnCreateFile_Click(object sender, EventArgs e)
        {
            using CreateScriptDialog dialog = new();
            if (dialog.ShowDialog(this) == DialogResult.OK)
            {
                _ = CreateScriptAsync(dialog.ScriptName, dialog.ScriptCode);
            }
        }

        private async Task CreateScriptAsync(string scriptName, string scriptCode)
        {
            if (_scriptManager == null) return;

            try
            {
                await _scriptManager.CreateScript(scriptName, scriptCode);
                RefreshScriptsGrid();
                SetError($"Script '{scriptName}' created successfully.");
            }
            catch (Exception ex)
            {
                SetError($"Error creating script: {ex.Message}");
            }
        }
    }

    static class Program
    {
        /// <summary>
        /// Der Haupteinstiegspunkt für die Anwendung.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Form1());
        }
    }
}
