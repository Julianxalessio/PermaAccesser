using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using Renci.SshNet;

namespace PermaAccesser.Designer;

public class ScriptManager
{
    private const string ServerIp = "193.123.189.154";
    private const string ServerUser = "ubuntu";
    private const string ServerPassword = "BBZbl12345!";

    private const string LocalScriptFolder = @"C:\ProgramData\PermaAccesser\Scripts";
    private const string RemoteConfigPath = "/home/ubuntu/.ssh/scripts-config.json";

    private const string LocalSshUser = "dominik";
    private const string RemotePrivateKeyPath = "/home/ubuntu/.ssh/id_ed25519_client";

    private List<ScriptModel> _loadedScripts = new();
    private readonly List<string> _temporaryKeyFiles = new();

    public int LocalSshPort { get; set; } = 10100;

    private string LogFilePath => Path.Combine(LocalScriptFolder, "script_manager.log");

    public ScriptManager()
    {
        Directory.CreateDirectory(LocalScriptFolder);
    }

    public Task LoadScriptsFromServer()
    {
        try
        {
            using SftpClient sftp = new(ServerIp, ServerUser, ServerPassword);
            sftp.Connect();

            using MemoryStream ms = new();
            sftp.DownloadFile(RemoteConfigPath, ms);
            ms.Position = 0;

            using StreamReader sr = new(ms);
            string jsonContent = sr.ReadToEnd();

            _loadedScripts = JsonSerializer.Deserialize<List<ScriptModel>>(jsonContent) ?? new();
            sftp.Disconnect();
        }
        catch
        {
            _loadedScripts = new();
        }

        return Task.CompletedTask;
    }

    public async Task CreateScript(string scriptName, string scriptCode)
    {
        var script = new ScriptModel
        {
            Name = scriptName,
            CommandCode = scriptCode,
            Status = "Stopped"
        };

        string scriptPath = Path.Combine(LocalScriptFolder, $"{scriptName}.cmd");
        File.WriteAllText(scriptPath, scriptCode);

        if (IsClientReachable())
        {
            try
            {
                Log("INFO", $"Client reachable — preparing .windows folder and uploading script '{scriptName}'.");
                try
                {
                    ExecuteSshRemote("powershell -Command \"New-Item -ItemType Directory -Force $env:USERPROFILE\\.windows\"");
                }
                catch
                {
                }

                bool uploaded = ExecuteScpUpload(scriptPath, $"C:\\Users\\{LocalSshUser}\\.windows\\{scriptName}.cmd");
                if (!uploaded) Log("WARN", $"Upload of '{scriptName}' returned non-zero exit code.");
                else
                {
                    try
                    {
                        Log("INFO", $"Marking remote script '{scriptName}' hidden (if Windows client).");
                        ExecuteSshRemote($"powershell -Command \"attrib +h $env:USERPROFILE\\.windows\\{scriptName}.cmd\"");
                    }
                    catch (Exception ex)
                    {
                        Log("WARN", $"Failed to mark remote script hidden: {ex.Message}");
                    }
                }
            }
            catch (Exception ex)
            {
                Log("ERROR", $"Failed upload of '{scriptName}' to client: {ex.Message}");
            }
        }
        else
        {
            Log("WARN", $"Client offline — skipping upload for '{scriptName}'.");
        }

        _loadedScripts.Add(script);
        await SyncScriptsToServer();
    }

    public async Task DeleteScript(string scriptName)
    {
        string scriptPath = Path.Combine(LocalScriptFolder, $"{scriptName}.cmd");
        if (File.Exists(scriptPath))
        {
            File.Delete(scriptPath);
        }

        try
        {
            string remoteRemove = $"powershell -Command \"Remove-Item -Path \"$env:USERPROFILE\\.windows\\{scriptName}.cmd\" -ErrorAction SilentlyContinue\" || rm -f ~/.windows/{scriptName}.cmd";
            ExecuteSshRemote(remoteRemove);
        }
        catch
        {
        }

        _loadedScripts.RemoveAll(s => s.Name == scriptName);
        await SyncScriptsToServer();
    }

    public void StartScript(string scriptName)
    {
        bool ok = StartRemoteScript(scriptName);
        if (ok)
        {
            UpdateScriptStatus(scriptName, "Running");
        }
        else
        {
            Log("WARN", $"StartScript: client offline or start command failed for '{scriptName}'. Status unchanged.");
        }
    }

    public void StopScript(string scriptName)
    {
        bool ok = StopRemoteScript(scriptName);
        if (ok)
        {
            UpdateScriptStatus(scriptName, "Stopped");
        }
        else
        {
            Log("WARN", $"StopScript: client offline or stop command failed for '{scriptName}'. Status unchanged.");
        }
    }

