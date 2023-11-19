# Import the module/script containing the functions to be tested
. "$PSScriptRoot\..\ps_pipeline.ps1"

# Describe block defines a group of test cases
Describe "PowerShell Script ps_pipeline Tests" {

    # BeforeEach block runs before each test in the Describe block
    BeforeEach {
        # Setup test directories
        $testSourceDir = Join-Path $Env:GITHUB_WORKSPACE "testSource"
        $testTargetDir = Join-Path $Env:GITHUB_WORKSPACE "testTarget"
        $testBackupDir = Join-Path $Env:GITHUB_WORKSPACE "testBackup"
        New-Item -ItemType Directory -Path $testSourceDir, $testTargetDir, $testBackupDir -Force

        # Create a test file in the source directory
        $testFile = Join-Path $testSourceDir "testFile.txt"
        "Test content" | Out-File -FilePath $testFile

        # Define other necessary variables or parameters
        $testRegexPattern = ".*" # Example regex pattern
    }

    # Test case
    It "Should process the file correctly and move it to the backup folder" {
        # Call the script with the test parameters
        ps_pipeline -SourceFolder $testSourceDir -RegexPattern $testRegexPattern -TargetFolder $testTargetDir -BackupFolder $testBackupDir

        # Assertions to verify the expected outcomes
        $backupFilePath = Join-Path $testBackupDir "testFile.txt"
        $fileExistsInBackup = Test-Path $backupFilePath
        $fileExistsInBackup | Should -BeTrue
        $fileExistsInSource = Test-Path $testFile
        $fileExistsInSource | Should -BeFalse
    }
}