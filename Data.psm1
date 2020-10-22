
Function Get-SystemSpecifications()
{

    $UserInfo = Get-UserInformation;
    $DividingLine = Get-DividingLine;
    $OS = Get-OS;
    $Kernel = Get-Kernel;
    $Uptime = Get-Uptime;
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
        $Kernel,
        $Uptime,
        $Shell,
        $Motherboard,
        $CPU,
        $GPU,
        $Displays,
        $RAM;

    foreach ($Disk in $Disks)
    {
        [void]$SystemInfoCollection.Add($Disk);
    }

    return $SystemInfoCollection;
}

Function Get-LineToTitleMappings()
{
    $TitleMappings = @{
        0 = "";
        1 = "";
        2 = "OS: ";
        3 = "Kernel: ";
        4 = "Uptime: ";
        5 = "Shell: ";
        6 = "Motherboard: ";
        7 = "CPU: ";
        8 = "GPU: ";
        9 = "Display: ";
        10 = "Memory: ";
    };

    return $TitleMappings;
}

Function Get-UserInformation()
{
    return $env:USERNAME + "@" + [System.Net.Dns]::GetHostName();
}

Function Get-DividingLine()
{
    return "-" * $UserInfo.Length;
}

Function Get-OS()
{
    return (Get-CimInstance Win32_OperatingSystem).Caption + " " +
        (Get-CimInstance Win32_OperatingSystem).OSArchitecture;
}

Function Get-Kernel()
{
    return (Get-CimInstance  Win32_OperatingSystem).Version;
}

Function Get-Uptime()
{
    $Uptime = (([DateTime](Get-CimInstance Win32_OperatingSystem).LocalDateTime) -
            ([DateTime](Get-CimInstance Win32_OperatingSystem).LastBootUpTime));

    $FormattedUptime =  $Uptime.Days.ToString() + "d " + $Uptime.Hours.ToString() + "h " + $Uptime.Minutes.ToString() + "m " + $Uptime.Seconds.ToString() + "s ";
    return $FormattedUptime;
}

Function Get-Shell()
{
    return "PowerShell $($PSVersionTable.PSVersion.ToString())";
}

Function Get-Displays()
{
    $Displays = New-Object System.Collections.Generic.List[System.Object];
    
    $Monitors = Get-CimInstance -ClassName Win32_VideoController | Select-Object CurrentHorizontalResolution,CurrentVerticalResolution,CurrentRefreshRate;

    for ($i=0; $i -lt ($Monitors.Count); $i++) {
        $HorizontalResolution = $Monitors[$i].CurrentHorizontalResolution;
        $VerticalResolution = $Monitors[$i].CurrentVerticalResolution;
        $RefreshRate = $Monitors[$i].CurrentRefreshRate;

        if ($HorizontalResolution -And $VerticalResolution -And $RefreshRate) {
            $Display = $HorizontalResolution.ToString() + " x " + $VerticalResolution.ToString() + " @ " + $RefreshRate.ToString() + "Hz";

            if (!$Displays) {
                $Displays = $Display;
            }
            else {
                $Displays = ($Displays, $Display) -join("; ");
            }
        }
    }

    if ($Displays) {
        return $Displays;
    }
    else {
        return "NONE";
    }
}

Function Get-CPU()
{
    return (Get-CimInstance -ClassName Win32_Processor | ForEach-Object {$_.Name}) -join("; ");
}

Function Get-GPU()
{
    return (Get-CimInstance -ClassName Win32_VideoController | ForEach-Object {$_.Name}) -join("; ");
}

Function Get-Mobo()
{
    $Motherboard = Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product;
    return $Motherboard.Manufacturer + " " + $Motherboard.Product;

}

