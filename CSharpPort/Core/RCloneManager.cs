using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace tools.Core
{
    internal record RCloneExecutionResult
    {
        public string StdOut { get; set; } = "";
        public string StdErr { get; set; } = "";
        public int ErrorCode { get; set; }
    }

    internal class RCloneManager
    {
        private readonly string rCloneBinaryPath;
        private readonly string rCloneConfigPath;

        public RCloneManager(string RCloneBinaryPath, string RCloneConfigPath)
        {
            if (string.IsNullOrEmpty(RCloneBinaryPath))
            {
                throw new ArgumentException($"'{nameof(RCloneBinaryPath)}' cannot be null or empty.", nameof(RCloneBinaryPath));
            }

            if (string.IsNullOrEmpty(RCloneConfigPath))
            {
                throw new ArgumentException($"'{nameof(RCloneConfigPath)}' cannot be null or empty.", nameof(RCloneConfigPath));
            }

            if (!File.Exists(RCloneConfigPath))
            {
                throw new ArgumentException($"'{nameof(RCloneConfigPath)}' must be a path to an existing file.");
            }

            if (!File.Exists(RCloneBinaryPath))
            {
                throw new ArgumentException($"'{nameof(RCloneBinaryPath)}' must be a path to an existing file.");
            }

            rCloneBinaryPath = RCloneBinaryPath;
            rCloneConfigPath = RCloneConfigPath;
        }

        public string RCloneConfigPath { get; }

        public async Task<IEnumerable<String>> GetRemotes()
        {
            RCloneExecutionResult res = await RunRclone("listremotes");
            if (res.ErrorCode != 0)
            {
                return res.StdErr.ToString().Split();
            }
            return res.StdOut.ToString().Split();
        }

        private async Task<RCloneExecutionResult> RunRclone(params string[] args)
        {
            RCloneExecutionResult res = new();
            using (var process = new Process()
            {
                StartInfo = {
                    FileName = rCloneBinaryPath,
                    Arguments = $"--config={rCloneConfigPath} {string.Join(" ", args)}",
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                }
            })
            {
                process.OutputDataReceived += (sender, dataReceivedArgs) => res.StdOut += dataReceivedArgs.Data ?? "";
                process.ErrorDataReceived += (sender, dataReceivedArgs) => res.StdErr += dataReceivedArgs.Data ?? "";
                process.Exited += (sender, args) =>
                {
                    res.ErrorCode = process.ExitCode;
                    if (process.ExitCode != 0)
                    {
                        Trace.TraceError($"rclone process exited with error code {res.ErrorCode}");
                    }
                };

                Trace.TraceInformation("About to run: {0} {1}.", process.StartInfo.FileName, process.StartInfo.Arguments);

                process.Start();
                await process.WaitForExitAsync();
            }
            return res;
        }
    }
}
