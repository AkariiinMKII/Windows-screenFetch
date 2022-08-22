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

    $AsciiArt = . Get-WindowsArt;

    if ($Distro) {
        if (($Distro -match 'mac') -or ($Distro -match 'osx') -or ($Distro -match 'apple')) {
            $AsciiArt = . Get-MacArt;
        }
        if (($Distro -match 'oldwin') -or ($Distro -match 'win.*xp')) {
            $AsciiArt = . Get-OldWindowsArt;
        }
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
