#---------------------------------------------
#Recursively convert *.XLS to *.XLSX in folder
#---------------------------------------------
param (
  [string]$folderXLS = 'E:\Temp\',
  [string]$folderBackup = 'E:\Temp\Backup\'  
)

$filetypeXLS = '*xls'
$parametersCNV = ' -nme -oice'
#---------------------------------------------
function Get-TimeStamp {
    
    return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
    
}
function Get-ExcelCnvExe
{
  $files = Get-ChildItem -Path ${env:ProgramFiles} -Filter 'excelcnv.exe' -Recurse -Force -ErrorAction SilentlyContinue
  If ($files.Count -eq 0)
  {    
    $files = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter 'excelcnv.exe' -Recurse -Force -ErrorAction SilentlyContinue
    If ($files.Count -eq 0)
    {
      Write-Error -Message 'WARNING! excelcnv.exe NOT FOUND! Cannot continue!'
      Break
    }
    Else
    {
      return $files[0].FullName
    }
  }
}

function Get-XLSXfromXLS
{
  param (
    [Parameter(Mandatory=$true)][string]
    $fileConverter,
    [Parameter(Mandatory=$true)][string]
    $parametersCNV,
    [Parameter(Mandatory=$true)][string]
    $fileXLS,
    [Parameter(Mandatory=$true)][string]
    $fileXLSX
   )
   
  #Run converter
  Start-Process -Wait -FilePath $fileConverter -ArgumentList $parametersCNV,('"{0}"' -f $fileXLS),('"{0}"' -f $fileXLSX)
  #Return number of KB saved
  return [int](($(Get-Item -Path $fileXLS).Length - $(Get-Item -Path $fileXLSX).Length)/1024)
}
function Move-FileToBackup
{
  param (
    [Parameter(Mandatory=$true)][string]
    $file,
    [Parameter(Mandatory=$true)][string]
    $path
  )
  #Check if directory exists
  If (!(Test-Path -Path $path -PathType Container))
  {
    $null = New-Item -Path $path -ItemType Directory
    
  }
  
  Move-Item -Path $file -Destination $path -Force
  
}



If (Test-Path -Path $folderXLS -PathType Container)
{
  #Get path of converter
  $fileConverter = Get-ExcelCnvExe
  Write-Output -InputObject $('Found converter at',$fileConverter -join ' ')
  
  If (!(Test-Path -Path $folderBackup -PathType Container))
  {
    $null = New-Item -Path $folderBackup -ItemType Directory
    Write-Output -InputObject $('Created backup folder:',$folderBackup -join ' ')
  }
  Else
  {
    Write-Output -InputObject $('Backup folder exists at',$folderBackup -join ' ')
  }
  #Write-Host $folderBackup
  
  #Process *.xls
  $filesXLS = Get-ChildItem -Path $folderXLS -Include $filetypeXLS -recurse
  $filesCount = 1
  $filesSize = 0
  $resultSaved = 0
  Write-Output -InputObject $('Found',$filesXLS.Count,'files at',('"{0}"' -f $folderXLS) -join ' ')
  ForEach ($fileXLS in $filesXLS)
  {
    #Strip old extension
    $fileXLSX = (($fileXLS.FullName).SubString(0, ($fileXLS.FullName).LastIndexOf('.'))),'.xlsx' -join ''
    $filesSize += [int]($fileXLS.Length/1024)
    
    #Backup path
    $fileBackupPath = Join-Path -Path $folderBackup -ChildPath $fileXLS.Directory.ToString().SubString($fileXLS.Directory.ToString().IndexOf(':')+1, $fileXLS.Directory.ToString().Length-$fileXLS.Directory.ToString().IndexOf(':')-1)
       
    #Convert
    Write-Output -InputObject $($(Get-TimeStamp),'Processing',('"{0}"' -f $fileXLS),' file',$filesCount,'from',$filesXLS.Count -join ' ')
    If (Test-Path -Path $fileXLSX)
    {
      If ($fileXLS.LastWriteTimeUtc -le $(Get-Item -Path $fileXLSX).LastWriteTimeUtc)
      {
        Write-Output -InputObject $('WARNING! Skipping',$fileXLS.FullName,'as converted file already in place and newer than original!' -join ' ')
        $fileSavedKB = 0
      }
      Else
      {
        $fileSavedKB = Get-XLSXfromXLS -fileConverter $fileConverter -parametersCNV $parametersCNV -fileXLS $fileXLS -fileXLSX $fileXLSX
        Write-Output -InputObject $($(Get-TimeStamp),'Finished!', $fileSavedKB,'KB saved' -join ' ')
      }
    }
    Else
    {
      $fileSavedKB = Get-XLSXfromXLS -fileConverter $fileConverter -parametersCNV $parametersCNV -fileXLS $fileXLS -fileXLSX $fileXLSX
      Write-Output -InputObject $($(Get-TimeStamp),'Finished!', $fileSavedKB,'KB saved' -join ' ')
    }
    Move-FileToBackup $fileXLS $fileBackupPath
    $filesCount += 1
    $resultSaved += $fileSavedKB
        
  }
  Write-Output -InputObject $('Total saved: ',$resultSaved,'KB from ',$filesSize,'KB. Occupied space will reduced by ',$([int](($resultSaved/$filesSize)*100)),'% after removing original files' -join '')
}
Else
{
  Write-Error -Message 'WARNING! Specified folder does not exist!'
  Break
}

