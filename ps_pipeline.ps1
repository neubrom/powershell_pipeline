<#
.SYNOPSIS
    Copies files based on regex matching from source to target directories, handles duplicates with versioning, calculates and verifies SHA-256 checksums, moves processed files to a backup directory, and logs operations.

.DESCRIPTION
    This script searches specified source directories for files matching a regex pattern, handles file duplicates by versioning if necessary, and copies them to a target directory. It calculates SHA-256 checksums for these files, compares them with existing checksums if available, moves successfully processed files to a backup directory, and logs all operations including errors.

.PARAMETER sourceDirs
    Array of paths to the source directories where files are located.

.PARAMETER targetDir
    Path of the target directory where files will be copied to.

.PARAMETER backupDir
    Path of the backup directory where successfully processed files will be moved to.

.PARAMETER logFile
    Path to the log file for recording script operations and events.

.PARAMETER regexPattern
    The regex pattern used to identify files to be processed.

.EXAMPLE
    .\scriptName.ps1 -sourceDir "C:\source" -targetDir "C:\target" -backupDir "C:\backup" -logFile "C:\log.txt" -regexPattern "FO\d{8}"

.NOTES
    Author: Roman Poltoratski
    GPL-3.0 License
    Version: 1.1
    Update the sourceDirs, targetDir, backupDir, logFile, and regexPattern variables as per your environment.
#>

param (
    [string[]]$sourceDirs,
    [string]$targetDir,
    [string]$backupDir,
    [string]$logFile,
    [string]$regexPattern
)

function Get-FileHashSHA256 {
    param ([string]$filePath)
    (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
}

function Write-Log {
    param (
        [string]$message,
        [string]$logFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp: $message" | Add-Content -Path $logFile
}

function Copy-FilesBasedOnPattern {
    param (
        [string]$sourceDir,
        [string]$targetDir,
        [string]$pattern,
        [string]$logFile,
        [string]$backupDir
    )

    $files = Get-ChildItem -Path $sourceDir -Recurse | Where-Object { $_.Name -match $pattern }

    foreach ($file in $files) {
        $targetFilePath = Join-Path $targetDir $file.Name
        $fileHash = Get-FileHashSHA256 -filePath $file.FullName

        if (Test-Path -Path $targetFilePath) {
            $targetFileHash = Get-FileHashSHA256 -filePath $targetFilePath

            if ($fileHash -ne $targetFileHash) {
                $newFileName = Get-VersionedFileName -sourceDir $targetDir -fileName $file.Name
                $targetFilePath = Join-Path $targetDir $newFileName
            }
        }

        Copy-Item -Path $file.FullName -Destination $targetFilePath
        $copiedFileHash = Get-FileHashSHA256 -filePath $targetFilePath

        if ($fileHash -eq $copiedFileHash) {
            Write-Log "Successfully copied and verified file to $targetFilePath" -logFile $logFile
            $backupFilePath = Join-Path $backupDir $file.Name
            Move-Item -Path $file.FullName -Destination $backupFilePath
            Write-Log "Moved source file to backup: $backupFilePath" -logFile $logFile
        } else {
            Write-Log "Hash mismatch after copying file to $targetFilePath" -logFile $logFile
        }
    }
}

function Get-VersionedFileName {
    param (
        [string]$sourceDir,
        [string]$fileName
    )

    $version = 1
    $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $fileExtension = [System.IO.Path]::GetExtension($fileName)
    $newFileName = "${fileBaseName}_v$version$fileExtension"

    while (Test-Path -Path (Join-Path $sourceDir $newFileName)) {
        $version++
        $newFileName = "${fileBaseName}_v$version$fileExtension"
    }

    return $newFileName
}

foreach ($sourceDir in $sourceDirs) {
    Copy-FilesBasedOnPattern -sourceDir $sourceDir -targetDir $targetDir -pattern $regexPattern -logFile $logFile -backupDir $backupDir
}

Write-Log "Script execution completed." -logFile $logFile
