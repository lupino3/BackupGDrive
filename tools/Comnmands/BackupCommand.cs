using Spectre.Console;
using Spectre.Console.Cli;
using System.Diagnostics.CodeAnalysis;

namespace BackupGDrive.CLI.Commands
{
    internal sealed partial class BackupCommand : Command<BackupCommand.Settings>
    {
        public override int Execute([NotNull] CommandContext context, [NotNull] Settings settings)
        {
            AnsiConsole.MarkupLine(settings.ToString());
            return 0;
        }
    }
}