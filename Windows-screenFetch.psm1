Function screenFetch() {
    <#
    .SYNOPSIS
        A Powershell port of bash/unix screenFetch.

    .PARAMETER Distro
        Select an alternative logo to show.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $Distro
    )

    $MacDistro = @("mac", "macos", "osx", "apple")
    $WinXPDistro = @("winxp", "windowsxp", "xp", "win xp", "windows xp")

    switch ($Distro) {
        {$MacDistro -contains $_} {$AsciiArt = . New-MacLogo; Break}
        {$WinXPDistro -contains $_} {$AsciiArt = . New-WinXPLogo; Break}
        default {$AsciiArt = . New-WinLogo; Break}
    }

    $SystemInfoCollection = . Get-SystemSpecifications;
    $LineToTitleMappings = . Get-LineToTitleMappings;

    # Iterate over all lines from the SystemInfoCollection to display all information
    $NumLines = (($SystemInfoCollection.Count, $AsciiArt.Count) | Measure-Object -Maximum).Maximum;
    for ($line = 0; $line -lt $NumLines; $line++) {
        if (($AsciiArt[$line].Length) -eq 0) {
            # Write some whitespaces to sync the left spacing with the asciiart.
            Write-Host (" " * 40) -NoNewline;
        }
        else {
            Write-Host $AsciiArt[$line] -ForegroundColor Cyan -NoNewline;
        }

        Write-Host $LineToTitleMappings[$line] -ForegroundColor Red -NoNewline;

        if ($line -eq 0) {
            $SplittedUserInfo = $SystemInfoCollection[$line].Split("@");

            Write-Host $SplittedUserInfo[0] -ForegroundColor Red -NoNewline;
            Write-Host "@" -NoNewline;
            Write-Host $SplittedUserInfo[1] -ForegroundColor Red;
        }
        elseif ($SystemInfoCollection[$line] -like '*:*') {
            $SplittedDiskInfo = $SystemInfoCollection[$line].Split(":");

            Write-Host ("Disk ", $SplittedDiskInfo[0], ":") -Separator "" -ForegroundColor Red -NoNewline;
            Write-Host $SplittedDiskInfo[1];
        }
        else {
            Write-Host $SystemInfoCollection[$line];
        }
    }
}
