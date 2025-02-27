# Unix functions
function touch([string]$file) {
    if (-Not $file) {
        return
    }

    $directory = Split-Path -Path $file -Parent

    if ($directory -and -Not (Test-Path $directory)) {
        try {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Formatted " <error/> Failed to create directory '$directory'. Error: $_"
            return
        }
    }

    try {
        "" | Out-File $file -Encoding ASCII
    }
    catch {
        Write-Error " <error/> Failed to create or update the file '$file'. Error: $_"
    }
}

function unzip([string] $file) {
    Test-CommandExists "7z"

    if (-Not (Test-Path $file)) {
        Write-Formatted " <error/> The source archive '$file' does not exist."
        return
    }

    $fileDir = Split-Path -Path $file -Parent
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)

    $DestinationPath = Join-Path -Path $fileDir -ChildPath $fileName

    if (-Not (Test-Path $DestinationPath)) {
        try {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }
        catch {
            Write-Formatted " <error/> Failed to create directory '$DestinationPath'."
            return
        }
    }

    try {
        & 7z x $file -o"$DestinationPath" -y
    }
    catch {
        Write-Formatted " <error/> Extraction failed: $_"
    }
}

function which([string] $name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export([string] $name, [string] $value) {
    Set-Item -force -path "env:$name" -value $value;
}

function pkill([string] $name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep([string] $name) {
    Get-Process $name
}

function head {
    param($Path, $n = 10)
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

function mkcd {
    param($dir) mkdir $dir -Force; Set-Location $dir 
}

function home {
    Set-Location -Path $HOME
}

function dtop { 
    Set-Location -Path $HOME\Desktop 
}

function dwnld {
    Set-Location -Path $HOME\Downloads 
}

function vids {
    Set-Location -Path $HOME\Videos 
}

function music {
    Set-Location -Path $HOME\Music 
}

function docs {
    Set-Location -Path $HOME\Documents
}

function cpy {
    Set-Clipboard $args[0] 
}

function pst { 
    Get-Clipboard 
}

function neofetch {
    $offsetX = 39
    $offsetY = 17

    $logo = "
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████

 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
 ████████████████  ████████████████
    "

    Write-Formatted("<windows>$logo</><move-up:$offsetY/>")

    function Write-FormattedInfo([string]$key, [string] $value) {
        $output = "<move-right:$offsetX/>"
    
        if ($key.Length -gt 1) {
            $output += "<windows>$key</>: "
        }
    
        $output += $value;

        Write-Formatted $output
    }

    $hostName = $env:COMPUTERNAME
    $fullUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $userName = $fullUserName -replace "$hostName\\", ""
    $divider = "-" * $fullUserName.Length

    $os = Get-CimInstance Win32_OperatingSystem
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    $uptime = (Get-Date) - $os.LastBootUpTime
    $uptimeString = "{0:N0} days, {1:N0} hours, {2:N0} minutes" -f [math]::Floor($uptime.TotalDays), $uptime.Hours, $uptime.Minutes

    $videoController = Get-CimInstance Win32_VideoController | Select-Object -First 1

    if (!$videoController) {
        $resolution = 'N/A';
    } else {
        $resolution = "$($videoController.CurrentHorizontalResolution) x $($videoController.CurrentVerticalResolution)"
    }

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1

    $memory = Get-CimInstance Win32_OperatingSystem
    $memTotal = [Math]::Floor($memory.TotalVisibleMemorySize / 1KB)
    $memAvailable = [Math]::Floor($memory.FreePhysicalMemory / 1KB)
    $memoryInfo = "$memAvailable MiB/$memTotal MiB"

    $shellVersion = $PSVersionTable.PSVersion
    $terminal = if ($env:WT_SESSION) { "Windows Terminal" } else { "PowerShell Shell" }

    # Output the collected information
    Write-FormattedInfo "" "<windows>$userName</>@<windows>$hostName</>"
    Write-FormattedInfo "" "$divider"
    Write-FormattedInfo "Admin" ($isAdmin ? "Yes" : "No")
    Write-FormattedInfo "OS" $os.Caption
    Write-FormattedInfo "Kernel" $os.Version
    Write-FormattedInfo "Build" $os.BuildNumber
    Write-FormattedInfo "Uptime" $uptimeString
    Write-FormattedInfo "Shell" "PowerShell $shellVersion"
    Write-FormattedInfo "Terminal" $terminal
    Write-FormattedInfo "Resolution" $resolution
    Write-FormattedInfo "CPU" $cpu.Name
    Write-FormattedInfo "GPU" $gpu.Name
    Write-FormattedInfo "Memory" $memoryInfo
    Write-FormattedInfo "" ""
    Write-FormattedInfo "" "`e[40m   `e[41m   `e[42m   `e[43m   `e[44m   `e[45m   `e[46m   `e[47m   `e[0m"
    Write-FormattedInfo "" "`e[100m   `e[101m   `e[102m   `e[103m   `e[104m   `e[105m   `e[106m   `e[107m   `e[0m"
    Write-FormattedInfo "" ""

    $gpu

    $videoController
}

# Other functions
function Invoke-RestartProfile {
    <#
        .SYNOPSIS
            Restarts the current session.
    #>
    . $PROFILE
}

function Get-PublicIP {
    <#
        .SYNOPSIS
            Gets public IPv4 and IPv6 addresses using https://ipify.org.
    #>
    Write-Formatted "IPv4: <info>$((Invoke-WebRequest -Uri "https://api.ipify.org").Content)</>"
    Write-Formatted "IPv6: <info>$((Invoke-WebRequest -Uri "https://api6.ipify.org").Content)</>"
}

function Invoke-ClearNvidiaCache {
    <#
        .SYNOPSIS
            Cleans Nvidia driver cache.
        .DESCRIPTION
            This cmdlet clears nvidia driver cache in:
            - %LOCALAPPDATA%\NVIDIA\
            - %LOCALAPPDATA%\NVIDIA Corporation\NV_Cache\
            - %PROGRAMDATA%\NVIDIA Corporation\NV_Cache\
            This cmdlet will also delete everything in the %TEMP% folder.
    #>

    $paths = $(
        "$($env:LOCALAPPDATA)\NVIDIA\*"
        "$($env:LOCALAPPDATA)\NVIDIA Corporation\NV_Cache\*"
        "$($env:ProgramData)\NVIDIA Corporation\NV_Cache\*"
        "$($env:TEMP)\*"
    )
    
    foreach ($path in $paths) {
        Write-Formatted "Removing <comment>$path</>"
        Remove-Item $path -Recurse -ErrorAction SilentlyContinue
    }

    Invoke-Sound
}

function Watch-Performance {
    <#
        .SYNOPSIS
            Displays usage every 2 seconds.
        .DESCRIPTION
            This cmdlet displays Date & Time, CPU Usage %, Available RAM MiB (%), GPU Usage %, GPU Memory usage MiB every 2 seconds.
    #>

    $totalRamMiB = [Math]::Floor((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1KB)

    while ($true) {
        $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $availableRamMiB = [Math]::Floor((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB)

        $gpuMemUsage = (Get-Counter "\GPU Process Memory(*)\Local Usage").CounterSamples |
        Where-Object CookedValue | Measure-Object -Property CookedValue -Sum
        $gpuMemUsage = [Math]::Floor($gpuMemUsage)
        $gpuUsage = (Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage").CounterSamples |
        Where-Object CookedValue | Measure-Object -Property CookedValue -Sum

        $output = [string]::Format(
            "[<comment>{0}</>] > CPU: <info>{1:P2}</>, Available RAM: <info>{2}</>MiB (<info>{3:P2}</>%), GPU Usage: <info>{4:P2}</>, GPU Memory: <info>{5:F2}</>MiB",
            $dateTime,
            $cpuUsage / 100,
            $availableRamMiB,
            $availableRamMiB / $totalRamMiB,
            $gpuUsage.Sum / 100,
            $gpuMemUsage.Sum / 1MB * (1024 / 1000)
        )

        Write-Formatted $output
        Start-Sleep -Seconds 2
    }
}

function Invoke-VideoCompress {
    <#
        .SYNOPSIS
            Compresses video using h264 codec with medium preset.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            Invoke-VideoCompress -InputPath video
            Invoke-VideoCompress -InputPath video.mp4
            Invoke-VideoCompress -InputPath video.mp4 -OutputPath output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Compression preset. Defaults to Medium")]
        [ValidateScript({ $_ -match 'ultrafast|superfast|veryfast|faster|fast|medium|slow|veryslow' })]
        [string]
        $Preset,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-compressed.mp4 will be used")]
        [string]
        $OutputPath
    )
    
    $null = Test-CommandExists "ffmpeg"
    $OutputPath = Invoke-NormalizeFilename $InputPath $OutputPath -postfix "compressed" -defaultExtension "mp4"
    $Preset = $Preset ? $Preset : "medium"

    ffmpeg -i $InputPath -c:v libx264 -preset $Preset -c:a aac -b:a 192k -movflags +faststart $OutputPath

    Invoke-Sound
}

function Invoke-VideoRemoveAudio {
    <#
        .SYNOPSIS
            Removes audio from the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            Invoke-VideoRemoveAudio -InputPath video
            Invoke-VideoRemoveAudio -InputPath video.mp4
            Invoke-VideoRemoveAudio -InputPath video.mp4 -OutputPath output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Output filename, if no filename specified, <InputFileName>-noaudio.mp4 will be used")]
        [string]
        $OutputPath
    )
    
    $null = Test-CommandExists "ffmpeg"
    $OutputPath = Invoke-NormalizeFilename $InputPath $OutputPath -postfix "no-audio" -defaultExtension "mp4"

    ffmpeg -i $InputPath -an -c copy -y $OutputPath

    Invoke-Sound
}

function Invoke-VideoExtractAudio {
    <#
        .SYNOPSIS
            Extracts audio from the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            Invoke-VideoExtractAudio -InputPath video
            Invoke-VideoExtractAudio -InputPath video.mp4
            Invoke-VideoExtractAudio -InputPath video.mp4 -OutputPath output.m4a
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Output filename, if no filename specified, <InputFileName>-audio.m4a will be used")]
        [string]
        $OutputPath
    )
    
    $null = Test-CommandExists "ffmpeg"
    $OutputPath = Invoke-NormalizeFilename $InputPath $OutputPath -postfix "audio" -defaultExtension "mp3"

    ffmpeg -i $InputPath -vn -acodec copy $OutputPath

    Invoke-Sound
}

function Invoke-VideoChangeSpeed {
    <#
        .SYNOPSIS
            Changes speed of the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            Invoke-VideoChangeSpeed -InputPath video -Speed 1.5
            Invoke-VideoChangeSpeed -InputPath video.mp4 -Speed 0.5
            Invoke-VideoChangeSpeed -InputPath video.mp4 -Speed 1.3 -OutputPath output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $InputPath,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Video speed multiplier, to slow down video use values < 1")]
        [Double]
        $Speed,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-x<speed>.mp4 will be used")]
        [string]
        $OutputPath
    )
    
    $null = Test-CommandExists "ffmpeg"

    if ($Speed -eq 0) {
        $Speed = 1
    }

    $Speed = 1.0 / $Speed
    $audioSpeed = 1.0 / $Speed

    $OutputPath = Invoke-NormalizeFilename $InputPath $OutputPath -postfix "x$audioSpeed" -defaultExtension "mp4"

    ffmpeg -i $InputPath -vf "setpts=$Speed*PTS" -filter:a "atempo=$audioSpeed" $OutputPath

    Invoke-Sound
}

function Invoke-VideoTrim {
    <#
        .SYNOPSIS
            Trims the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            Invoke-VideoTrim -InputPath video -Start 01:40:00
            Invoke-VideoTrim -InputPath video.mp4 -Start 0:38:30 -End 1:10:10
            Invoke-VideoTrim -InputPath video.mp4 -Start 0:38:30 -End 1:10:10 -OutputPath out.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")]
        [string]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Start time of the video trimming. Note that you can use two different time unit formats: sexagesimal (HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678), or in seconds.")]
        [string]
        $Start,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "End time of the video trimming. Note that you can use two different time unit formats: sexagesimal (HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678), or in seconds.")]
        [string]
        $End,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Output filename, if no filename specified, <InputFileName>-trimmed<period>.mp4 will be used")]
        [string]
        $OutputPath
    )

    $null = Test-CommandExists "ffmpeg"

    if (!$Start -and !$End) {
        Write-Formatted " <error/> End or start of the section to trim must be specified."
        return
    }

    if (!$End) {
        $End = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputPath
    }
    
    $Start = $Start ? $Start : 0

    $OutputPath = Invoke-NormalizeFilename $InputPath $OutputPath -postfix "trimmed-$($Start ? $Start.Replace(":", ".") : "start")-$($End ? $End.Replace(":", ".") : "end")" -defaultExtension "mp4"

    ffmpeg -i $InputPath -ss $Start -to $End $OutputPath

    Invoke-Sound
}

