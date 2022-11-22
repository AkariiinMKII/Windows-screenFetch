Function screenFetch() {
    <#
    .SYNOPSIS
        A Powershell port of bash/unix screenFetch.

    .PARAMETER Distro
        Select an alternative logo to show.

    .PARAMETER Help
        Print help info.

    .PARAMETER Version
        Print version info.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $Distro,
        [Parameter(Mandatory = $false, Position = 1)]
        [switch] $Help,
        [Parameter(Mandatory = $false, Position = 2)]
        [switch] $Version
    )

    $HelpInfo = @(
        @{Parameter="screenFetch [<Parameters>]"; Description=""}
        @{Parameter="    -Distro <String>"; Description="Specify the ASCII logo shown."}
        @{Parameter=""; Description="Currently support the logo of Mac and Windows XP,"}
        @{Parameter=""; Description="for Mac logo, use 'mac', 'macos', 'osx', 'apple',"}
        @{Parameter=""; Description="for Windows XP logo, use 'winxp', 'windowsxp', 'xp'."}
        @{Parameter="    -Help"; Description="Print help info."}
        @{Parameter="    -Version"; Description="Print version info."}
    ) | ForEach-Object { New-Object PSObject | Add-Member -NotePropertyMembers $_ -PassThru }

    if ($Help) {
        Return $HelpInfo | Format-Table -HideTableHeaders
    }

    if ($Version) {
        $VersionInfo = (Get-Module -Name Windows-screenFetch | Select-Object Version).Version
        Return "Windows-screenFetch $VersionInfo"
    }

    $MacDistro = @("mac", "macos", "osx", "apple")
    $WinXPDistro = @("winxp", "windowsxp", "xp", "win xp", "windows xp")

    switch ($Distro) {
        {$MacDistro -contains $_} {$AsciiArt = . New-MacLogo; Break}
        {$WinXPDistro -contains $_} {$AsciiArt = . New-WinXPLogo; Break}
        default {$AsciiArt = . New-WinLogo; Break}
    }

    $SystemInfoCollection = . Get-SystemSpecifications
    $LineToTitleMappings = . Get-LineToTitleMappings

    # Iterate over all lines from the SystemInfoCollection to display all information
    $NumLines = (($SystemInfoCollection.Count, $AsciiArt.Count) | Measure-Object -Maximum).Maximum
    for ($line = 0; $line -lt $NumLines; $line++) {
        if (($AsciiArt[$line].Length) -eq 0) {
            # Write some whitespaces to sync the left spacing with the asciiart.
            Write-Host (" " * 40) -NoNewline
        }
        else {
            Write-Host $AsciiArt[$line] -ForegroundColor Cyan -NoNewline
        }

        Write-Host $LineToTitleMappings[$line] -ForegroundColor Red -NoNewline

        if ($line -eq 0) {
            $SplittedUserInfo = $SystemInfoCollection[$line].Split("@")

            Write-Host $SplittedUserInfo[0] -ForegroundColor Red -NoNewline
            Write-Host "@" -NoNewline
            Write-Host $SplittedUserInfo[1] -ForegroundColor Red
        }
        elseif ($SystemInfoCollection[$line] -like '*:*') {
            $SplittedDiskInfo = $SystemInfoCollection[$line].Split(":")

            Write-Host ("Disk ", $SplittedDiskInfo[0], ":") -Separator "" -ForegroundColor Red -NoNewline
            Write-Host $SplittedDiskInfo[1]
        }
        else {
            Write-Host $SystemInfoCollection[$line]
        }
    }
}

Set-Alias Windows-screenFetch screenFetch
