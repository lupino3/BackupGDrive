using System.Collections.ObjectModel;
using Spectre.Console.Cli;
using BackupGDrive.CLI.Commands;

var app = new CommandApp<BackupCommand>();
return app.Run(args);