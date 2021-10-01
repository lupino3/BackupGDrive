using System;
using System.IO;
using System.Diagnostics;
using System.Collections.Generic;
using System.Linq;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;

namespace BackupGDrive.CLI.Commands
{
    internal sealed partial class BackupCommand
    {
        public sealed class Settings : CommandSettings
        {
            [CommandArgument(0, "<backup>")]
            public string Backup { get; init; }

            [CommandOption("-d|--debug")]
            [DefaultValue(false)]
            public bool Debug { get; init; }

            [CommandOption("-s|--should-download-rclone")]
            [DefaultValue(false)]
            public bool ShouldDownloadRclone { get; init; }

            private string? rcloneConfig;
            [CommandOption("-c|--rclone-config")]
            public string RcloneConfig
            {
                get => rcloneConfig ?? Path.Join(Environment.GetEnvironmentVariable("APPDATA"), "rclone", "rclone.conf");
                init { rcloneConfig = value; }
            }

            private string? rclonePath;
            [CommandOption("-p|--rclone-path")]
            public string RclonePath
            {
                get => rclonePath ?? Path.Join(Path.GetDirectoryName(Process.GetCurrentProcess().MainModule!.FileName), "rclone.exe");
                init { rclonePath = value; }
            }

            // TODO: move to a config file.
            public record BackupConfig(string Action, string Source, string Destination);
            public readonly IReadOnlyDictionary<string, BackupConfig> configs = new Dictionary<string, BackupConfig> {
                    {"syncdocs",        new BackupConfig("sync", "GDrive:Important Documents",  "Azure:importantdocuments")},
                    {"localcopydocs",   new BackupConfig("sync", "GDrive:Important Documents",  "d:/Important Documents")},
                    {"uploadphotos",    new BackupConfig("copy", "d:/Photos",                   "GDrive:Photos")},
                    {"syncphotos",      new BackupConfig("sync", "GDrive:Photos",               "Azure:photos")}
            };

            public override ValidationResult Validate()
            {
                var errors = new List<string>();
                if (!configs.ContainsKey(Backup))
                {
                    errors.Add($"Invalid backup type: {Backup}. Valid values: {String.Join(", ", configs.Keys)}");
                }

                if (!File.Exists(RcloneConfig))
                {
                    errors.Add($"The rclone config file ({RcloneConfig}) does not exist.");
                }

                if (!ShouldDownloadRclone && !File.Exists(RclonePath))
                {
                    errors.Add($"The rclone executable ({RclonePath}) could not be found, and the ShouldDownloadRclone option is not set.");
                }

                if (errors.Any())
                {
                    return ValidationResult.Error(String.Join('\n', errors));
                }

                return ValidationResult.Success();
            }
        }
    }
}