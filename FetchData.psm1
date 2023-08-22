Function Get-SystemSpecifications() {

    $UserInfo = Get-UserInformation
    $DividingLine = Get-DividingLine
    $OS = Get-OS
    $Version = Get-Version
    $Uptime = Get-SystemUptime
    $Shell = Get-Shell
    $Motherboard = Get-Mobo
    $CPU = Get-CPU
    $GPU = Get-GPU
    $Displays = Get-Displays
    $NIC = Get-NIC
    $RAM = Get-RAM
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

    foreach ($Disk in $Disks) {
        [void]$SystemInfoCollection.Add($Disk)
    }

    return $SystemInfoCollection
}

Function Get-LineToTitleMappings() {
    $TitleMappings = @{
        0 = ""
        1 = ""
        2 = "OS: "
        3 = "Version: "
        4 = "Uptime: "
        5 = "Shell: "
        6 = "Motherboard: "
        7 = "CPU: "
        8 = "GPU: "
        9 = "Display: "
        10 = "NIC: "
        11 = "RAM: "
    }

    return $TitleMappings
}

Function Get-UserInformation() {
    return ($env:USERNAME, "@", [System.Net.Dns]::GetHostName()) -join("")
}

Function Get-DividingLine() {
    return "-" * $UserInfo.Length
}

Function Get-OS() {
    $GCIOS = Get-CimInstance -ClassName Win32_OperatingSystem
    return ($GCIOS.Caption, $GCIOS.OSArchitecture) -join(" ")
}

Function Get-Version() {
    return (Get-CimInstance -ClassName Win32_OperatingSystem).Version
}

Function Get-SystemUptime() {
    $GCIOS = Get-CimInstance -ClassName Win32_OperatingSystem
    $Uptime = (([DateTime]$GCIOS.LocalDateTime) - ([DateTime]$GCIOS.LastBootUpTime))
    $FormattedUptime = ($Uptime.Days.ToString(), "d ", $Uptime.Hours.ToString(), "h ", $Uptime.Minutes.ToString(), "m ", $Uptime.Seconds.ToString(), "s") -join("")

    return $FormattedUptime
}

Function Get-Shell() {
    return ("PowerShell", $PSVersionTable.PSVersion.ToString()) -join(" ")
}

Function Get-Displays() {
    Add-Type -AssemblyName System.Windows.Forms
    $AllScreens = [System.Windows.Forms.Screen]::AllScreens

    $Monitors = $AllScreens | ForEach-Object {
        $MonitorInfo = New-Object PSObject
        $MonitorInfo | Add-Member -MemberType NoteProperty -Name ScreenWidth -Value ($_.Bounds).Width
        $MonitorInfo | Add-Member -MemberType NoteProperty -Name ScreenHeight -Value ($_.Bounds).Height
        $MonitorInfo | Add-Member -MemberType NoteProperty -Name Primary -Value $_.Primary
        $MonitorInfo
    }

    $Displays = New-Object System.Collections.Generic.List[System.Object]

    $Monitors | Where-Object {$_.Primary} | ForEach-Object {
        $Display = ($_.ScreenWidth.ToString(), " x ", $_.ScreenHeight.ToString(), " (Primary)") -join("")
        if (-not $Displays) {
            $Displays = $Display
        }
        else {
            $Displays = ($Displays, $Display) -join("; ")
        }
    }

    $Monitors | Where-Object {-not $_.Primary} | ForEach-Object {
        $Display = ($_.ScreenWidth.ToString(), " x ", $_.ScreenHeight.ToString()) -join("")
        if (-not $Displays) {
            $Displays = $Display
        }
        else {
            $Displays = ($Displays, $Display) -join("; ")
        }
    }

    if ($Displays) {
        return $Displays
    }
    else {
        return "NONE"
    }
}

Function Get-CPU() {
    return (Get-CimInstance -ClassName Win32_Processor -Property Name | ForEach-Object {($_.Name).Trim()}) -join("; ")
}

Function Get-GPU() {
    return (Get-CimInstance -ClassName Win32_VideoController | Where-Object {$_.Status -eq 'OK'} | ForEach-Object {($_.Name).Trim()}) -join("; ")
}

Function Get-Mobo() {
    $Motherboard = Get-CimInstance -ClassName Win32_BaseBoard
    return ($Motherboard.Manufacturer, $Motherboard.Product) -join(" ")
}

