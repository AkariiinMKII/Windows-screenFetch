Function Get-SystemSpecifications() {

    $UserInfo = Get-UserInformation;
    $DividingLine = Get-DividingLine;
    $OS = Get-OS;
    $Version = Get-Version;
    $Uptime = Get-SystemUptime;
    $Shell = Get-Shell;
    $Motherboard = Get-Mobo;
    $CPU = Get-CPU;
    $GPU = Get-GPU;
    $Displays = Get-Displays;
    $RAM = Get-RAM;
    $Disks = Get-Disks;


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
        $RAM;

    foreach ($Disk in $Disks) {
        [void]$SystemInfoCollection.Add($Disk);
    }

    return $SystemInfoCollection;
}

Function Get-LineToTitleMappings() {
    $TitleMappings = @{
        0 = "";
        1 = "";
        2 = "OS: ";
        3 = "Version: ";
        4 = "Uptime: ";
        5 = "Shell: ";
        6 = "Motherboard: ";
        7 = "CPU: ";
        8 = "GPU: ";
        9 = "Display: ";
        10 = "RAM: ";
    };

    return $TitleMappings;
}

Function Get-UserInformation() {
    return ($env:USERNAME, "@", [System.Net.Dns]::GetHostName()) -join("");
}

Function Get-DividingLine() {
    return "-" * $UserInfo.Length;
}

Function Get-OS() {
    $GCIOS = Get-CimInstance -ClassName Win32_OperatingSystem
    return ($GCIOS.Caption, $GCIOS.OSArchitecture) -join(" ");
}

Function Get-Version() {
    return (Get-CimInstance -ClassName Win32_OperatingSystem).Version;
}

Function Get-SystemUptime() {
    $GCIOS = Get-CimInstance -ClassName Win32_OperatingSystem
    $Uptime = (([DateTime]$GCIOS.LocalDateTime) - ([DateTime]$GCIOS.LastBootUpTime));
    $FormattedUptime = ($Uptime.Days.ToString(), "d ", $Uptime.Hours.ToString(), "h ", $Uptime.Minutes.ToString(), "m ", $Uptime.Seconds.ToString(), "s") -join("");

    return $FormattedUptime;
}

Function Get-Shell() {
    return ("PowerShell", $PSVersionTable.PSVersion.ToString()) -join(" ");
}

Function Get-Displays() {
    Add-Type -AssemblyName System.Windows.Forms
    $AllScreens = [System.Windows.Forms.Screen]::AllScreens;

    $Monitors = $AllScreens | ForEach-Object {
        $MonitorInfo = New-Object psobject
        $MonitorInfo | Add-Member -MemberType NoteProperty -Name ScreenWidth -Value ($_.Bounds).Width
        $MonitorInfo | Add-Member -MemberType NoteProperty -Name ScreenHeight -Value ($_.Bounds).Height
        $MonitorInfo | Add-Member -MemberType NoteProperty -Name Primary -Value $_.Primary
        $MonitorInfo
    }

    $Displays = New-Object System.Collections.Generic.List[System.Object];

    $Monitors | Where-Object {$_.Primary} | ForEach-Object {
        $Display = ($_.ScreenWidth.ToString(), " x ", $_.ScreenHeight.ToString(), " (Primary)") -join("");
        if (!$Displays) {
            $Displays = $Display;
        }
        else {
            $Displays = ($Displays, $Display) -join("; ");
        }
    }

    $Monitors | Where-Object {!$_.Primary} | ForEach-Object {
        $Display = ($_.ScreenWidth.ToString(), " x ", $_.ScreenHeight.ToString()) -join("");
        if (!$Displays) {
            $Displays = $Display;
        }
        else {
            $Displays = ($Displays, $Display) -join("; ");
        }
    }

    if ($Displays) {
        return $Displays;
    }
    else {
        return "NONE";
    }
}

Function Get-CPU() {
    return (Get-CimInstance -ClassName Win32_Processor -Property Name | ForEach-Object {($_.Name).Trim()}) -join("; ");
}

Function Get-GPU() {
    return (Get-CimInstance -ClassName Win32_VideoController | Where-Object {$_.Status -eq 'OK'} | ForEach-Object {($_.Name).Trim()}) -join("; ");
}

Function Get-Mobo() {
    $Motherboard = Get-CimInstance -ClassName Win32_BaseBoard;
    return ($Motherboard.Manufacturer, $Motherboard.Product) -join(" ");
}

Function Get-RAM() {
    $FreeRam = (Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1KB;
    $TotalRam = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB;

    $UsedRam = $TotalRam - $FreeRam;
    $UsedRamPercent = "{0:F0}" -f (($UsedRam / $TotalRam) * 100);

    if ($TotalRam -ge 10KB) {
        $UsedRam = "{0:F1}" -f ($UsedRam / 1KB);
        $TotalRam = "{0:F1}" -f ($TotalRam / 1KB);
        $RAMUnit = "GiB"
    }
    else {
        $UsedRam = "{0:F0}" -f $UsedRam;
        $TotalRam = "{0:F0}" -f $TotalRam;
        $RAMUnit = "MiB"
    }

    return ($UsedRam.ToString(), "$RAMUnit / ", $TotalRam.ToString(), "$RAMUnit (", $UsedRamPercent.ToString(), "% used)") -join("");
}

Function Get-Disks() {
    $FormattedDisks = New-Object System.Collections.Generic.List[System.Object];

    $DiskTable = Get-CimInstance -ClassName Win32_LogicalDisk;

    $DiskTable | ForEach-Object {
        $DiskSize = $_.Size;
        $FreeDiskSize = $_.FreeSpace;

        if ($DiskSize -gt 0) {
            $UsedDiskSize = $DiskSize - $FreeDiskSize;
            $UsedDiskPercent = "{0:F0}" -f (($UsedDiskSize / $DiskSize) * 100);

            if ($DiskSize -gt 10GB) {
                $DiskSizeValue = "{0:F0}" -f ($DiskSize / 1GB);
                $UsedDiskSizeValue = "{0:F0}" -f ($UsedDiskSize / 1GB);
                $DiskUnit = "GiB";
            }
            else {
                $DiskSizeValue = "{0:F0}" -f ($DiskSize / 1MB);
                $UsedDiskSizeValue = "{0:F0}" -f ($UsedDiskSize / 1MB);
                $DiskUnit = "MiB";
            }

            $DiskStatus = ($UsedDiskSizeValue.ToString(), $DiskUnit, " / ", $DiskSizeValue.ToString(), $DiskUnit, " (", $UsedDiskPercent.ToString(), "% used)") -join("");
        }
        else {
            $DiskStatus = "Empty";
        }

        $FormattedDisk = ($_.DeviceId.ToString(), $DiskStatus) -join(" ");

        switch ($_.DriveType) {
            2 {$FormattedDisk = ($FormattedDisk, "*Removable disk") -join(" ")}
            4 {$FormattedDisk = ($FormattedDisk, "*Network disk") -join(" ")}
            5 {$FormattedDisk = ($FormattedDisk, "*Compact disk") -join(" ")}
        }

        $FormattedDisks.Add($FormattedDisk);
    }

    return $FormattedDisks;
}
