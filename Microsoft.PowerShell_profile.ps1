# Change encoding to UTF-8
chcp 65001

# Disable telemetry if admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Utility Functions
function _importModule([string]$module) {        
    if (-not (Get-Module -ListAvailable -Name "$module")) {
        Install-Module -Name "$module" -Scope CurrentUser -Force -SkipPublisherCheck -AllowPrerelease
    }

    Import-Module -Name "$module"
}

function _write([string]$inputText) {
    $colorTags = @{
        'info'    = "`e[32m"         # Green
        'comment' = "`e[33m"         # Yellow
        'error'   = "`e[37;41m"      # White on Red
        'windows' = "`e[36m"         # Cyan
    }    
    $selfClosingTags = @{
        'info'    = "`e[32m!`e[0m" # Green !
        'comment' = "`e[33m+`e[0m" # Yellow +
        'error'   = "`e[31m-`e[0m" # Red -
    }
    $parametrisedTags = @{
        'move-up'    = "`e[#A"       # Move Up
        'move-down'  = "`e[#B"       # Move Down 
        'move-right' = "`e[#C"       # Move Right
        'move-left ' = "`e[#D"       # Move Left
    }

    $resetTag = "`e[0m"               # Reset

    $stack = New-Object System.Collections.ArrayList

    $output = ""
    $i = 0

    while ($i -lt $inputText.Length) {
        if ($inputText[$i] -ne '<') {
            $output += $inputText[$i]
            $i++

            continue
        }
  
        $endTag = $inputText.IndexOf('>', $i)

        if ($endTag -lt 0) {
            $output += $inputText[$i] 
            $i++
            continue
        }

        $tagContent = $inputText.Substring($i + 1, $endTag - $i - 1).Trim()

        if ($tagContent.EndsWith('/') -and $selfClosingTags.ContainsKey($tagContent.TrimEnd('/'))) {
            $output += $selfClosingTags[$tagContent.TrimEnd('/')]
        } elseif ($tagContent -like "/*" -and $stack.Count -gt 0 -and ($stack[$stack.Count - 1] -eq $tagContent.Substring(1) -or $tagContent -eq "/")) {
            $output += $resetTag
            $null = $stack.RemoveAt($stack.Count - 1)
                
            if ($stack.Count -gt 0) {
                $output += $colorTags[$stack[$stack.Count - 1]]
            }
        } elseif ($colorTags.ContainsKey($tagContent)) {
            $null = $stack.Add($tagContent)
            $output += $colorTags[$tagContent]
        } elseif ($tagContent -match '^([a-z0-9-_]+):(\d+)/$' -and $parametrisedTags.ContainsKey($matches[1])) {
            $tagName = $matches[1]
            $paramValue = $matches[2]

            $output += $parametrisedTags[$tagName] -replace '#', $paramValue
        } else {
            $output += "<$($tagContent)>"
        }

        $i = $endTag + 1
    }

    if ($stack.Count -gt 0) {
        $output += $resetTag
    }

    Write-Host $output;
}

function _normalizeFilename(
    [string] $inputPath,
    [string]$outputPath,
    [string]$prefix = '',
    [string]$postfix = '',
    [string]$defaultExtension = ''
) {
    if (!$outputPath) {
        $outputPath

        if ($prefix) {
            $outputPath += "$prefix-"
        }

        $outputPath += [System.IO.Path]::GetFileNameWithoutExtension($inputPath)

        if ($outputPath) {
            $outputPath += "-$postfix"
        }
    } else {
        $extension = [IO.Path]::GetExtension($outputPath)
    }

    if (!$extension) {
        $outputPath += ".$defaultExtension"
    }

    return $outputPath
}

function _validateFileExtension {
    <#
        .SYNOPSIS
            Validates file extensions
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Filename,
        [Parameter(Position = 1)]
        [string[]]$SupportedExtensions
    )

    $FileExtension = [System.IO.Path]::GetExtension($Filename)

    if (-not $SupportedExtensions.Contains($FileExtension)) {
        $SupportedExtensionsString = ($SupportedExtensions -join ', ').ToLower()
        _write " <error/> File '$Filename' has invalid extension. Supported extensions are: $SupportedExtensionsString"
        
        EXIT 1
    }
}

function _testCmdletExists {
    <#
        .SYNOPSIS
            Validates Cmdlet
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command
    )

    $Result = Get-Command $Command -ErrorAction SilentlyContinue

    if (!$Result) {
        _write " <error/> Command '$Command' is required to run this command"

        EXIT 1
    }
}

function _makeSound {
    <#
        .SYNOPSIS
            Makes system sound
    #>
    [System.Media.SystemSounds]::Hand.Play()
}

# Environmental variables
$env:POSH = "DARK"
$env:EDITOR = "nvim"

# _importModule('Terminal-Icons')
_importModule('PSReadLine')
_importModule('posh-git')
_importModule('PowerType')

