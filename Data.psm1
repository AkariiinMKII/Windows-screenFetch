Function Get-SystemSpecifications()
{

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

Function Get-UserInformation()
{
    return ($env:USERNAME, "@", [System.Net.Dns]::GetHostName()) -join("");
}

Function Get-DividingLine()
{
    return "-" * $UserInfo.Length;
}

Function Get-OS()
{
    return ((Get-CimInstance Win32_OperatingSystem).Caption, (Get-CimInstance Win32_OperatingSystem).OSArchitecture) -join(" ");
}

Function Get-Version()
{
    return (Get-CimInstance Win32_OperatingSystem).Version;
}

Function Get-SystemUptime()
{
    $TimeTable = Get-CimInstance Win32_OperatingSystem | Select-Object LastBootUpTime, LocalDateTime;

    $Uptime = (([DateTime]$TimeTable.LocalDateTime) - ([DateTime]$TimeTable.LastBootUpTime));
    $FormattedUptime = ($Uptime.Days.ToString(), "d ", $Uptime.Hours.ToString(), "h ", $Uptime.Minutes.ToString(), "m ", $Uptime.Seconds.ToString(), "s") -join("");

    return $FormattedUptime;
}

Function Get-Shell()
{
    return ("PowerShell", $PSVersionTable.PSVersion.ToString()) -join(" ");
}

Function Get-Displays()
{
    $Displays = New-Object System.Collections.Generic.List[System.Object];
    
    $Monitors = Get-CimInstance -ClassName Win32_VideoController | Select-Object CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate;

    $NumMonitors = ($Monitors | Measure-Object).Count;

    for ($i=0; $i -lt $NumMonitors; $i++) {
        $HorizontalResolution = $Monitors[$i].CurrentHorizontalResolution;
        $VerticalResolution = $Monitors[$i].CurrentVerticalResolution;
        $RefreshRate = $Monitors[$i].CurrentRefreshRate;

        if ($HorizontalResolution -And $VerticalResolution -And $RefreshRate) {
            $Display = ($HorizontalResolution.ToString(), " x ", $VerticalResolution.ToString(), " @ ", $RefreshRate.ToString(), "Hz") -join("");

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
    return ($Motherboard.Manufacturer, $Motherboard.Product) -join(" ");
}

Function Get-RAM()
{
    $FreeRam = ([math]::Truncate((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB)); 
    $TotalRam = ([math]::Truncate((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB));

    $UsedRam = $TotalRam - $FreeRam;
    $UsedRamPercent = "{0:F0}" -f (($UsedRam / $TotalRam) * 100);

    $UsedRamGB = "{0:F1}" -f ($UsedRam / 1024);
    $TotalRamGB = "{0:F1}" -f ($TotalRam / 1024);

    return ($UsedRamGB.ToString(), "GiB / ", $TotalRamGB.ToString(), "GiB (", $UsedRamPercent.ToString(), "% used)") -join("");
}

Function Get-Disks()
{
    $FormattedDisks = New-Object System.Collections.Generic.List[System.Object];

    $DiskTable = Get-CimInstance Win32_LogicalDisk | Select-Object DeviceId, Size, FreeSpace;

    $NumDisks = ($DiskTable | Measure-Object).Count;

    for ($i=0; $i -lt $NumDisks; $i++) {
        $DiskID = $DiskTable[$i].DeviceId;

        $DiskSize = $DiskTable[$i].Size;
        $FreeDiskSize = $DiskTable[$i].FreeSpace;

        if ($DiskSize -gt 0) {
            $UsedDiskSize = $DiskSize - $FreeDiskSize;
            $UsedDiskPercent = "{0:F0}" -f (($UsedDiskSize / $DiskSize) * 100);
            
            $CheckSize = $DiskSize / 10737418240;

            if ($CheckSize -gt 1) {
                $DiskSizeValue = "{0:F0}" -f ($DiskSize / 1073741824);
                $UsedDiskSizeValue = "{0:F0}" -f ($UsedDiskSize / 1073741824);

                $Unit = "GiB";
            }
            else {
                $DiskSizeValue = "{0:F0}" -f ($DiskSize / 1048576);
                $UsedDiskSizeValue = "{0:F0}" -f ($UsedDiskSize / 1048576);

                $Unit = "MiB";
            }

            $DiskStatus = ($UsedDiskSizeValue.ToString(), $Unit, " / ", $DiskSizeValue.ToString(), $Unit, " (", $UsedDiskPercent.ToString(), "% used)") -join("");
        }
        else {
            $DiskStatus = "Empty";
        }

        $FormattedDisk = ($DiskID.ToString(), $DiskStatus) -join(" ");
        $FormattedDisks.Add($FormattedDisk);
    }

    return $FormattedDisks;
}
