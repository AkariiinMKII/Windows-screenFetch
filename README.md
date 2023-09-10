# Windows screenFetch

[![License](https://img.shields.io/github/license/AkariiinMKII/Windows-screenFetch?label=License)](https://github.com/AkariiinMKII/Windows-screenFetch/blob/main/LICENSE)
![Language](https://img.shields.io/badge/Language-PowerShell-blue)
![Supported Platform](https://img.shields.io/badge/Supported_Platform-Windows_10\/11-blue)
![Repo Size](https://img.shields.io/github/repo-size/AkariiinMKII/Windows-screenFetch?label=Repo%20Size)

![Windows screenFetch](.screenshots/win10_logo.png)

_Original by [JulianChow94](https://github.com/JulianChow94/Windows-screenFetch), modified in this repo._

> ## ScreenFetch
>
> screenFetch was originally made as a "Bash Screenshot Information Tool". Simply, it lets you display detailed information about your system in the terminal, it also comes with a ASCII logo for the detected Linux distribution.
>
> This doesn't work on Windows natively and this project is my attempt to provide a solution that does not require obtaining a linux environment on windows.
>
> The original can be found in [KittyKatt's repository](https://github.com/KittyKatt/screenFetch).
>
> ## How is it different
>
> The original screenfetch requires a system that supports bash so it cannot be used on windows natively! This is a small scale project that simply "mimics" the behaviour of screenFetch in windows.
>
> __Windows screenFetch is a PowerShell script, not a Bash program.__ Therefore, a linux-like environment such as [Cygwin](https://www.cygwin.com/) or [MinGW](http://www.mingw.org/wiki/msys) is ___not required___. This can be run natively on windows as a PowerShell script within a PowerShell or command prompt console.
>
> _Since this tool is only intended to run within a windows environment, no flags to invoke any Linux distribution ASCII art is supported._

## Installation

- ### Via [Scoop](https://github.com/ScoopInstaller/Scoop)

```PowerShell
# Add scoop bucket
scoop bucket add Scoop4kariiin https://github.com/AkariiinMKII/Scoop4kariiin

# Install
scoop install Windows-screenFetch-alt
# This version returns display resolution instead of native resolution in "Display"
# Here is another version that returns native resolution
# but may cause other bugs, see https://github.com/AkariiinMKII/Windows-screenFetch/issues/3
# use following command if you need another version (will uninstall current branch version)
# scoop install Windows-screenFetch

```

- ### Via git clone

Notice that you need to install [git for windows](https://gitforwindows.org/) in advance.

```PowerShell
# Go to modules folder
$UsePath = (Split-Path $PROFILE | Join-Path -ChildPath Modules); if(!(Test-Path $UsePath)) {New-Item $UsePath -Type Directory -Force | Out-Null}; Set-Location $UsePath

# Clone this repository and switch to this branch
git clone https://github.com/AkariiinMKII/Windows-screenFetch; Set-Location .\Windows-screenFetch\; git checkout use-display-resolution

# Modify PS profile to enable auto-import
if (!(Test-Path $PROFILE)) {New-Item $PROFILE -Type File -Force | Out-Null}
Add-Content -Path $PROFILE -Value "Import-Module Windows-screenFetch"
```

## Functions

### `screenFetch`

_Print system information with distribution logo._

|Parameters|Type|Mandatory|Descriptions|
|----|:----:|:----:|----|
|`Distro`|String|&cross;|Specify the ASCII logo shown in left side.[1]|
|`Help`|Switch|&cross;|Print help info.|
|`Version`|Switch|&cross;|Print version info.|

[1] Currently support the logo of Windows and macOS, please see `AsciiArtGenerator` for possible extensions

- For Windows 10 logo, use `win10`, `windows10`
- For Windows 11 logo, use `win11`, `windows11`
- For Windows XP logo, use `winxp`, `windowsxp`, `xp`
- For macOS logo, use `mac`, `macos`, `osx`, `apple`

![Windows 11 logo](.screenshots/win11_logo.png)
![Windows XP logo](.screenshots/winxp_logo.png)
![macOS logo](.screenshots/macos_logo.png)

## Troubleshooting

If you have followed the installation steps but you're getting the following error:

```PowerShell
The file C:\<yourpath>\screenfetch.ps1 is not digitally signed.
The script will not execute on the system.
```

A common fix is to run the PowerShell command `Set-ExecutionPolicy Unrestricted` in a shell with administrative privileges.

## Known issues

- Cannot get native resolution in `Display` area. [(#3)](https://github.com/AkariiinMKII/Windows-screenFetch/issues/3)

## Contributing

Feel free to open PRs!🥳