Function Get-RAM()
{
    $FreeRam = ([math]::Truncate((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB)); 
    $TotalRam = ([math]::Truncate((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB));
    $UsedRam = $TotalRam - $FreeRam;
    $FreeRamPercent = ($FreeRam / $TotalRam) * 100;
    $FreeRamPercent = "{0:F0}" -f $FreeRamPercent;
    $UsedRamPercent = ($UsedRam / $TotalRam) * 100;
    $UsedRamPercent = "{0:F0}" -f $UsedRamPercent;

    return $UsedRam.ToString() + "MiB / " + $TotalRam.ToString() + "MiB " + "(" + $UsedRamPercent.ToString() + "%" + " used)";
}

Function Get-Disks()
{
    $FormattedDisks = New-Object System.Collections.Generic.List[System.Object];

    $NumDisks = (Get-CimInstance Win32_LogicalDisk).Count;

    if ($NumDisks) {
        for ($i=0; $i -lt ($NumDisks); $i++) {
            $DiskID = (Get-CimInstance Win32_LogicalDisk)[$i].DeviceId;

            $DiskSize = (Get-CimInstance Win32_LogicalDisk)[$i].Size;

            if ($DiskSize -gt 0) {
                $FreeDiskSize = (Get-CimInstance Win32_LogicalDisk)[$i].FreeSpace
                $FreeDiskSizeGB = $FreeDiskSize / 1073741824;
                $FreeDiskSizeGB = "{0:F0}" -f $FreeDiskSizeGB;

                $DiskSizeGB = $DiskSize / 1073741824;
                $DiskSizeGB = "{0:F0}" -f $DiskSizeGB;

                if ($DiskSizeGB -gt 0 -And $FreeDiskSizeGB -gt 0) {
                    $FreeDiskPercent = ($FreeDiskSizeGB / $DiskSizeGB) * 100;
                    $FreeDiskPercent = "{0:F0}" -f $FreeDiskPercent;

                    $UsedDiskSize = $DiskSize - $FreeDiskSize;
                    $UsedDiskSizeGB = $UsedDiskSize / 1073741824;
                    $UsedDiskSizeGB = "{0:F0}" -f $UsedDiskSizeGB;
                    $UsedDiskPercent = ($UsedDiskSizeGB / $DiskSizeGB) * 100;
                    $UsedDiskPercent = "{0:F0}" -f $UsedDiskPercent;
                }
                else {
                    $FreeDiskPercent = 0;
                    $UsedDiskSizeGB = 0;
                    $UsedDiskPercent = 0;
                }
            }
            else {
                $DiskSizeGB = 0;
                $FreeDiskSizeGB = 0;
                $FreeDiskPercent = 0;
                $UsedDiskSizeGB = 0;
                $UsedDiskPercent = 100;
            }

            $FormattedDisk = "Disk " + $DiskID.ToString() + " " +
                $UsedDiskSizeGB.ToString() + "GiB" + " / " + $DiskSizeGB.ToString() + "GiB " +
                "(" + $UsedDiskPercent.ToString() + "%" + " used)";
            $FormattedDisks.Add($FormattedDisk);
        }
    }
    else {
        $DiskID = (Get-CimInstance Win32_LogicalDisk).DeviceId;

        $FreeDiskSize = (Get-CimInstance Win32_LogicalDisk).FreeSpace
        $FreeDiskSizeGB = $FreeDiskSize / 1073741824;
        $FreeDiskSizeGB = "{0:F0}" -f $FreeDiskSizeGB;

        $DiskSize = (Get-CimInstance Win32_LogicalDisk).Size;
        $DiskSizeGB = $DiskSize / 1073741824;
        $DiskSizeGB = "{0:F0}" -f $DiskSizeGB;

        if ($DiskSize -gt 0 -And $FreeDiskSize -gt 0 ) {
            $FreeDiskPercent = ($FreeDiskSizeGB / $DiskSizeGB) * 100;
            $FreeDiskPercent = "{0:F0}" -f $FreeDiskPercent;

            $UsedDiskSizeGB = $DiskSizeGB - $FreeDiskSizeGB;
            $UsedDiskPercent = ($UsedDiskSizeGB / $DiskSizeGB) * 100;
            $UsedDiskPercent = "{0:F0}" -f $UsedDiskPercent;

            $FormattedDisk = "Disk " + $DiskID.ToString() + " " +
                $UsedDiskSizeGB.ToString() + "GiB" + " / " + $DiskSizeGB.ToString() + "GiB " +
                "(" + $UsedDiskPercent.ToString() + "%" + ")";
            $FormattedDisks.Add($FormattedDisk);
        }
        else {
            $FormattedDisk = "Disk " + $DiskID.ToString() + " Empty";
            $FormattedDisks.Add($FormattedDisk);
        }
    }

    return $FormattedDisks;
}
