# Import the PowerShell script to be tested
. "$PSScriptRoot\..\ps_pipeline.ps1"

# Describe block for the group of tests
Describe "PowerShell Script ps_pipeline Tests" {

    # BeforeEach block to set up the environment for each test
    BeforeEach {
        # Define the source, target, and backup directories
        $testSourceDir = Join-Path $Env:TEST_SOURCE_DIR "testSource"
        $testTargetDir = Join-Path $Env:TEST_TARGET_DIR "testTarget"
        $testBackupDir = Join-Path $Env:TEST_BACKUP_DIR "testBackup"

        # Create the directories
        New-Item -ItemType Directory -Path $testSourceDir, $testTargetDir, $testBackupDir -Force

        # Create a test file in the source directory
        $testFile = Join-Path $testSourceDir "testFile.txt"
        "Test content" | Out-File -FilePath $testFile
    }

    # Test case for verifying the file processing and movement
    It "Should process the file correctly and move it to the backup folder" {
        # Run the PowerShell script with parameters
        ps_pipeline -SourceFolder $testSourceDir -TargetFolder $testTargetDir -BackupFolder $testBackupDir -RegexPattern ".*"

        # Assertions to check the expected outcomes
        # Check if the file exists in the backup folder
        $backupFilePath = Join-Path $testBackupDir "testFile.txt"
        $fileExistsInBackup = Test-Path $backupFilePath
        $fileExistsInBackup | Should -BeTrue

        # Check if the file no longer exists in the source folder
        $fileExistsInSource = Test-Path $testFile
        $fileExistsInSource | Should -BeFalse
    }
}
