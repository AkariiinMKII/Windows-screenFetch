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
    $Monitors = Get-Monitors
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
        $Monitors,
        $NIC,
        $RAM

    ForEach ($Disk in $Disks) {
        [void]$SystemInfoCollection.Add(($(Format-screenFetchData -Data "Disk " -Color Red), $Disk) -join(""))
    }

    Return $SystemInfoCollection
}

Function Get-LineToTitleMappings() {
    $TitleMappings = @{
        0 = ""
        1 = ""
        2 = Format-screenFetchData -Data "OS: " -Color Red
        3 = Format-screenFetchData -Data "Version: " -Color Red
        4 = Format-screenFetchData -Data "Uptime: " -Color Red
        5 = Format-screenFetchData -Data "Shell: " -Color Red
        6 = Format-screenFetchData -Data "Motherboard: " -Color Red
        7 = Format-screenFetchData -Data "CPU: " -Color Red
        8 = Format-screenFetchData -Data "GPU: " -Color Red
        9 = Format-screenFetchData -Data "Monitor: " -Color Red
        10 = Format-screenFetchData -Data "NIC: " -Color Red
        11 = Format-screenFetchData -Data "RAM: " -Color Red
    }

    Return $TitleMappings
}

Function Get-UserInformation() {
    Return ($(Format-screenFetchData -Data $env:USERNAME -Color Red), $(Format-screenFetchData -Data "@"), $(Format-screenFetchData -Data $([System.Net.Dns]::GetHostName()) -Color Red)) -join("")
}

Function Get-DividingLine() {
    $generateDividingLine = "-" * ($env:USERNAME.Length + [System.Net.Dns]::GetHostName().Length + 1)
    Return $(Format-screenFetchData -Data $generateDividingLine)
}

Function Get-OS() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $infoOS = ($FetchOS.Caption, $FetchOS.OSArchitecture) -join(" ")

    Return $(Format-screenFetchData -Data $infoOS)
}

Function Get-Version() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $infoOSVersion = $FetchOS.Version

    Return $(Format-screenFetchData -Data $infoOSVersion)
}

Function Get-SystemUptime() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $FetchOS
    )
    $fetchUptime = (([DateTime]$FetchOS.LocalDateTime) - ([DateTime]$FetchOS.LastBootUpTime))
    $infoUptime = ($fetchUptime.Days.ToString(), "d ", $fetchUptime.Hours.ToString(), "h ", $fetchUptime.Minutes.ToString(), "m ", $fetchUptime.Seconds.ToString(), "s") -join("")

    Return $(Format-screenFetchData -Data $infoUptime)
}

Function Get-Shell() {
    $infoPSVersion = ("PowerShell", $PSVersionTable.PSVersion.ToString()) -join(" ")

    Return $(Format-screenFetchData -Data $infoPSVersion)
}

Function Get-Mobo() {
    $fetchBaseBoard = Get-CimInstance -ClassName Win32_BaseBoard
    $infoMobo = ($fetchBaseBoard.Manufacturer, $fetchBaseBoard.Product) -join(" ")

    Return $(Format-screenFetchData -Data $infoMobo)
}

Function Get-CPU() {
    $infoCPU = (Get-CimInstance -ClassName Win32_Processor | ForEach-Object { ($_.Name).Trim(), $(Format-ClockSpeed -Speed $_.MaxClockSpeed) -join(" @ ") }) -join("; ")

    Return $(Format-screenFetchData -Data $infoCPU)
}

Function Get-GPU() {
    $fetchVC = Get-CimInstance -ClassName Win32_VideoController
    $infoGPU = ($FetchVC | Where-Object { 'OK' -eq $_.Status } | ForEach-Object { ($_.Name).Trim() }) -join("; ")

    Return $(Format-screenFetchData -Data $infoGPU)
}

