<#
.SYNOPSIS
    Copies files based on regex matching from source to target directories, calculates and verifies MD5 checksums, and logs operations.

.DESCRIPTION
    This script searches specified source directories for files matching a regex pattern and copies them to a target directory.
    It calculates MD5 checksums for these files, compares them with existing checksums if available, and logs all operations including errors.

.PARAMETER sourceDirs
    Array of paths to the source directories where files are located.

.PARAMETER targetDir
    Path of the target directory where files will be copied to.

.PARAMETER logFile
    Path to the log file for recording script operations and events.

.EXAMPLE
    .\scriptName.ps1
    Execute the script to copy and process files as per the specified parameters.

.NOTES
    Author: Roman Poltoratski
    GPL-3.0 license
    Version: 1.0
    Update the sourceDirs, targetDir, and logFile variables as per your environment.
#>

# Script Configuration
param (
    [string]$sourceDir = $env:SOURCE_DIR,
    [string]$targetDir = $env:TARGET_DIR,
    [string]$logFile = $env:LOG_FILE
    [string]$regexPattern = $env:REGEX_PATTERN
)

# Function to save MD5 checksum in a file
function Save-MD5Checksum {
    param (
        [string]$filePath,
        [string]$logFile
    )

    try {
        $checksumFileName = "$filePath.md5"
        $newMd5Hash = Get-FileHashMD5 -filePath $filePath

        if (Test-Path -Path $checksumFileName) {
            $existingMd5Hash = Get-Content -Path $checksumFileName

            if ($existingMd5Hash -ne $newMd5Hash) {
                Write-Log "Warning: MD5 hash mismatch for $filePath. Existing: $existingMd5Hash, New: $newMd5Hash" -logFile $logFile
            }
        }

        $newMd5Hash | Out-File -FilePath $checksumFileName -Encoding ASCII
        Write-Log "MD5 hash saved for $filePath" -logFile $logFile
    } catch {
        Write-Log "Error saving MD5 checksum for file: $filePath. Error: $_" -logFile $logFile
    }
}

# Function to save MD5 checksum in a file
function Save-MD5Checksum {
    param (
        [string]$filePath,
        [string]$logFile
    )

    try {
        $checksumFileName = "$filePath.md5"
        $newMd5Hash = Get-FileHashMD5 -filePath $filePath

        if (Test-Path -Path $checksumFileName) {
            $existingMd5Hash = Get-Content -Path $checksumFileName

            if ($existingMd5Hash -ne $newMd5Hash) {
                Write-Log "Warning: MD5 hash mismatch for $filePath. Existing: $existingMd5Hash, New: $newMd5Hash" -logFile $logFile
            }
        }

        $newMd5Hash | Out-File -FilePath $checksumFileName -Encoding ASCII
        Write-Log "MD5 hash saved for $filePath" -logFile $logFile
    } catch {
        Write-Log "Error saving MD5 checksum for file: $filePath. Error: $_" -logFile $logFile
    }
}

# Function to write logs with timestamp
function Write-Log {
    param (
        [string]$message,
        [string]$logFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp: $message" | Add-Content -Path $logFile

# Function to copy files based on pattern
function Copy-FilesBasedOnPattern {
    param (
        [string]$sourceDir,
        [string]$targetDir,
        [string]$pattern,
        [string]$logFile
    )

    try {
        $files = Get-ChildItem -Path $sourceDir -Recurse | Where-Object { $_.Name -match $pattern }

        foreach ($file in $files) {
            $targetFilePath = Join-Path $targetDir $file.Name

            if (!(Test-Path -Path $targetFilePath)) {
                Copy-Item -Path $file.FullName -Destination $targetFilePath
                Write-Log "Copied file to $targetFilePath" -logFile $logFile
                Save-MD5Checksum -filePath $targetFilePath -logFile $logFile
            } else {
                Write-Log "File already exists at destination: $targetFilePath" -logFile $logFile
            }
        }
    } catch {
        Write-Log "Error copying files from $sourceDir to $targetDir. Error: $_" -logFile $logFile
    }
}

# Main Script Logic
foreach ($sourceDir in $sourceDirs) {
    Copy-FilesBasedOnPattern -sourceDir $sourceDir -targetDir $targetDir -pattern $regexPattern -logFile $logFile
}

Write-Log "Script execution completed." -logFile $logFile
