# DATEV Leistungsindex Silent ausführen
# 03/2022 - Thomas Lauer (lauer@glsh.net)
# Github - https://github.com/glshnu

function Get-IniFile 
{  
    param(  
        [parameter(Mandatory = $true)] [string] $filePath  
    )  
    
    $anonymous = "NoSection"
  
    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  

        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   

        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $ini[$section][$name] = $value  
        }  
    }  

    return $ini  
}

Start-Process -FilePath "$($env:datevpp)\PROGRAMM\RWApplic\irw.exe" -ArgumentList "-ap:PerfIndex -d:IRW20011 -c" -Wait
Start-Process -FilePath "$($env:datevpp)\PROGRAMM\RWApplic\irw.exe" -ArgumentList "-ap:PerfIndex -d:IRW20011 -c" -Wait

$dir = "$($env:temp)\IrwPerformanceIndex*.txt"
write-host "dir" $dir

#Umgebung ausgeben
$Env = @{
  "USERNAME"     = $env:USERNAME 
  "USERPROFILE"  = $env:USERPROFILE
  "COMPUTERNAME" = $env:COMPUTERNAME
}
$Env | ft

$latest = Get-ChildItem -Path $dir | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$latest | ft name, FullName

$iniFile = Get-IniFile $latest.FullName

Clear-Variable result
$result= [pscustomobject]($iniFile.StartScore,$iniFile.DataAccessScore,$iniFile.ProcessorScore,$iniFile.HardDiskScore,$iniFile.GuiScore,$iniFile.OverallScore | select @{Label="Name";E={$_.Name}},@{Label="Duration";E={$_.Duration.replace(' Sekunden','')}})
$result


#$iniFile | ConvertTo-Json
#$iniFile.AssesmentInfo
#$iniFile.ProcessorInfo
#$iniFile.Common


# UDF Feld für Datto RMM schreiben
# New-ItemProperty -Path HKLM:\SOFTWARE\CentraStage -Name Custom16 -Value $OverallScore -Force