Function Get-NIC() {
    $AdaptersTable = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"}
    $Adapters = $AdaptersTable | ForEach-Object {
        $InterfaceDesc = ($_.InterfaceDescription).Trim()
        $AdapterName = ($_.Name).Trim()
        $AdapterSpeed = ($_.LinkSpeed).Trim().Split(" ") -join("")
        ($InterfaceDesc, " (", $AdapterName, " @ ", $AdapterSpeed, ")") -join("")
    }

    return $Adapters -join("; ")
}

Function Format-StorageSize() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int64] $Size,
        [Parameter(Mandatory = $false, Position = 1)]
        [switch] $RAM
    )
    switch ($Size) {
        {$_ -gt 1PB} {
            $CalculateSizeValue = "{0:F2}" -f ($Size / 1PB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "PiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 100TB} {
            $CalculateSizeValue = "{0:F0}" -f ($Size / 1TB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "TiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 10TB} {
            $CalculateSizeValue = "{0:F1}" -f ($Size / 1TB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "TiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 1TB} {
            $CalculateSizeValue = "{0:F2}" -f ($Size / 1TB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "TiB") -join("")
            Return $CalculateSize
        }
        {($_ -gt 100GB) -and (-not $RAM)} {
            $CalculateSizeValue = "{0:F0}" -f ($Size / 1GB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "GiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 10GB} {
            $CalculateSizeValue = "{0:F1}" -f ($Size / 1GB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "GiB") -join("")
            Return $CalculateSize
        }
        {($_ -gt 1GB) -and (-not $RAM)} {
            $CalculateSizeValue = "{0:F2}" -f ($Size / 1GB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "GiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 1GB} {
            $CalculateSizeValue = "{0:F1}" -f ($Size / 1GB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "GiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 1MB} {
            $CalculateSizeValue = "{0:F0}" -f ($Size / 1MB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "MiB") -join("")
            Return $CalculateSize
        }
        {$_ -gt 1KB} {
            $CalculateSizeValue = "{0:F0}" -f ($Size / 1KB)
            $CalculateSize = ($CalculateSizeValue.ToString(), "KiB") -join("")
            Return $CalculateSize
        }
        default {
            $CalculateSize = ($Size.ToString(), "Bytes") -join("")
            Return $CalculateSize
        }
    }
}

Function Get-RAM() {
    $FreeRamValue = (Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory * 1KB
    $TotalRamValue = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory

    $UsedRamValue = $TotalRamValue - $FreeRamValue
    $UsedRamPercentValue = "{0:F0}" -f (($UsedRamValue / $TotalRamValue) * 100)
    $UsedRamPercent = ("(", $UsedRamPercentValue.ToString(), "% used)") -join("")

    $TotalRam = Format-StorageSize -Size $TotalRamValue -RAM
    $UsedRam = Format-StorageSize -Size $UsedRamValue -RAM

    return ($UsedRam, "/", $TotalRam, $UsedRamPercent) -join(" ")
}

Function Get-Disks() {
    $FormattedDisks = New-Object System.Collections.Generic.List[System.Object]

    $DiskTable = Get-CimInstance -ClassName Win32_LogicalDisk

    $DiskTable | ForEach-Object {
        $DiskSizeValue = $_.Size
        $FreeDiskSizeValue = $_.FreeSpace

        if ($DiskSizeValue -gt 0) {
            $UsedDiskSizeValue = $DiskSizeValue - $FreeDiskSizeValue
            $UsedDiskPercentValue = "{0:F0}" -f (($UsedDiskSizeValue / $DiskSizeValue) * 100)
            $UsedDiskPercent = ("(", $UsedDiskPercentValue.ToString(), "% used)") -join("")

            $DiskSize = Format-StorageSize -Size $DiskSizeValue
            $UsedDiskSize = Format-StorageSize -Size $UsedDiskSizeValue

            $DiskStatus = ($UsedDiskSize, "/", $DiskSize, $UsedDiskPercent) -join(" ")
        }
        else {
            $DiskStatus = "*Empty"
        }

        $FormattedDisk = ($_.DeviceId.ToString(), $DiskStatus) -join(" ")

        switch ($_.DriveType) {
            2 {$FormattedDisk = ($FormattedDisk, "*Removable disk") -join(" ")}
            4 {$FormattedDisk = ($FormattedDisk, "*Network disk") -join(" ")}
            5 {$FormattedDisk = ($FormattedDisk, "*Compact disk") -join(" ")}
        }

        $FormattedDisks.Add($FormattedDisk)
    }

    return $FormattedDisks
}
