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
        $groupHelpInfo = @(
            @{ Parameter = "screenFetch            "; Description = "Print system information with distribution logo." }
            @{ Parameter = ""; Description = "" }
            @{ Parameter = "    -Distro <String>"; Description = "Specify the ASCII logo shown in left side." }
            @{ Parameter = ""; Description = "Currently support the logo of Windows and macOS." }
            @{ Parameter = ""; Description = "for Windows 10 logo, use 'win10', 'windows10';" }
            @{ Parameter = ""; Description = "for Windows 11 logo, use 'win11', 'windows11';" }
            @{ Parameter = ""; Description = "for Windows XP logo, use 'winxp', 'windowsxp', 'xp';" }
            @{ Parameter = ""; Description = "for macOS logo, use 'mac', 'macos', 'osx', 'apple'." }
            @{ Parameter = ""; Description = "" }
            @{ Parameter = "    -Help"; Description = "Print help info." }
            @{ Parameter = ""; Description = "" }
            @{ Parameter = "    -Version"; Description = "Print version info." }
            @{ Parameter = ""; Description = "" }
            @{ Parameter = "GitHub repository page:"; Description = "https://github.com/AkariiinMKII/Windows-screenFetch" }
        )

        $HelpInfo = ForEach ($lineHelpInfo in $groupHelpInfo) {
            New-Object PSObject | Add-Member -NotePropertyMembers $lineHelpInfo -PassThru
        }

        Return $HelpInfo | Format-Table -HideTableHeaders
    }

    if ($Version) {
        $VersionInfo = (Get-Module -Name Windows-screenFetch | Select-Object -Property Version).Version

        Return "Windows-screenFetch $VersionInfo"
    }

    $Win10Distro = @("win10", "windows10", "win 10", "windows 10")
    $Win11Distro = @("win11", "windows11", "win 11", "windows 11")
    $WinXPDistro = @("winxp", "windowsxp", "win xp", "windows xp", "xp")
    $MacDistro = @("mac", "macos", "osx", "apple")

    switch ($Distro) {
        { $Win10Distro -contains $_ } { $AsciiArt = . New-Win10Logo; Break }
        { $Win11Distro -contains $_ } { $AsciiArt = . New-Win11Logo; Break }
        { $WinXPDistro -contains $_ } { $AsciiArt = . New-WinXPLogo; Break }
        { $MacDistro -contains $_ } { $AsciiArt = . New-MacLogo; Break }
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

    $Regex = [regex] "\<\/(\w*)::(.+?)\/\>"
    $ColorStamp = @(
        "Black", "DarkRed", "DarkGreen", "DarkYellow", "DarkBlue", "DarkMagenta", "DarkCyan", "Gray",
        "DarkGray", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"
    )

    # Iterate over all lines from the SystemInfoCollection to display all information
    $totalLines = ((($SystemInfoCollection.Count + 2), $AsciiArt.Count) | Measure-Object -Maximum).Maximum
    ForEach ($numLine in 0..$totalLines) {
        if (0 -eq $AsciiArt[$numLine].Length) {
            # Write some whitespaces to sync the left spacing with the AsciiArt.
            Write-Host (" " * 40) -NoNewline
        } else {
            Write-Host $AsciiArt[$numLine] -ForegroundColor Cyan -NoNewline
        }

        $contentLine = ($LineToTitleMappings[$numLine], $SystemInfoCollection[$numLine]) -join("")

        if ($contentLine.Length -gt 0) {
            $contentRegexMatch = $Regex.Matches($contentLine)
            ForEach ($contentCaptured in $contentRegexMatch) {
                if ($ColorStamp -contains $contentCaptured.Groups[1].Value) {
                    Write-Host $contentCaptured.Groups[2].Value -ForegroundColor $contentCaptured.Groups[1].Value -NoNewline
                } else {
                    Write-Host $contentCaptured.Groups[2].Value -NoNewline
                }
            }
        }

        if (($SystemInfoCollection.Count + 1) -eq $numLine) {
            ForEach ($numColor in 0..7) {
                Write-Host "   " -BackgroundColor $ColorStamp[$numColor] -NoNewline
            }
        }

        if (($SystemInfoCollection.Count + 2) -eq $numLine) {
            ForEach ($numColor in 8..15) {
                Write-Host "   " -BackgroundColor $ColorStamp[$numColor] -NoNewline
            }
        }

        Write-Host ""
    }
}

Set-Alias Windows-screenFetch screenFetch
