# Manor Lords Save Game Transfer Tool

This repository contains a PowerShell migration script, `migrate-saves-xboxgamepass-to-steam.ps1`, designed to transfer Manor Lords save games from XBOX GamePass PC to Steam.

## Script Parameters

The script accepts the following parameters:

| Parameter           | Optional | Description |
| ------------------- | -------- | ----------- |
| `-help`             | Yes      | Show this help message. |
| `-gameInstallNumber`| Yes      | Specify the unique identifier for the game installation. This number is used to locate the correct game files for transfer. |
| `-baseDir`          | Yes      | Specify the base directory where the game files are currently stored. The default path is `C:\Users\[Your Username]\AppData\Local\Packages\ManorLords\LocalCache\Local\ManorLords\Saves`. |
| `-destinationDir`   | Yes      | Specify the destination directory where the game files should be transferred to. The default path is `C:\Users\[Your Username]\AppData\Local\ManorLords\Saves`. |
| `-deleteExisting`   | Yes      | Specify whether to delete existing files in the destination directory before the transfer. Accepts `true` or `false`. Default is `false`. If `true`, any existing files in the destination directory will be deleted before the transfer. If `false`, the transfer will fail if there are existing files in the destination directory. |
| `-timeDiffMinutes`  | Yes      | Specify the time difference in minutes to consider for file synchronization. Only files that have been modified within this time difference will be transferred. Default is `15`, meaning all files will be transferred regardless of when they were last modified. |

## How It Works
This script serves two main purposes: 

1. It associates Xbox save files with the corresponding save game thumbnails based on the nearest modification times, and then transfers the matched files to a specified destination directory. 

2. It converts the Xbox save file style to the Steam save file style, making the save files compatible with both platforms.

The Xbox save files are located in `C:\Users\niels\AppData\Local\Packages\HoodedHorse.ManorLords_znaey1dw2bdpr`. The save game thumbnails and Steam's save data are stored in `C:\Users\niels\AppData\Local\ManorLords\`.

If the `-deleteExisting` flag is enabled, the script will overwrite any existing files in the destination directory, ensuring that the most recent save files are always used.

## Usage

To use the script, open a PowerShell terminal and navigate to the directory containing the script. Then, run the script with the desired parameters. For example:

```powershell
.\migrate-saves-xboxgamepass-to-steam.ps1 -gameInstallNumber "000900000AE4F5E0_0000000000000000000000006677A913" -deleteExisting $True
```

This command will run the script, using the game installation number `000900000AE4F5E0_0000000000000000000000006677A913` and deleting any existing files in the destination directory.