function Get-YoutubeAudio {
    <#
        .SYNOPSIS
            Downloads an audio from the youtube video
        .LINK
            https://github.com/yt-dlp/yt-dlp
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Youtube video link")] 
        [string]
        $Link,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Target path")] 
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]
        $Path = "./"
    )

    $null = Test-CommandExists "yt-dlp"

    & yt-dlp -f 251 --extract-audio --audio-format opus --audio-quality 0 --embed-thumbnail --convert-thumbnails jpg --exec-before-download "magick convert %(thumbnails.-1.filepath)q -fuzz 25% -trim -quality 100 -sampling-factor 4:2:0 -define jpeg:dct-method=float %(thumbnails.-1.filepath)q" --add-metadata -P $Path  -o "%(creator)s - %(title)s.%(ext)s" "$Link"

    Invoke-Sound
}

function Get-YoutubeThumbnail {
    <#
        .SYNOPSIS
            Downloads a thumbnail from the youtube video
        .LINK
            https://github.com/yt-dlp/yt-dlp
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Youtube video link")] 
        [string]
        $Link,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Target path")] 
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]
        $Path = "./"
    )
    
    $null = Test-CommandExists "yt-dlp"

    & yt-dlp --write-thumbnail --skip-download -P $Path "$Link"

    Invoke-Sound
}

