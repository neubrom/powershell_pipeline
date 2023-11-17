# Dot-source the PowerShell script to test its functions
. .\ps_pipeline.ps1

# Test setup: creating necessary directories and files
$testSourceDir = Join-Path $env:GITHUB_WORKSPACE "testSource"
$testTargetDir = Join-Path $env:GITHUB_WORKSPACE "testTarget"
$testBackupDir = Join-Path $env:GITHUB_WORKSPACE "testBackup"
$testLogFile = Join-Path $env:GITHUB_WORKSPACE "test.log"
$testFileName = "testFile.txt"
$testFilePath = Join-Path $testSourceDir $testFileName

BeforeAll {
    New-Item -ItemType Directory -Path $testSourceDir, $testTargetDir, $testBackupDir -Force
    "Test content" | Out-File -FilePath $testFilePath
}

Describe "Get-FileHashSHA256 Tests" {
    It "Calculates the correct SHA-256 hash for a known file" {
        $knownHash = "expected-sha256-hash-of-testFile.txt" # Replace with actual hash
        $calculatedHash = Get-FileHashSHA256 -filePath $testFilePath
        $calculatedHash | Should -Be $knownHash
    }
}

Describe "Write-Log Tests" {
    It "Writes the correct log message to a file" {
        $testMessage = "Test log entry"
        Write-Log -message $testMessage -logFile $testLogFile
        $logContent = Get-Content -Path $testLogFile
        $logContent | Should -Contain $testMessage
    }
}

Describe "Copy-FilesBasedOnPattern Tests" {
    It "Successfully copies and verifies files based on pattern" {
        Copy-FilesBasedOnPattern -sourceDir $testSourceDir -targetDir $testTargetDir -pattern ".*\.txt" -logFile $testLogFile -backupDir $testBackupDir
        Test-Path (Join-Path $testTargetDir $testFileName) | Should -BeTrue
    }

    It "Moves the source file to backup after successful copy" {
        Test-Path (Join-Path $testBackupDir $testFileName) | Should -BeTrue
    }
}

Describe "Get-VersionedFileName Tests" {
    It "Generates a correctly versioned file name" {
        $existingFileName = "existingFile.txt"
        $existingFilePath = Join-Path $testSourceDir $existingFileName
        New-Item -Path $existingFilePath -ItemType File
        $versionedName = Get-VersionedFileName -sourceDir $testSourceDir -fileName $existingFileName
        $versionedName | Should -Be "existingFile_v1.txt"
        Remove-Item -Path $existingFilePath
    }
}

# Test cleanup: removing test directories and files
AfterAll {
    Remove-Item -Path $testSourceDir, $testTargetDir, $testBackupDir, $testLogFile -Recurse -Force
}
