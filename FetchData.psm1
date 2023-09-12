Function Get-SystemSpecifications() {
    $fetchOS = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, OSArchitecture, Version, LocalDateTime, LastBootUpTime, FreePhysicalMemory

    $UserInfo = Get-UserInformation
    $DividingLine = Get-DividingLine
    $OS = Get-OS -FetchOS $fetchOS
    $Version = Get-Version -FetchOS $fetchOS
    $Uptime = Get-SystemUptime -FetchOS $fetchOS
    $Shell = Get-Shell
    $Motherboard = Get-Mobo
    $CPU = Get-CPU
    $GPU = Get-GPU
    $Displays = Get-Displays
    $NIC = Get-NIC
    $RAM = Get-RAM -FetchOS $fetchOS
    $Disks = Get-Disks

    [System.Collections.ArrayList] $SystemInfoCollection =
        $UserInfo,
        $DividingLine,
        $OS,
        $Version,
        $Uptime,
        $Shell,
        $Motherboard,
        $CPU,
        $GPU,
        $Displays,
        $NIC,
        $RAM

    ForEach ($Disk in $Disks) {
        [void]$SystemInfoCollection.Add(("</Red::Disk />", $Disk) -join(""))
    }

    Return $SystemInfoCollection
}

Function Get-LineToTitleMappings() {
    $TitleMappings = @{
        0 = ""
        1 = ""
        2 = "</Red::OS: />"
        3 = "</Red::Version: />"
        4 = "</Red::Uptime: />"
        5 = "</Red::Shell: />"
        6 = "</Red::Motherboard: />"
        7 = "</Red::CPU: />"
        8 = "</Red::GPU: />"
        9 = "</Red::Display: />"
        10 = "</Red::NIC: />"
        11 = "</Red::RAM: />"
    }

    Return $TitleMappings
}

Function Get-UserInformation() {
    Return ("</Red::", $env:USERNAME, "/>", "</::@/>", "</Red::", [System.Net.Dns]::GetHostName(), "/>") -join("")
}

Function Get-DividingLine() {
    $generateDividingLine = "-" * ($env:USERNAME.Length + [System.Net.Dns]::GetHostName().Length + 1)

    Return ("</::", $generateDividingLine, "/>") -join("")
}

Function Get-OS() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $infoOS = ($FetchOS.Caption, $FetchOS.OSArchitecture) -join(" ")

    Return ("</::", $infoOS, "/>") -join("")
}

Function Get-Version() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $infoOSVersion = $FetchOS.Version

    Return ("</::", $infoOSVersion, "/>") -join("")
}

Function Get-SystemUptime() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $fetchUptime = (([DateTime]$FetchOS.LocalDateTime) - ([DateTime]$FetchOS.LastBootUpTime))
    $infoUptime = ($fetchUptime.Days.ToString(), "d ", $fetchUptime.Hours.ToString(), "h ", $fetchUptime.Minutes.ToString(), "m ", $fetchUptime.Seconds.ToString(), "s") -join("")

    Return ("</::", $infoUptime, "/>") -join("")
}

Function Get-Shell() {
    $infoPSVersion = ("PowerShell", $PSVersionTable.PSVersion.ToString()) -join(" ")

    Return ("</::", $infoPSVersion, "/>") -join("")
}

Function Get-Mobo() {
    $fetchBaseBoard = Get-CimInstance -ClassName Win32_BaseBoard
    $infoMobo = ($fetchBaseBoard.Manufacturer, $fetchBaseBoard.Product) -join(" ")

    Return ("</::", $infoMobo, "/>") -join("")
}

Function Get-CPU() {
    $infoCPU = (Get-CimInstance -ClassName Win32_Processor | ForEach-Object { ($_.Name).Trim(), $(Format-ClockSpeed -Speed $_.MaxClockSpeed) -join(" @ ") }) -join("; ")

    Return ("</::", $infoCPU, "/>") -join("")
}

Function Get-GPU() {
    $fetchVC = Get-CimInstance -ClassName Win32_VideoController
    $infoGPU = ($FetchVC | Where-Object { 'OK' -eq $_.Status } | ForEach-Object { ($_.Name).Trim() }) -join("; ")

    Return ("</::", $infoGPU, "/>") -join("")
}

Function Get-Displays() {
    $infoDisplays = New-Object System.Collections.Generic.List[System.Object]

    $fetchMonitors = Get-CimInstance -Namespace "root\wmi" -Class WmiMonitorListedSupportedSourceModes -ErrorAction SilentlyContinue

    ForEach ($selectMonitor in $fetchMonitors) {
        $supportedResolutions = $selectMonitor.MonitorSourceModes | Select-Object HorizontalActivePixels, VerticalActivePixels, VerticalRefreshRateNumerator, VerticalRefreshRateDenominator
        $maxResolution = $supportedResolutions | Sort-Object -Property { $_.HorizontalActivePixels * $_.VerticalActivePixels } | Select-Object -Last 1

        $HorRes = $maxResolution.HorizontalActivePixels
        $VerRes = $maxResolution.VerticalActivePixels
        $RefRate = "{0:F0}" -f ($maxResolution.VerticalRefreshRateNumerator / $maxResolution.VerticalRefreshRateDenominator)

        if ($HorRes -and $VerRes -and $RefRate) {
            $Display = ($HorRes.ToString(), " x ", $VerRes.ToString(), " @ ", $RefRate.ToString(), "Hz") -join("")

            $infoDisplays = ($infoDisplays, $Display | Where-Object { '' -ne $_ }) -join("; ")
        }
    }

    if (-not $infoDisplays) {
        $infoDisplays = "None"
    }

    Return ("</::", $infoDisplays, "/>") -join("")
}

