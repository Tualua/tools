param (
  [string[]]$Miners
)
function Get-MinersFromFile 
{
  param
  (
    [Parameter(Mandatory=$true)][string]
    $Path    
  )
  $Miners = @()
  $regexIPAddr = '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  Get-Content -Path $Path | ForEach-Object {
    If ($_ -match $regexIPAddr)
    {    
      $Miners += [string]$_      
    }
  }
  
  return $Miners | Sort-Object -Property { [Version] $_} -Unique
}
function Get-MinerData
{
  param
  (
    [string]$user, 
    [string]$pass, 
    [string]$url
  ) 
  $securepasswd = ConvertTo-SecureString $pass -AsPlainText -Force
  $cred = New-Object System.Management.Automation.PSCredential($user, $securepasswd)
  $responseData = Invoke-WebRequest -Uri $url -Credential $cred

  return $responseData
  }

If (!($Miners))
{
  $Miners = Get-MinersFromFile -Path $(Join-Path -Path $PSSCriptRoot -ChildPath 'xmrminers.txt' )
}
 
$username = 'user'
$password = 'password'
$apiurl = 'api.json'
$minerport = '8888'
$stats = @()
$total10s= 0
$total60s= 0
$total15m= 0
$totals = @()
ForEach ($miner in $Miners)
{
  $url = $("http://$miner",$minerport -join ':'),$apiurl -join '/'
  $rawdata = Get-MinerData -user $username -pass $password -url $url
  $stats += [psCustomObject]@{
      'miner' = $miner
      'hashrate 10s' = [int]$($rawdata.content|ConvertFrom-Json).hashrate.total[0]
      'hashrate 60s' = [int]$($rawdata.content|ConvertFrom-Json).hashrate.total[1]
      'hashrate 15m' = [int]$($rawdata.content|ConvertFrom-Json).hashrate.total[2]
      'threads' = [int]$($rawdata.content|ConvertFrom-Json).hashrate.threads.count
      
  }
  $total10s += [int]$($rawdata.content|ConvertFrom-Json).hashrate.total[0] 
  $total60s += [int]$($rawdata.content|ConvertFrom-Json).hashrate.total[1] 
  $total15m += [int]$($rawdata.content|ConvertFrom-Json).hashrate.total[2] 
}

$stats.GetEnumerator()|Sort-Object -Property 'hashrate 15m' -Descending | Format-Table

Write-Host $("Total miners:", $stats.Count -join ' ')

$totals += [psCustomObject]@{
      'data' = 'Total'
      'hashrate 10s' = $total10s
      'hashrate 60s' = $total60s
      'hashrate 15m' = $total15m
      
      
  }
$totals += [psCustomObject]@{
      'data' = 'Average'
      'hashrate 10s' = [int]$($total10s/($stats.Count-1))
      'hashrate 60s' = [int]$($total60s/($stats.Count-1))
      'hashrate 15m' = [int]$($total15m/($stats.Count-1))
      
      
  }
$totals | Format-Table

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