function ConvertTo-PNG {
    <#
        .SYNOPSIS
            Converts svg image to png
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path")] 
        [string]
        $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Density")] 
        [string]
        $Density = 1000
    )
    
    $null = Test-CommandExists "magick"

    $SupportedExtensions = $(
        ".svg"
    )

    if (Test-Path -Path $Path -PathType Container) {
        $Files = Get-ChildItem -Path $Path -File | Where-Object { [IO.Path]::GetExtension($_) -in $SupportedExtensions }

        if (-not (Test-Path "./magick")) {
            New-Item -ItemType Directory -Path "./magick" | Out-Null
        }

        foreach ($File in $Files) {
            $TargetFilename = Invoke-NormalizeFilename $File -prefix "magick" -defaultExtension "png"
    
            magick convert +antialias -background none -density "$Density" "$File" "./magick/$TargetFilename"
        }
    }
    elseif (Test-Path -Path $Path -PathType Leaf) {
        $null = Test-FileExtenstion $path $SupportedExtensions

        $TargetFilename = Invoke-NormalizeFilename $Path -prefix "magick" -defaultExtension "png"

        magick convert +antialias -background none -density "$Density" "$Path" "./$TargetFilename"
    }

    Invoke-Sound
}

function ConvertTo-Opus {
    <#
        .SYNOPSIS
            Converts audio file to opus
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path")] 
        [string]
        $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Bitrate, kbps")] 
        [string]
        $Bitrate = 320
    )

    $null = Test-CommandExists "opusenc"

    $SupportedExtensions = $(
        ".aiff",
        ".mp3",
        ".flac",
        ".ogg",
        ".oga",
        ".mogg",
        ".raw",
        ".wav"
    )

    if (Test-Path -Path $Path -PathType Container) {
        $Files = Get-ChildItem -Path $Path -File | Where-Object { [IO.Path]::GetExtension($_) -in $SupportedExtensions }

        if (-not (Test-Path "./opus")) {
            New-Item -ItemType Directory -Path "./opus" | Out-Null
        }

        foreach ($File in $Files) {
            $TargetFilename = Invoke-NormalizeFilename $File -DefaultExtension "opus"
            
            opusenc --bitrate "$($Bitrate)kbps" $File "./opus/$TargetFilename"
        }
    }
    elseif (Test-Path -Path $Path -PathType Leaf) {
        $null = Test-FileExtenstion $path $SupportedExtensions

        $TargetFilename = Invoke-NormalizeFilename $Path -DefaultExtension "opus"
        
        opusenc --bitrate "$($Bitrate)kbps" $Path "./$TargetFilename"
    }

    Invoke-Sound
}

