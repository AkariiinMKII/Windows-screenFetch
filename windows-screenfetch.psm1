#### Screenfetch for powershell
#### Author Julian Chow


Function Screenfetch($distro)
{
    $AsciiArt = "";

    if (-not $distro) {
        $AsciiArt = . Get-WindowsArt;
    }

    if (([string]::Compare($distro, "mac", $true) -eq 0) -or
        ([string]::Compare($distro, "macOS", $true) -eq 0) -or
        ([string]::Compare($distro, "osx", $true) -eq 0)) {
        $AsciiArt = . Get-MacArt;
    }
    else {
        $AsciiArt = . Get-WindowsArt;
    }

    $SystemInfoCollection = . Get-SystemSpecifications;
    $LineToTitleMappings = . Get-LineToTitleMappings;

    # Iterate over all lines from the SystemInfoCollection to display all information
    $LineNumber = (($SystemInfoCollection.Count, $AsciiArt.Count) | Measure-Object -Maximum).Maximum;
    for ($line = 0; $line -lt $LineNumber; $line++) {
        if (($AsciiArt[$line].Length) -eq 0) {
            # Write some whitespaces to sync the left spacing with the asciiart.
            Write-Host "                                    " -f Cyan -NoNewline;
        }
        else {
            Write-Host $AsciiArt[$line] -f Cyan -NoNewline;
        }
        
        Write-Host $LineToTitleMappings[$line] -f Red -NoNewline;

        if ($line -eq 0) {
            $UserInfoSeperator = "@";
            $SplittedUserInfo = $SystemInfoCollection[$line].Split($UserInfoSeperator);
            
            Write-Host $SplittedUserInfo[0] -f Red -NoNewline;
            Write-Host $UserInfoSeperator -NoNewline;
            Write-Host $SplittedUserInfo[1] -f Red;
        }
        elseif ($SystemInfoCollection[$line] -like '*:*') {
            $DiskInfoSeperator = ":";
            $SplittedDiskInfo = $SystemInfoCollection[$line].Split($DiskInfoSeperator);

            $Title = $SplittedDiskInfo[0] + $DiskInfoSeperator;
            $Content = $SplittedDiskInfo[1];

            Write-Host $Title -f Red -NoNewline;
            Write-Host $Content;
        }
        else {
            Write-Host $SystemInfoCollection[$line];
        }
    }
}