Enable-PowerType

$PSReadLineOptions = @{
    CompletionQueryItems = 1
    HistoryNoDuplicates  = $true
    PredictionSource     = "Plugin"
    PredictionViewStyle  = "InlineView"
    ShowToolTips         = $true
    WordDelimiters       = ";:,.[]{}()/\|^&*-=+'""–—―_"
    Colors               = @{
        # "Command"                   = [ConsoleColor]::Yellow
        # "Comment"                   = "`e[42m" # green background
        # "ContinuationPrompt"        = [ConsoleColor]::White
        # "Default"                   = [ConsoleColor]::White
        # "Emphasis"                  = [ConsoleColor]::White
        # "Error"                     = [ConsoleColor]::Red
        # "InlinePrediction"          = [ConsoleColor]::Black
        # "Keyword"                   = [ConsoleColor]::Green
        # "ListPrediction"            = [ConsoleColor]::DarkYellow
        # "ListPredictionSelected"    = [ConsoleColor]::Black
        # "Member"                    = [ConsoleColor]::White
        # "Number"                    = [ConsoleColor]::DarkYellow
        # "Operator"                  = [ConsoleColor]::White
        # "Parameter"                 = [ConsoleColor]::Cyan
        # "Selection"                 = "`e[30;47m"
        # "String"                    = [ConsoleColor]::Blue
        # "Type"                      = [ConsoleColor]::DarkBlue
        # "Variable"                  = [ConsoleColor]::Green
    }
}

Set-PSReadLineOption @PSReadLineOptions

oh-my-posh --init --shell pwsh --config "$env:USERPROFILE\oh-my-posh\inasena.yaml" | Invoke-Expression

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

# Unix functions
function touch([string]$file) {
    $directory = Split-Path -Path $file -Parent

    if (-Not (Test-Path $directory)) {
        try {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        } catch {
            _write " <error/> Failed to create directory '$directory'. Error: $_"
            EXIT 1
        }
    }

    try {
        "" | Out-File $file -Encoding ASCII
    } catch {
        Write-Error " <error/> Failed to create or update the file '$file'. Error: $_"
    }
}

