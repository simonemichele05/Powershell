$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"

if (Test-Path $regKey) {
    Remove-ItemProperty -Path $regKey -Name '*' -ErrorAction SilentlyContinue
}
