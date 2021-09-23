using System;
using System.IO;
using System.Diagnostics;
using CommandLine;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;


// TODO: Usage, help for options, error messages for backups-to-run.
class Options {
    // Types for configuration, to simplify validation.
    // TODO: move to a config file. An enum here is not the most flexible thing, but I wanted
    // to play with Flag enums and their support in CommandLineParser.
    [Flags]
    public enum Configuration {
        SyncDocs        = 1,
        LocalCopyDocs   = 2,
        UploadPhotos    = 4,
        SyncPhotos      = 8
    }
    public record BackupConfig(string Action, string Source, string Destination);
    public readonly ReadOnlyDictionary<Configuration, BackupConfig> configs = new(
        new Dictionary<Configuration, BackupConfig>{
            {Configuration.SyncDocs,        new BackupConfig("sync", "GDrive:Important Documents",  "Azure:importantdocuments")},
            {Configuration.LocalCopyDocs,   new BackupConfig("sync", "GDrive:Important Documents",  "d:/Important Documents")},
            {Configuration.UploadPhotos,    new BackupConfig("copy", "d:/Photos",                   "GDrive:Photos")},
            {Configuration.SyncPhotos,      new BackupConfig("sync", "GDrive:Photos",               "Azure:photos")}
    });

    public IEnumerable<BackupConfig> GetBackupConfigs()
    {
        foreach (Configuration val in Enum.GetValues(typeof(Configuration))) { 
            if (BackupsToRun.HasFlag(val))
            {
                yield return configs[val];
            }
        }
    }

    [Option('d', "debug")]
    public bool Debug { get; set; }

    [Option("should-download-rclone")]
    public bool ShouldDownloadRclone { get; set; }

    private string? rcloneConfig;
    [Option("rclone-config")]
    public string RcloneConfig
    {
        get => rcloneConfig ?? Path.Join(Environment.GetEnvironmentVariable("APPDATA"), "rclone", "rclone.conf");
        set { rcloneConfig = value; }
    }

    private string? rclonePath;
    [Option("rclone-path")]
    public string RclonePath
    {
        get => rclonePath ?? Path.Join(Path.GetDirectoryName(Process.GetCurrentProcess().MainModule!.FileName), "rclone.exe");
        set { rclonePath = value; }
    }

    [Option("backups-to-run", Required = true)]
    public Configuration BackupsToRun { get; set; }
}

public class ManualBackup {

    static void Main(string[] args) {
        Parser.Default.ParseArguments<Options>(args)
            .WithParsed(o => { InnerMain(o); });
    } 
    
    private static void InnerMain(Options options) {
        if (options == null) { throw new ArgumentNullException(nameof(options)); }

        if (options.Debug)
        {
            Console.WriteLine("Debug mode!");
        }
        Console.WriteLine($"Hello World! {options.RclonePath}");
        Console.WriteLine($"Hello World! {options.RcloneConfig}");
        Console.WriteLine($"{options.BackupsToRun}");
        foreach (var config in options.GetBackupConfigs())
        {
            Console.WriteLine(config);
        }
    }
}