function unzip([string] $file) {
    _testCmdletExists "7z"

    if (-Not (Test-Path $file)) {
        _write " <error/> The source archive '$file' does not exist."
        return
    }

    $fileDir = Split-Path -Path $file -Parent
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)

    $DestinationPath = Join-Path -Path $fileDir -ChildPath $fileName

    if (-Not (Test-Path $DestinationPath)) {
        try {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        } catch {
            _write " <error/> Failed to create directory '$DestinationPath'."
            return
        }
    }

    try {
        & 7z x $file -o"$DestinationPath" -y
    } catch {
        _write " <error/> Extraction failed: $_"
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

    _write("<windows>$logo</><move-up:$offsetY/>")

    function _writeInfo([string]$key, [string] $value) {
        $output = "<move-right:$offsetX/>"
    
        if ($key.Length -gt 1) {
            $output += "<windows>$key</>: "
        }
    
        $output += $value;

        _write $output
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
    $resolution = "$($videoController.CurrentHorizontalResolution) x $($videoController.CurrentVerticalResolution)"

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1

    $memory = Get-CimInstance Win32_OperatingSystem
    $memTotal = [Math]::Floor($memory.TotalVisibleMemorySize / 1KB)
    $memAvailable = [Math]::Floor($memory.FreePhysicalMemory / 1KB)
    $memoryInfo = "$memAvailable MiB/$memTotal MiB"

    $shellVersion = $PSVersionTable.PSVersion
    $terminal = if ($env:WT_SESSION) { "Windows Terminal" } else { "PowerShell Shell" }

    # Output the collected information
    _writeInfo "" "<windows>$userName</>@<windows>$hostName</>"
    _writeInfo "" "$divider"
    _writeInfo "Admin" ($isAdmin ? "Yes" : "No")
    _writeInfo "OS" $os.Caption
    _writeInfo "Kernel" $os.Version
    _writeInfo "Build" $os.BuildNumber
    _writeInfo "Uptime" $uptimeString
    _writeInfo "Shell" "PowerShell $shellVersion"
    _writeInfo "Terminal" $terminal
    _writeInfo "Resolution" $resolution
    _writeInfo "CPU" $cpu.Name
    _writeInfo "GPU" $gpu.Name
    _writeInfo "Memory" $memoryInfo
    _writeInfo "" ""
    _writeInfo "" "`e[40m   `e[41m   `e[42m   `e[43m   `e[44m   `e[45m   `e[46m   `e[47m   `e[0m"
    _writeInfo "" "`e[100m   `e[101m   `e[102m   `e[103m   `e[104m   `e[105m   `e[106m   `e[107m   `e[0m"
    _writeInfo "" ""
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
    _write "IPv4: <info>$((Invoke-WebRequest -Uri "https://api.ipify.org").Content)</>"
    _write "IPv6: <info>$((Invoke-WebRequest -Uri "https://api6.ipify.org").Content)</>"
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
        _write "Removing <comment>$path</>"
        Remove-Item $path -Recurse -ErrorAction SilentlyContinue
    }

    _makeSound
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

        _write $output
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
    
    $null = _testCmdletExists "ffmpeg"
    $OutputPath = _normalizeFilename $InputPath $OutputPath -postfix "compressed" -defaultExtension "mp4"
    $Preset = $Preset ? $Preset : "medium"

    ffmpeg -i $InputPath -c:v libx264 -preset $Preset -crf=23 -c:a aac -b:a 192k -movflags +faststart $OutputPath

    _makeSound
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
    
    $null = _testCmdletExists "ffmpeg"
    $OutputPath = _normalizeFilename $InputPath $OutputPath -postfix "no-audio" -defaultExtension "mp4"

    ffmpeg -i $InputPath -an -c copy -y $OutputPath

    _makeSound
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
    
    $null = _testCmdletExists "ffmpeg"
    $OutputPath = _normalizeFilename $InputPath $OutputPath -postfix "audio" -defaultExtension "mp3"

    ffmpeg -i $InputPath -vn -acodec copy $OutputPath

    _makeSound
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
    
    $null = _testCmdletExists "ffmpeg"

    if ($Speed -eq 0) {
        $Speed = 1
    }

    $Speed = 1.0 / $Speed
    $audioSpeed = 1.0 / $Speed

    $OutputPath = _normalizeFilename $InputPath $OutputPath -postfix "x$audioSpeed" -defaultExtension "mp4"

    ffmpeg -i $InputPath -vf "setpts=$Speed*PTS" -filter:a "atempo=$audioSpeed" $OutputPath

    _makeSound
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
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
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

    $null = _testCmdletExists "ffmpeg"

    if (!$Start -and !$End) {
        _write " <error/> End or start of the section to trim must be specified."
        EXIT 1
    }

    if (!$End) {
        $End = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputPath
    }
    
    $Start = $Start ? $Start : 0

    $OutputPath = _normalizeFilename $InputPath $OutputPath -postfix "trimmed-$($Start ? $Start.Replace(":", ".") : "start")-$($End ? $End.Replace(":", ".") : "end")" -defaultExtension "mp4"

    ffmpeg -i $InputPath -ss $Start -to $End $OutputPath

    _makeSound
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

    $null = _testCmdletExists "yt-dlp"

    & yt-dlp -f 251 --extract-audio --audio-format opus --audio-quality 0 --embed-thumbnail --convert-thumbnails jpg --exec-before-download "magick convert %(thumbnails.-1.filepath)q -fuzz 25% -trim -quality 100 -sampling-factor 4:2:0 -define jpeg:dct-method=float %(thumbnails.-1.filepath)q" --add-metadata -P $Path  -o "%(creator)s - %(title)s.%(ext)s" "$Link"

    _makeSound
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
    
    $null = _testCmdletExists "yt-dlp"

    & yt-dlp --write-thumbnail --skip-download -P $Path "$Link"

    _makeSound
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
    
    $null = _testCmdletExists "magick"

    $SupportedExtensions = $(
        ".svg"
    )

    if (Test-Path -Path $Path -PathType Container) {
        $Files = Get-ChildItem -Path $Path -File | Where-Object { [IO.Path]::GetExtension($_) -in $SupportedExtensions }

        if (-not (Test-Path "./magick")) {
            New-Item -ItemType Directory -Path "./magick" | Out-Null
        }

        foreach ($File in $Files) {
            $TargetFilename = _normalizeFilename $File -prefix "magick" -defaultExtension "png"
    
            magick convert +antialias -background none -density "$Density" "$File" "./magick/$TargetFilename"
        }
    } elseif (Test-Path -Path $Path -PathType Leaf) {
        $null = _validateFileExtension $path $SupportedExtensions

        $TargetFilename = _normalizeFilename $Path -prefix "magick" -defaultExtension "png"

        magick convert +antialias -background none -density "$Density" "$Path" "./$TargetFilename"
    }

    _makeSound
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

    $null = _testCmdletExists "opusenc"

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
            $TargetFilename = _normalizeFilename $File -DefaultExtension "opus"
            
            opusenc --bitrate "$($Bitrate)kbps" $File "./opus/$TargetFilename"
        }
    } elseif (Test-Path -Path $Path -PathType Leaf) {
        $null = _validateFileExtension $path $SupportedExtensions

        $TargetFilename = _normalizeFilename $Path -DefaultExtension "opus"
        
        opusenc --bitrate "$($Bitrate)kbps" $Path "./$TargetFilename"
    }

    _makeSound
}