function Invoke-SplitMusicByAlbum {
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path")]
        [string]
        $path
    )

    if (!(Test-Path "$env:USERPROFILE\Documents\PowerShell\TagLibSharp.dll" -PathType Leaf)) {
        Write-Formatted " <error/> Could not find TagLibSharp.dll, please download it from https://github.com/mono/taglib-sharp"
        return
    }

    if (!(Test-Path $path -PathType Container)) {
        Write-Formatted " <error/> The folder '$path' does not exist."
        return
    }

    $supportedExtensions = $(
        ".aiff",
        ".mp3",
        ".flac",
        ".ogg",
        ".oga",
        ".mogg",
        ".raw",
        ".wav",
        ".opus"
    )

    $files = Get-ChildItem -Path $path -File | Where-Object { [IO.Path]::GetExtension($_) -in $supportedExtensions }
    [System.Reflection.Assembly]::LoadFile("$env:USERPROFILE\Documents\PowerShell\TagLibSharp.dll")

    foreach ($file in $files) {
        $mediaFile = [TagLib.File]::Create($file.fullname);
        $targetPath = "$path/$($mediaFile.Tag.Album)"

        if (!(Test-Path $targetPath)) {
            try {
                New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
            }
            catch {
                Write-Formatted " <error/> Failed to create directory '$directory'. Error: $_"
                return
            }
        }

        Move-Item $file.fullname $targetPath
        
        Write-Formatted " <info/> Moved <comment>$($file.name)</> to <info>$($targetPath)</>"
    }
}