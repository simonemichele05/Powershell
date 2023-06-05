function Get-BinaryMask {
    param (
        [int]$numberOfOnes
    )

    # Genera il numero binario
    $binaryNumber = ""
    for ($i = 0; $i -lt 32; $i++) {
        if ($i -lt $numberOfOnes) {
            $binaryNumber += "1"
        } else {
            $binaryNumber += "0"
        }
    }

    return $binaryNumber
}

function Get-IPRange {
    param (
        [string]$networkAddress
    )

    # Converte l'indirizzo di rete in un oggetto IPAddress
    $networkIP = [System.Net.IPAddress]::Parse($networkAddress)

    # Ottiene l'indirizzo IP base per la subnet
    $baseIPNumeric = [System.BitConverter]::ToInt32($networkIP.GetAddressBytes(), 0)

    # Scansione degli indirizzi IP all'interno della subnet
    $activseIPs = @()
    for ($i = 1; $i -le 255; $i++) {
        $ipBytes = [System.BitConverter]::GetBytes($baseIPNumeric)
        $ipBytes[3] = $i
        $ip = [System.Net.IPAddress]::new($ipBytes)

        if (Test-Connection -ComputerName $ip.IPAddressToString -Count 1 -Quiet) {
            $activeIPs += $ip.IPAddressToString
        }
    }
    return $activeIPs
}

function Get-FreePorts{
    param (
        [string]$ip
    )

    $portRange = 54990..55000
    $freePorts = @()  # Array per memorizzare le porte libere
    foreach ($port in $portRange) {
        if (Test-NetConnection -ComputerName $ip -Port $port -InformationLevel Quiet) {
            $freePorts += $port
        }
    }
    return $freePorts
}

function Convert-BinaryToIPAddress {
    param (
        [string]$binaryString
    )

    # Divide la stringa binaria in quattro parti da 8 caratteri ciascuna
    $parts = @()
    for ($i = 0; $i -lt 4; $i++) {
        $start = $i * 8
        $part = $binaryString.Substring($start, 8)
        $parts += $part
    }

    # Converti ogni parte binaria in un numero decimale
    $decimalParts = @()
    foreach ($part in $parts) {
        $decimalPart = [Convert]::ToUInt32($part, 2)
        $decimalParts += $decimalPart.ToString()
    }

    # Concatena i numeri decimali con intervalli puntati
    $ipAddress = $decimalParts -join "."

    return $ipAddress
}

# Ottieni l'indirizzo IP del dispositivo
$ipAddress = Test-Connection -ComputerName $env:COMPUTERNAME -Count 1 | Select-Object -ExpandProperty IPV4Address

$ipBytes = ($ipAddress -split '\.' | ForEach-Object { [byte]$_ })
$ipBytes = $ipBytes[$ipBytes.Length..0]

$binaryAddress = [System.Convert]::ToString([System.BitConverter]::ToInt32($ipBytes, 0), 2)

Write-Host "IP ADDRESS: " $ipAddress


# Ottieni la subnet mask
$subnetMask = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -eq $ipAddress.IPAddressToString }).PrefixLength

$binaryMask = Get-BinaryMask -numberOfOnes $subnetMask

$decimalMask = Convert-BinaryToIPAddress -binaryString $binaryMask

Write-Host "DECIMAL MASK: " $decimalMask


# Ottieni l'indirizzo di rete
$decimalNumber1 = [Convert]::ToInt32($binaryAddress, 2)
$decimalNumber2 = [Convert]::ToInt32($binaryMask, 2)

$binaryNetwork = $decimalNumber1 -band $decimalNumber2

$binaryNetwork = [Convert]::ToString($binaryNetwork, 2)
$networkAddress = Convert-BinaryToIPAddress -binaryString $binaryNetwork

Write-Host "NETWORK ADDRESS: " $networkAddress


# Host nella rete
$ipRange = Get-IPRange -networkAddress $networkAddress

$ip = "192.164.50.66"
$listeningPorts = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' -and $_.LocalAddress -eq $ip }
Write-Host $listeningPorts

# Stampa gli indirizzi IP
Write-Host "HOST NELLA RETE:"
foreach ($ip in $ipRange) {
    Write-Host $ip`n
    $freePorts = Get-FreePorts -ip $ip
    Write-Host "FREE PORTS: " $freePorts
}