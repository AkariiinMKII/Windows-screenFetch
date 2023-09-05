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

    ForEach ($Disk in $Disks) {
        [void]$SystemInfoCollection.Add(("<inRed>Disk </inRed>", $Disk) -join(""))
    }

    Return $SystemInfoCollection
}

Function Get-LineToTitleMappings() {
    $TitleMappings = @{
        0 = ""
        1 = ""
        2 = "<inRed>OS: </inRed>"
        3 = "<inRed>Version: </inRed>"
        4 = "<inRed>Uptime: </inRed>"
        5 = "<inRed>Shell: </inRed>"
        6 = "<inRed>Motherboard: </inRed>"
        7 = "<inRed>CPU: </inRed>"
        8 = "<inRed>GPU: </inRed>"
        9 = "<inRed>Display: </inRed>"
        10 = "<inRed>NIC: </inRed>"
        11 = "<inRed>RAM: </inRed>"
    }

    Return $TitleMappings
}

Function Get-UserInformation() {
    Return ("<inRed>", $env:USERNAME, "</inRed>", "<inDefault>@</inDefault>", "<inRed>", [System.Net.Dns]::GetHostName(), "</inRed>") -join("")
}

Function Get-DividingLine() {
    $DividingLine = "-" * ($env:USERNAME.Length + [System.Net.Dns]::GetHostName().Length + 1)

    Return ("<inDefault>", $DividingLine, "</inDefault>") -join("")
}

Function Get-OS() {
    $GCIOS = Get-CimInstance -ClassName Win32_OperatingSystem
    $infoOS = ($GCIOS.Caption, $GCIOS.OSArchitecture) -join(" ")

    Return ("<inDefault>", $infoOS, "</inDefault>") -join("")
}

Function Get-Version() {
    $infoOSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version

    Return ("<inDefault>", $infoOSVersion, "</inDefault>") -join("")
}

Function Get-SystemUptime() {
    $GCIOS = Get-CimInstance -ClassName Win32_OperatingSystem
    $Uptime = (([DateTime]$GCIOS.LocalDateTime) - ([DateTime]$GCIOS.LastBootUpTime))
    $infoUptime = ($Uptime.Days.ToString(), "d ", $Uptime.Hours.ToString(), "h ", $Uptime.Minutes.ToString(), "m ", $Uptime.Seconds.ToString(), "s") -join("")

    Return ("<inDefault>", $infoUptime, "</inDefault>") -join("")
}

Function Get-Shell() {
    $infoPSVersion = ("PowerShell", $PSVersionTable.PSVersion.ToString()) -join(" ")

    Return ("<inDefault>", $infoPSVersion, "</inDefault>") -join("")
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
        } else {
            $Displays = ($Displays, $Display) -join("; ")
        }
    }

    $Monitors | Where-Object {-not $_.Primary} | ForEach-Object {
        $Display = ($_.ScreenWidth.ToString(), " x ", $_.ScreenHeight.ToString()) -join("")
        if (-not $Displays) {
            $Displays = $Display
        } else {
            $Displays = ($Displays, $Display) -join("; ")
        }
    }

    if ($Displays) {
        $infoDisplays = $Displays
    } else {
        $infoDisplays = "NONE"
    }

    Return ("<inDefault>", $infoDisplays, "</inDefault>") -join("")
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

Function Get-CPU() {
    $infoCPU = (Get-CimInstance -ClassName Win32_Processor | ForEach-Object {($_.Name).Trim(), $(Format-ClockSpeed -Speed $_.MaxClockSpeed) -join(" @ ")}) -join("; ")

    Return ("<inDefault>", $infoCPU, "</inDefault>") -join("")
}

Function Get-GPU() {
    $infoGPU = (Get-CimInstance -ClassName Win32_VideoController | Where-Object {$_.Status -eq 'OK'} | ForEach-Object {($_.Name).Trim()}) -join("; ")

    Return ("<inDefault>", $infoGPU, "</inDefault>") -join("")
}

Function Get-Mobo() {
    $Motherboard = Get-CimInstance -ClassName Win32_BaseBoard
    $infoMobo = ($Motherboard.Manufacturer, $Motherboard.Product) -join(" ")

    Return ("<inDefault>", $infoMobo, "</inDefault>") -join("")
}

Function Get-NIC() {
    $tableAdapters = Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"}
    $Adapters = $tableAdapters | ForEach-Object {
        $InterfaceDesc = ($_.InterfaceDescription).Trim()
        $AdapterName = ($_.Name).Trim()
        $AdapterSpeed = ($_.LinkSpeed).Trim().Split(" ") -join("")
        ($InterfaceDesc, " (", $AdapterName, " @ ", $AdapterSpeed, ")") -join("")
    }

    $infoNIC = $Adapters -join("; ")

    Return ("<inDefault>", $infoNIC, "</inDefault>") -join("")
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

    $infoRAM = ($UsedRam, "/", $TotalRam, $UsedRamPercent) -join(" ")

    Return ("<inDefault>", $infoRAM, "</inDefault>") -join("")
}

Function Get-Disks() {
    $infoDisks = New-Object System.Collections.Generic.List[System.Object]

    $tableDisks = Get-CimInstance -ClassName Win32_LogicalDisk

    ForEach ($selectDisk in $tableDisks) {
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
            $DiskStatus = "*Empty"
        }

        $FormattedDisk = ("<inRed>", $selectDisk.DeviceId.ToString(), " </inRed>", "<inDefault>", $DiskStatus, "</inDefault>") -join("")

        switch ($selectDisk.DriveType) {
            2 {$FormattedDisk = ($FormattedDisk, "<inDarkGray> Removable disk</inDarkGray>") -join("")}
            4 {$FormattedDisk = ($FormattedDisk, "<inDarkGray> Network disk</inDarkGray>") -join("")}
            5 {$FormattedDisk = ($FormattedDisk, "<inDarkGray> Compact disk</inDarkGray>") -join("")}
        }

        $infoDisks.Add($FormattedDisk)
    }

    Return $infoDisks
}
