<#
.SYNOPSIS
    Processes files from a source folder to a target folder and then to a backup folder, based on matching regex patterns and file integrity verification.

.DESCRIPTION
    This script generates a GUID for files in a source folder and subfolders, copies files to a target folder, verifies integrity, and moves them to a backup folder if conditions are met.

.PARAMETER SourceFolder
    Path of the folder to be processed.

.PARAMETER RegexPattern
    Regex pattern to match in file names for processing.

.PARAMETER TargetFolder
    Path of the folder where files are initially copied.

.PARAMETER BackupFolder
    Path of the folder where files are finally stored after verification.

.EXAMPLE
    .\ThisScript.ps1 -SourceFolder "C:\path\to\your\folder" -RegexPattern "\w+_backup_\d{4}" -TargetFolder "C:\target" -BackupFolder "C:\backup"

.NOTES
    Version: 1.9
    GPL-3.0 License
    Author: Roman Poltoratski
    Date: 2023-11-19
#>

param (
    [string]$SourceFolder,
    [string]$RegexPattern,
    [string]$TargetFolder,
    [string]$BackupFolder
)

# Existing functions (Generate-GuidFromFile, Test-BackupIntegrity) remain the same

function Process-File {
    param (
        [string]$SourceFilePath,
        [string]$TargetFolderPath,
        [string]$BackupFolderPath,
        [string]$Regex,
        [string]$GUID
    )

    try {
        $fileName = [System.IO.Path]::GetFileName($SourceFilePath)
        $patternMatch = if ($fileName -match $Regex) { $Matches[0] } else { "NoPattern" }

        # Create folders in target and backup based on the pattern match
        $patternTargetFolder = Join-Path $TargetFolderPath $patternMatch
        $patternBackupFolder = Join-Path $BackupFolderPath $patternMatch
        New-Item -ItemType Directory -Path $patternTargetFolder, $patternBackupFolder -Force

        # Versioning logic for both target and backup folders
        foreach ($folder in @($patternTargetFolder, $patternBackupFolder)) {
            $versionedFilePath = Join-Path $folder $fileName
            $version = 0
            while (Test-Path $versionedFilePath) {
                $version++
                $versionedFilePath = Join-Path $folder ($fileName -replace "\.([^.]+)$", ("v" + $version + ".$1"))
            }
        }

        # Copy the file to the target folder and verify
        $targetFilePath = Join-Path $patternTargetFolder $fileName
        Copy-Item $SourceFilePath $targetFilePath
        $copiedFileGuid = Generate-GuidFromFile -FilePath $targetFilePath
        if ($copiedFileGuid -eq $GUID) {
            # Move the source file to the backup folder if GUIDs match
            $backupFilePath = Join-Path $patternBackupFolder $fileName
            Move-Item $SourceFilePath $backupFilePath -Force
            return $true
        } else {
            Write-Host "GUID mismatch for file: $SourceFilePath"
            return $false
        }
    } catch {
        Write-Error "An error occurred during the file processing: $_"
        return $false
    }
}

# Main script logic
if (-Not (Test-Path $SourceFolder)) {
    Write-Error "Source folder not found: $SourceFolder"
    exit
}

$files = Get-ChildItem -Path $SourceFolder -Recurse -File
foreach ($file in $files) {
    $filePath = $file.FullName
    $guid = Generate-GuidFromFile -FilePath $filePath
    if ($guid -eq $null) {
        Write-Host "Skipping file due to error in GUID generation: $filePath"
        continue
    }

    if ($filePath -match $RegexPattern) {
        $processSuccess = Process-File -SourceFilePath $filePath -TargetFolderPath $TargetFolder -BackupFolderPath $BackupFolder -Regex $RegexPattern -GUID $guid
        if (-not $processSuccess) {
            Write-Host "Error occurred during the file processing for: $filePath"
        }
    }
}