Function Get-Monitors() {
    $infoMonitors = @()

    $fetchMonitorID = Get-CimInstance -Namespace "root\wmi" -Class WmiMonitorID -ErrorAction SilentlyContinue
    $fetchResolutions = Get-CimInstance -Namespace "root\wmi" -Class WmiMonitorListedSupportedSourceModes -ErrorAction SilentlyContinue

    ForEach ($selectMonitor in $fetchMonitorID) {
        $selectInstanceName = $selectMonitor.InstanceName

        if ([System.Array] -eq ($selectMonitor.UserFriendlyName.GetType()).BaseType) {
            $MonitorName = ($selectMonitor.UserFriendlyName -ne 0 | ForEach-Object { [char]$_ }) -join("")
        } else {
            $MonitorName = "Unknown"
        }

        $pairResolutions = $fetchResolutions | Where-Object { $selectInstanceName -eq $_.InstanceName }
        $supportedResolutions = $pairResolutions.MonitorSourceModes | Select-Object HorizontalActivePixels, VerticalActivePixels, VerticalRefreshRateNumerator, VerticalRefreshRateDenominator
        $maxResolution = $supportedResolutions | Sort-Object -Property { $_.HorizontalActivePixels * $_.VerticalActivePixels } | Select-Object -Last 1

        $HorRes = $maxResolution.HorizontalActivePixels
        $VerRes = $maxResolution.VerticalActivePixels
        $RefRate = "{0:F0}" -f ($maxResolution.VerticalRefreshRateNumerator / $maxResolution.VerticalRefreshRateDenominator)

        $infoResolution = ($HorRes.ToString(), " x ", $VerRes.ToString(), " @ ", $RefRate.ToString(), "Hz") -join("")
        $infoMonitor = ($MonitorName, " (", $infoResolution, ")") -join("")

        $infoMonitors = ($infoMonitors, $infoMonitor | Where-Object { '' -ne $_ }) -join("; ")
    }

    if (-not $infoMonitors) {
        $infoMonitors = "None"
    }

    Return $(Format-screenFetchData -Data $infoMonitors)
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

    Return $(Format-screenFetchData -Data $infoNIC)
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
    $UsedRamPercent = ("(", $UsedRamPercentValue.ToString(), "%)") -join("")

    $TotalRam = Format-StorageSize -Size $TotalRamValue -isRAM
    $UsedRam = Format-StorageSize -Size $UsedRamValue -isRAM

    $infoRAM = ($UsedRam, "/", $TotalRam, $UsedRamPercent) -join(" ")

    Return $(Format-screenFetchData -Data $infoRAM)
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
            $UsedDiskPercent = ("(", $UsedDiskPercentValue.ToString(), "%)") -join("")

            $DiskSize = Format-StorageSize -Size $DiskSizeValue
            $UsedDiskSize = Format-StorageSize -Size $UsedDiskSizeValue

            $DiskStatus = ($UsedDiskSize, "/", $DiskSize, $UsedDiskPercent) -join(" ")
        } else {
            $DiskStatus = "Empty"
        }

        $FormattedDisk = ($(Format-screenFetchData -Data $selectDisk.DeviceId.ToString() -Color Red), $(Format-screenFetchData -Data " $DiskStatus")) -join("")

        switch ($selectDisk.DriveType) {
            0 { $FormattedDisk = ($FormattedDisk, $(Format-screenFetchData -Data " Unknown" -Color DarkGray)) -join("") }
            1 { $FormattedDisk = ($FormattedDisk, $(Format-screenFetchData -Data " No Root Directory" -Color DarkGray)) -join("") }
            2 { $FormattedDisk = ($FormattedDisk, $(Format-screenFetchData -Data " Removable Disk" -Color DarkGray)) -join("") }
            4 { $FormattedDisk = ($FormattedDisk, $(Format-screenFetchData -Data " Network Drive" -Color DarkGray)) -join("") }
            5 { $FormattedDisk = ($FormattedDisk, $(Format-screenFetchData -Data " Compact Disc" -Color DarkGray)) -join("") }
            6 { $FormattedDisk = ($FormattedDisk, $(Format-screenFetchData -Data " RAM Disk" -Color DarkGray)) -join("") }
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
    if ($Speed -ge 1000) {
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
        { $_ -ge 1PB } {
            $calculateSize = "{0:F2}" -f ($Size / 1PB)
            Return ($calculateSize.ToString(), "PiB") -join("")
        }
        { $_ -ge 100TB } {
            $calculateSize = "{0:F0}" -f ($Size / 1TB)
            Return ($calculateSize.ToString(), "TiB") -join("")
        }
        { $_ -ge 10TB } {
            $calculateSize = "{0:F1}" -f ($Size / 1TB)
            Return ($calculateSize.ToString(), "TiB") -join("")
        }
        { $_ -ge 1TB } {
            $calculateSize = "{0:F2}" -f ($Size / 1TB)
            Return ($calculateSize.ToString(), "TiB") -join("")
        }
        { ($_ -ge 100GB) -and (-not $isRAM) } {
            $calculateSize = "{0:F0}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { $_ -ge 10GB } {
            $calculateSize = "{0:F1}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { ($_ -ge 1GB) -and (-not $isRAM) } {
            $calculateSize = "{0:F2}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { $_ -ge 1GB } {
            $calculateSize = "{0:F1}" -f ($Size / 1GB)
            Return ($calculateSize.ToString(), "GiB") -join("")
        }
        { $_ -ge 1MB } {
            $calculateSize = "{0:F0}" -f ($Size / 1MB)
            Return ($calculateSize.ToString(), "MiB") -join("")
        }
        { $_ -ge 1KB } {
            $calculateSize = "{0:F0}" -f ($Size / 1KB)
            Return ($calculateSize.ToString(), "KiB") -join("")
        }
        default {
            Return ($Size.ToString(), "Bytes") -join("")
        }
    }
}

Function Format-screenFetchData() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Data,
        [Parameter(Mandatory = $false, Position = 1)]
        [string] $Color
    )
    $ColorStamp = @(
        "Black", "DarkRed", "DarkGreen", "DarkYellow", "DarkBlue", "DarkMagenta", "DarkCyan", "Gray",
        "DarkGray", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"
    )

    if ($Color -and $ColorStamp -contains $Color) {
        $Data = ("</$Color::", $Data, "/>") -join("")
    } else {
        $Data = ("</::", $Data, "/>") -join("")
    }

    Return $Data
}