Function Get-NIC() {
    $fetchAdapters = Get-NetAdapter -Physical | Where-Object { 'Up' -eq $_.Status }
    $Adapters = $fetchAdapters | ForEach-Object {
        $InterfaceDesc = ($_.InterfaceDescription).Trim()
        $AdapterName = ($_.Name).Trim()
        $AdapterSpeed = ($_.LinkSpeed).Trim().Split(" ") -join("")
        ($InterfaceDesc, " (", $AdapterName, " @ ", $AdapterSpeed, ")") -join("")
    }

    $infoNIC = $Adapters -join("; ")

    Return ("</::", $infoNIC, "/>") -join("")
}

Function Get-RAM() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $FreeRamValue = $FetchOS.FreePhysicalMemory * 1KB
    $TotalRamValue = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory

    $UsedRamValue = $TotalRamValue - $FreeRamValue
    $UsedRamPercentValue = "{0:F0}" -f (($UsedRamValue / $TotalRamValue) * 100)
    $UsedRamPercent = ("(", $UsedRamPercentValue.ToString(), "% used)") -join("")

    $TotalRam = Format-StorageSize -Size $TotalRamValue -isRAM
    $UsedRam = Format-StorageSize -Size $UsedRamValue -isRAM

    $infoRAM = ($UsedRam, "/", $TotalRam, $UsedRamPercent) -join(" ")

    Return ("</::", $infoRAM, "/>") -join("")
}

Function Get-Disks() {
    $infoDisks = New-Object System.Collections.Generic.List[System.Object]

    $fetchDisks = Get-CimInstance -ClassName Win32_LogicalDisk

    ForEach ($selectDisk in $fetchDisks) {
        $DiskSizeValue = $selectDisk.Size
        $FreeDiskSizeValue = $selectDisk.FreeSpace

        if ($DiskSizeValue -gt 0) {
            $UsedDiskSizeValue = $DiskSizeValue - $FreeDiskSizeValue
            $UsedDiskPercentValue = "{0:F0}" -f (($UsedDiskSizeValue / $DiskSizeValue) * 100)
            $UsedDiskPercent = ("(", $UsedDiskPercentValue.ToString(), "% used)") -join("")

            $DiskSize = Format-StorageSize -Size $DiskSizeValue
            $UsedDiskSize = Format-StorageSize -Size $UsedDiskSizeValue

            $DiskStatus = ($UsedDiskSize, "/", $DiskSize, $UsedDiskPercent) -join(" ")
        } else {
            $DiskStatus = "Empty"
        }

        $FormattedDisk = ("</Red::", $selectDisk.DeviceId.ToString(), " />", "</::", $DiskStatus, "/>") -join("")

        switch ($selectDisk.DriveType) {
            0 { $FormattedDisk = ($FormattedDisk, "</DarkGray:: Unknown/>") -join("") }
            1 { $FormattedDisk = ($FormattedDisk, "</DarkGray:: No Root Directory/>") -join("") }
            2 { $FormattedDisk = ($FormattedDisk, "</DarkGray:: Removable Disk/>") -join("") }
            4 { $FormattedDisk = ($FormattedDisk, "</DarkGray:: Network Drive/>") -join("") }
            5 { $FormattedDisk = ($FormattedDisk, "</DarkGray:: Compact Disc/>") -join("") }
            6 { $FormattedDisk = ($FormattedDisk, "</DarkGray:: RAM Disk/>") -join("") }
        }

        $infoDisks.Add($FormattedDisk)
    }

    Return $infoDisks
}

Function Format-ClockSpeed() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int64] $Speed
    )
    if ($Speed -gt 1000) {
        $FormatSpeedValue = "{0:F1}" -f ($Speed / 1000)
        Return ($FormatSpeedValue.ToString(), "GHz") -join("")
    } else {
        Return ($Speed.ToString(), "MHz") -join("")
    }
}

Function Format-StorageSize() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int64] $Size,
        [Parameter(Mandatory = $false, Position = 1)]
        [switch] $isRAM
    )
    switch ($Size) {
        { $_ -gt 1PB } {
            $calculateSize = "{0:F2}" -f ($Size / 1PB)
            Return ($calculateSize.ToString(), "PiB") -join("")
        }
        { $_ -gt 100TB } {
            $calculateSize = "{0:F0}" -f ($Size / 1TB)
            Return ($calculateSize.ToString(), "TiB") -join("")
        }
        { $_ -gt 10TB } {
            $calculateSize = "{0:F1}" -f ($Size / 1TB)
            Return ($calculateSize.ToString(), "TiB") -join("")
        }
        { $_ -gt 1TB } {
            $calculateSize = "{0:F2}" -f ($Size / 1TB)
            Return ($calculateSize.ToString(), "TiB") -join("")
        }
        { ($_ -gt 100GB) -and (-not $isRAM) } {
            $calculateSize = "{0:F0}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { $_ -gt 10GB } {
            $calculateSize = "{0:F1}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { ($_ -gt 1GB) -and (-not $isRAM) } {
            $calculateSize = "{0:F2}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { $_ -gt 1GB } {
            $calculateSize = "{0:F1}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { $_ -gt 1MB } {
            $calculateSize = "{0:F0}" -f ($Size / 1MB)
            Return ($calculateSize.ToString(), "MiB") -join("")
        }
        { $_ -gt 1KB } {
            $calculateSize = "{0:F0}" -f ($Size / 1KB)
            Return ($calculateSize.ToString(), "KiB") -join("")
        }
        default {
            Return ($Size.ToString(), "Bytes") -join("")
        }
    }
}
