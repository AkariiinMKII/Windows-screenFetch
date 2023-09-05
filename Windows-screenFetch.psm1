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
        [Alias("Logo")]
        [string] $Distro,
        [Parameter(Mandatory = $false, Position = 1)]
        [switch] $Help,
        [Parameter(Mandatory = $false, Position = 2)]
        [switch] $Version
    )

    if ($Help) {
        $HelpInfo = @(
            @{Parameter="screenFetch            "; Description="Print system information with distribution logo."}
            @{Parameter=""; Description=""}
            @{Parameter="    -Distro <String>"; Description="Specify the ASCII logo shown in left side."}
            @{Parameter=""; Description="Currently support the logo of Windows and macOS,"}
            @{Parameter=""; Description="for Windows 10 logo, use 'win10', 'windows10',"}
            @{Parameter=""; Description="for Windows 11 logo, use 'win11', 'windows11',"}
            @{Parameter=""; Description="for Windows XP logo, use 'winxp', 'windowsxp', 'xp',"}
            @{Parameter=""; Description="for macOS logo, use 'mac', 'macos', 'osx', 'apple'."}
            @{Parameter=""; Description=""}
            @{Parameter="    -Help"; Description="Print help info."}
            @{Parameter=""; Description=""}
            @{Parameter="    -Version"; Description="Print version info."}
            @{Parameter=""; Description=""}
            @{Parameter="GitHub repository page:"; Description="https://github.com/AkariiinMKII/Windows-screenFetch"}
        )
        ForEach ($lineHelpInfo in $HelpInfo) {
            New-Object PSObject | Add-Member -NotePropertyMembers $lineHelpInfo -PassThru
        }

        Return $HelpInfo | Format-Table -HideTableHeaders
    }

    if ($Version) {
        $VersionInfo = (Get-Module -Name Windows-screenFetch | Select-Object Version).Version
        Return "Windows-screenFetch $VersionInfo"
    }

    $Win10Distro = @("win10", "windows10", "win 10", "windows 10")
    $Win11Distro = @("win11", "windows11", "win 11", "windows 11")
    $WinXPDistro = @("winxp", "windowsxp", "win xp", "windows xp", "xp")
    $MacDistro = @("mac", "macos", "osx", "apple")

    switch ($Distro) {
        {$Win10Distro -contains $_} {$AsciiArt = . New-Win10Logo; Break}
        {$Win11Distro -contains $_} {$AsciiArt = . New-Win11Logo; Break}
        {$WinXPDistro -contains $_} {$AsciiArt = . New-WinXPLogo; Break}
        {$MacDistro -contains $_} {$AsciiArt = . New-MacLogo; Break}
        default {
            $DetectOS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
            if ($DetectOS -match '10') {
                $AsciiArt = . New-Win10Logo; Break
            } else {
                $AsciiArt = . New-Win11Logo; Break
            }
        }
    }

    $SystemInfoCollection = . Get-SystemSpecifications
    $LineToTitleMappings = . Get-LineToTitleMappings

    # Iterate over all lines from the SystemInfoCollection to display all information
    $numLines = (($SystemInfoCollection.Count, $AsciiArt.Count) | Measure-Object -Maximum).Maximum
    for ($line = 0; $line -lt $numLines; $line++) {
        if ($AsciiArt[$line].Length -eq 0) {
            # Write some whitespaces to sync the left spacing with the asciiart.
            Write-Host (" " * 40) -NoNewline
        } else {
            Write-Host $AsciiArt[$line] -ForegroundColor Cyan -NoNewline
        }

        $contentLine = ($LineToTitleMappings[$line], $SystemInfoCollection[$line]) -join("")

        $Regex = [regex] "\<in(\w+)\>(.+?)\<\/in\w+\>"
        if ($contentLine.Length -gt 0) {
            $captureLine = $Regex.Matches($contentLine)
            ForEach ($contentMatch in $captureLine) {
                if ($contentMatch.Groups[1].Value -eq "Default") {
                    Write-Host $contentMatch.Groups[2].Value -NoNewline
                } else {
                    Write-Host $contentMatch.Groups[2].Value -ForegroundColor $contentMatch.Groups[1].Value -NoNewline
                }
            }
        }
        
        Write-Host ""
    }
}

Set-Alias Windows-screenFetch screenFetch
