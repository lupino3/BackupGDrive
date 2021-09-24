using System;
using System.IO;
using System.Diagnostics;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Spectre.Console;
using Spectre.Console.Cli;
using System.ComponentModel;
using System.Diagnostics.CodeAnalysis;

namespace BackupGDrive
{
    public class CLIBackup
    {
        public static int Main(string[] args)
        {
            var app = new CommandApp<BackupGDrive.BackupCommand>();
            return app.Run(args);
        }
    }
    internal sealed class BackupCommand : Command<BackupCommand.Settings>
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
                return configs.ContainsKey(Backup) ?
                    ValidationResult.Success() :
                    ValidationResult.Error($"Invalid backup type: {Backup}. Valid values: {String.Join(", ", configs.Keys)}");
            }
        }
        public override int Execute([NotNull] CommandContext context, [NotNull] Settings settings)
        {
            AnsiConsole.MarkupLine(settings.ToString());
            return 0;
        }
    }
}