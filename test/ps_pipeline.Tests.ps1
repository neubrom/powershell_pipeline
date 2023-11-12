# Assuming your functions are in a file named 'MyScriptFunctions.ps1'
. .\ps_pipeline.ps1

Describe "Get-FileHashMD5 Tests" {
    It "Calculates the correct MD5 hash for a known file" {
        $testFilePath = "test\File.txt"
        $knownHash = "expected-md5-hash-of-file" # Replace with actual known hash
        $calculatedHash = Get-FileHashMD5 -filePath $testFilePath
        $calculatedHash | Should -Be $knownHash
    }
}

Describe "Write-Log Tests" {
    It "Writes the correct log message to a file" {
        $testLogPath = "test\LogFile.log"
        $testMessage = "Test log entry"
        Write-Log -message $testMessage -logFile $testLogPath
        $logContent = Get-Content -Path $testLogPath
        $logContent | Should -Contain $testMessage
    }
}