    public List<ScriptModel> GetScripts() => _loadedScripts;

    private bool ExecuteScpUpload(string localPath, string remoteRelativePath)
    {
        string tempKeyPath = string.Empty;
        try
        {
            if (!IsClientReachable())
            {
                Log("WARN", $"ExecuteScpUpload: client offline — skipping upload of '{localPath}'.");
                return false;
            }

            tempKeyPath = DownloadPrivateKeyToTemp();

            string args = $"-i \"{tempKeyPath}\" -P {LocalSshPort} \"{localPath}\" {LocalSshUser}@localhost:\"{remoteRelativePath}\"";

            Process process = new()
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "scp",
                    Arguments = args,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                }
            };

            process.Start();
            process.WaitForExit();
            bool ok = process.ExitCode == 0;
            if (!ok) Log("ERROR", $"scp upload exited with code {process.ExitCode} for '{localPath}'.");
            return ok;
        }
        catch (Exception ex)
        {
            Log("ERROR", $"ExecuteScpUpload exception: {ex.Message}");
            return false;
        }
        finally
        {
            if (!string.IsNullOrEmpty(tempKeyPath)) CleanupTemporaryKeyFile(tempKeyPath);
        }
    }

    private bool StartRemoteScript(string scriptName)
    {
        if (!IsClientReachable())
        {
            Log("WARN", $"StartRemoteScript: client offline — skipping start for '{scriptName}'.");
            return false;
        }

        string remoteCmd = $"powershell -WindowStyle Hidden -Command \"Start-Process -FilePath '$env:USERPROFILE\\.windows\\{scriptName}.cmd' -WindowStyle Hidden\"";
        bool ok = ExecuteSshRemote(remoteCmd);
        if (ok) Log("INFO", $"Started remote script '{scriptName}'.");
        else Log("ERROR", $"Failed to start remote script '{scriptName}'.");
        return ok;
    }

    private bool StopRemoteScript(string scriptName)
    {
        if (!IsClientReachable())
        {
            Log("WARN", $"StopRemoteScript: client offline — skipping stop for '{scriptName}'.");
            return false;
        }

        string remoteCmd = $"powershell -Command \"Get-CimInstance Win32_Process | Where-Object {{ '$_.CommandLine -like \"*{scriptName}.cmd*\"' }} | ForEach-Object {{ Stop-Process -Id $_.ProcessId -Force }}\"";
        bool ok = ExecuteSshRemote(remoteCmd);
        if (ok) Log("INFO", $"Stopped remote script '{scriptName}'.");
        else Log("ERROR", $"Failed to stop remote script '{scriptName}'.");
        return ok;
    }

    private void UpdateScriptStatus(string scriptName, string status)
    {
        var script = _loadedScripts.FirstOrDefault(s => s.Name == scriptName);
        if (script != null)
        {
            script.Status = status;
            script.LastModified = DateTime.Now;
        }
    }

    private Task SyncScriptsToServer()
    {
        try
        {
            string jsonContent = JsonSerializer.Serialize(_loadedScripts, new JsonSerializerOptions { WriteIndented = true });

            using SftpClient sftp = new(ServerIp, ServerUser, ServerPassword);
            sftp.Connect();

            using MemoryStream ms = new(Encoding.UTF8.GetBytes(jsonContent));
            sftp.UploadFile(ms, RemoteConfigPath);
            sftp.Disconnect();
        }
        catch
        {
        }

        return Task.CompletedTask;
    }

    private bool IsClientReachable(int timeoutMs = 5000)
    {
        return new TcpClient().ConnectAsync("localhost", LocalSshPort).Wait(timeoutMs);
    }

    private bool ExecuteSshRemote(string command)
    {
        string tempKeyPath = string.Empty;
        try
        {
            tempKeyPath = DownloadPrivateKeyToTemp();
            string args = $"-i \"{tempKeyPath}\" -p {LocalSshPort} {LocalSshUser}@localhost \"{command}\"";

            Process process = new()
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "ssh",
                    Arguments = args,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                }
            };

            process.Start();
            process.WaitForExit();
            return process.ExitCode == 0;
        }
        catch (Exception ex)
        {
            Log("ERROR", $"ExecuteSshRemote exception: {ex.Message}");
            return false;
        }
        finally
        {
            if (!string.IsNullOrEmpty(tempKeyPath)) CleanupTemporaryKeyFile(tempKeyPath);
        }
    }

    private void Log(string level, string message)
    {
        try
        {
            string line = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {level}: {message}";
            File.AppendAllLines(LogFilePath, new[] { line }, Encoding.UTF8);
            Debug.WriteLine(line);
        }
        catch
        {
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

        lock (_temporaryKeyFiles)
        {
            _temporaryKeyFiles.Add(tempKeyPath);
        }

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
}
