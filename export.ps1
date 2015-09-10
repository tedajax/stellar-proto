$base64path = gc $env:appdata\Dropbox\host.db | select -index (1)
# -index 1 is the 2nd line in the file

$dropboxPath = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($base64path)) # convert from base64 to ascii

Write-Host $PSScriptRoot

$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "git"
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.CreateNoWindow = $true
$pinfo.WorkingDirectory = $PSScriptRoot
$pinfo.Arguments = "archive master --format zip -o stellar.love"
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

Write-Host "Creating archive of repository and storing in stellar.love..."

if ($p.ExitCode -ne 0) {
    Write-Host "Error while performing git archive."
    Write-Host "stdout: " + $stdout
    Write-Host "stderr: " + $stderr
    Write-Host "exit code: " + $p.ExitCode
    Exit
}

Write-Host "Copying .love package to dropbox directory..."
Copy-Item stellar.love $dropboxPath\Stellar\.

Write-Host "Done!"