# PowerShell script to transfer Manor Lords save files from Xbox Game Pass to Steam

param (
    [Parameter(Mandatory=$false)]
    [string]$gameInstallNumber,

    [Parameter(Mandatory=$false)]
    [string]$baseDir = "C:\Users\$env:USERNAME\AppData\Local\Packages\HoodedHorse.ManorLords_znaey1dw2bdpr\SystemAppData\wgs",

    [Parameter(Mandatory=$false)]
    [string]$destinationDir = "C:\Users\$env:USERNAME\AppData\Local\ManorLords\Saved\SaveGames",

    [Parameter(Mandatory=$false)]
    [bool]$deleteExisting = $false,

    [Parameter(Mandatory=$false)]
    [int]$timeDiffMinutes = 15
)

Write-Host "Starting the migration script..."

if (-not $gameInstallNumber) {
    # Attempt to auto-detect the folder
    $folders = Get-ChildItem -Path $baseDir -Directory | Where-Object { $_.Name -match '000900000[0-9A-F]+' }
    if ($folders.Count -eq 1) {
        $gameInstallNumber = $folders.Name
        Write-Host "The following gameInstallNumber is found: $gameInstallNumber."
    } else {
        Write-Host "Multiple or no game folders found. Please specify the gameInstallNumber."
        exit
    }
}

# Verify and set the full source directory
$sourceDir = Join-Path -Path $baseDir -ChildPath $gameInstallNumber

# Ensure the base directory exists
if (-not (Test-Path -Path $sourceDir)) {
    Write-Host "The source directory does not exist. Please check the baseDir and gameInstallNumber."
    exit
}

# Ensure the destination directory exists
if (-not (Test-Path -Path $destinationDir)) {
    Write-Host "The destination directory does not exist. Please check the destinationDir."
    exit
}

# Mapping the Xbox saves to the correct Steam thumbnails by nearest modified time
$steamSaves = Get-ChildItem -Path $destinationDir -Filter "*.png" | Where-Object { $_.Name -match "^saveGame_\d+\.png$|^autosave\.png$" } | Sort-Object LastWriteTime
$xboxSaveDirs = Get-ChildItem -Path $sourceDir -Directory

# Loop over each Steam save file
foreach ($steamSave in $steamSaves) {
    Write-Host "Processing Steam save file: $($steamSave.Name)"
    
    # Determine the save file name. If the Steam save file name contains "autosave", set the save file name to "autosave". 
    # Otherwise, prefix the save game number extracted from the Steam save file name with "saveGame_".
    $saveFileName = if ($steamSave.Name -like "*autosave*") { 
        "autosave" 
    } else { 
        "saveGame_" + [regex]::Match($steamSave.Name, 'saveGame_(\d+)').Groups[1].Value 
    }
    
    # Set an acceptable time range for matching Xbox saves
    $timeDiff = [TimeSpan]::FromMinutes($timeDiffMinutes)
    
    # Initialize the selected folders to null
    $selectedFolders = $null

    # Loop over each Xbox save directory
    foreach ($xboxDir in $xboxSaveDirs) {
        # Calculate the absolute difference in minutes between the Xbox save and the Steam save
        $currentDiff = [Math]::Abs(($xboxDir.LastWriteTime - [DateTime]::ParseExact($steamSave.LastWriteTime, "MM/dd/yyyy HH:mm:ss", $null)).TotalMinutes)
        
        # If the current difference is within the acceptable time range, select the Xbox save directory
        if ($currentDiff -lt $timeDiff.TotalMinutes -and (Get-ChildItem -Path $xboxDir.FullName | Measure-Object).Count -gt 0) {
            # Add the current directory to the selected folders
            $selectedFolders += @($xboxDir)
            
            # If more than two folders are selected, keep only the two with the closest timestamps
            if ($selectedFolders.Count -gt 2) {
                $selectedFolders = $selectedFolders | Sort-Object { [Math]::Abs(($_.LastWriteTime - [DateTime]::ParseExact($steamSave.LastWriteTime, "MM/dd/yyyy HH:mm:ss", $null)).TotalMinutes) } | Select-Object -First 2
            }
        }
    }

    # foreach ($folder in $selectedFolders) {
    #     Write-Host "$folder"
    # }

    # continue

    # If two Xbox save directories are selected, proceed with copying and renaming the files
    if ($selectedFolders -and $selectedFolders.Count -eq 2) {
        Write-Host "Two matching Xbox save directories found for Steam save: $($steamSave.Name)"
        
        # Get the files from the selected folders
        $filesFromFolders = $selectedFolders | ForEach-Object { Get-ChildItem $_.FullName -File | Where-Object { $_.Name -notlike "container.2" } }
        
        # Sort the files by length in descending order
        $filesSorted = $filesFromFolders | Sort-Object Length -Descending
        
        # Get the largest and second largest files
        $largerFile = $filesSorted[0]
        $smallerFile = $filesSorted[1]

        # Set the destination file paths
        $destDescrFile = Join-Path -Path $destinationDir -ChildPath "${saveFileName}_descr.sav"
        $destSaveFile = Join-Path -Path $destinationDir -ChildPath "${saveFileName}.sav"

        if ($null -ne $smallerFile) {
            Copy-Item -Path $smallerFile.FullName -Destination $destDescrFile -Force
        } else {
            Write-Host "No description file found to copy for $saveFileName"
            continue
        }

        if ($null -ne $largerFile) {
            Copy-Item -Path $largerFile.FullName -Destination $destSaveFile -Force
        } else {
            Write-Host "No save file found to copy for $saveFileName"
            continue
        }

        # Check if the destination files already exist
        $destDescrFileExists = Test-Path -Path $destDescrFile
        $destSaveFileExists = Test-Path -Path $destSaveFile

        # If the deleteExisting flag is set or the files do not exist, copy the files
        if ($deleteExisting -or (-not $destDescrFileExists -and -not $destSaveFileExists)) {
            # Copy the smaller file to the destination description file
            Write-Host "Copying description file $($smallerFile.Name) to $($destDescrFile)"
            Copy-Item -Path $smallerFile.FullName -Destination $destDescrFile -Force

            # Copy the larger file to the destination save file
            Write-Host "Copying save file $($largerFile.Name) to $($destSaveFile)"
            Copy-Item -Path $largerFile.FullName -Destination $destSaveFile -Force

            Write-Host "Save $destSaveFile successfully $(if ($deleteExisting) { 'replaced' } else { 'copied' })!"
        } else {
            Write-Host "Save $destSaveFile skipped, because it already exists!"
        }
    } else {
        Write-Host "No matching Xbox save directories found for Steam save: $($steamSave.Name)"
    }
}

Write-Host "All matching files have been copied and renamed successfully."