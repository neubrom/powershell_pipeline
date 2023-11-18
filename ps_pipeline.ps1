
    Author: Roman Poltoratski
    GPL-3.0 License
    Version: 1.1
    Update the sourceDirs, targetDir, backupDir, logFile, and regexPattern variables as per your environment.


    <#
.SYNOPSIS
    Generates a GUID for a file based on its name, size, and content, and manages backups with versioning.

.DESCRIPTION
    This script generates a GUID for a given file based on its name, size, and SHA1 hash of its content.
    It then checks for a specified pattern in the file name. If matched, the file is backed up to a folder
    named after the pattern and date. It handles versioning for files with the same name but different content.

.PARAMETER FilePath
    Path of the file to be processed.

.PARAMETER Pattern
    Pattern to match in the file name for backup.

.PARAMETER BackupFolder
    Path of the folder where backups are stored.

.EXAMPLE
    .\ThisScript.ps1 -FilePath "C:\path\to\your\file.txt" -Pattern "your_pattern" -BackupFolder "C:\backup"

.NOTES
    Version: 1.2
    GPL-3.0 License
    Author: Roman Poltoratski
    Date: 2023-11-18
#>

param (
    [string]$FilePath,
    [string]$Pattern,
    [string]$BackupFolder
)

function Generate-GuidFromFile {
    param (
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }

    try {
        $file = Get-Item $FilePath
        $fileName = $file.Name
        $fileSize = $file.Length
        $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
        $fileContent = [System.IO.File]::ReadAllBytes($FilePath)
        $hashBytes = $sha1.ComputeHash($fileContent)
        $hashString = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
        $combinedString = "$fileName$fileSize$hashString"
        $combinedBytes = [System.Text.Encoding]::UTF8.GetBytes($combinedString)
        $finalHashBytes = $sha1.ComputeHash($combinedBytes)
        $finalHashString = -join ($finalHashBytes | ForEach-Object { $_.ToString("x2") })
        $guidString = $finalHashString.Substring(0, 32)
        $guid = [guid]::new($guidString)
        return $guid
    } catch {
        Write-Error "An error occurred while generating GUID: $_"
        return $null
    }
}

function Backup-FileWithVersioning {
    param (
        [string]$SourceFilePath,
        [string]$DestinationFolder,
        [string]$GUID
    )

    try {
        $fileName = [System.IO.Path]::GetFileName($SourceFilePath)
        $backupFilePath = Join-Path $DestinationFolder $fileName
        $backupGuidFilePath = $backupFilePath + ".GUID"

        $version = 0
        while (Test-Path $backupFilePath -or Test-Path $backupGuidFilePath) {
            if ((Get-Content $backupGuidFilePath) -ne $GUID) {
                $version++
                $backupFilePath = Join-Path $DestinationFolder ($fileName -replace "\.([^.]+)$", ("v" + $version + ".$1"))
                $backupGuidFilePath = $backupFilePath + ".GUID"
            } else {
                break
            }
        }

        Copy-Item $SourceFilePath $backupFilePath
        $GUID | Out-File $backupGuidFilePath
        return $true
    } catch {
        Write-Error "An error occurred while backing up the file: $_"
        return $false
    }
}

function Test-BackupIntegrity {
    param (
        [string]$BackupFolder
    )

    $backupFiles = Get-ChildItem $BackupFolder -Recurse | Where-Object { -not $_.PSIsContainer }
    foreach ($file in $backupFiles) {
        if ($file.Extension -eq ".GUID") {
            continue
        }

        $guidFilePath = $file.FullName + ".GUID"
        if (-not (Test-Path $guidFilePath)) {
            Write-Host "Missing GUID file for: $($file.FullName)"
            continue
        }

        $originalGuid = Get-Content $guidFilePath
        $computedGuid = Generate-GuidFromFile -FilePath $file.FullName
        if ($originalGuid -ne $computedGuid) {
            Write-Host "Integrity check failed for: $($file.FullName)"
        }
    }
}

# Main script logic
$guid = Generate-GuidFromFile -FilePath $FilePath
if ($guid -eq $null) {
    Write-Host "Exiting due to error in GUID generation."
    exit
}

if ($FilePath -match $Pattern) {
    $dateFolder = (Get-Date).ToString("yyyy-MM-dd")
    $dateSpecificBackupFolder = Join-Path $BackupFolder $dateFolder
    if (-Not (Test-Path $dateSpecificBackupFolder)) {
        New-Item -ItemType Directory -Path $dateSpecificBackupFolder
    }

    $backupSuccess = Backup-FileWithVersioning -SourceFilePath $FilePath -DestinationFolder $dateSpecificBackupFolder -GUID $guid
    if (-not $backupSuccess) {
        Write-Host "Exiting due to error in backup process."
        exit
    }
}

# Optional: Perform integrity check on the backups
# Test-BackupIntegrity -BackupFolder $BackupFolder
