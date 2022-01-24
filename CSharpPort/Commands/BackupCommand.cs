using Spectre.Console;
using Spectre.Console.Cli;
using System;
using System.Diagnostics.CodeAnalysis;
using System.Threading.Tasks;
using tools.Core;

namespace BackupGDrive.CLI.Commands
{
    internal sealed partial class BackupCommand : AsyncCommand<BackupCommand.Settings>
    {
        public override async Task<int> ExecuteAsync([NotNull] CommandContext context, [NotNull] Settings settings)
        {
            RCloneManager rclone = new(settings.RclonePath, settings.RcloneConfig);
            var remotes = await rclone.GetRemotes();
            foreach (var remote in remotes)
            {
                Console.WriteLine(remote);
            }
            return 0;
        }
    }
}