# environmental variables
$env:POSH = "DARK"

# Set PSReadLine options
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

# import modules
Enable-PowerType
# Import-Module -Name Terminal-Icons
# Import-Module -Name posh-git

# change encoding to UTF-8
chcp 65001

# init oh-my-posh with a theme
oh-my-posh --init --shell pwsh --config "$env:USERPROFILE\oh-my-posh\inasena.yaml" | Invoke-Expression

function global:Stop-SSH {
    <#
        .SYNOPSIS
            Stops SSHD service
    #>

    Stop-service sshd
    Write-Host "Done." -ForegroundColor Green
    __Beep
}

function global:Start-SSH {
    <#
        .SYNOPSIS
            Starts SSHD service with ngrok
    #>

    Start-service sshd
    ngrok tcp 22
}

function global:Remove-NV-Cache {
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

    Remove-Item "$($env:LOCALAPPDATA)\NVIDIA\*" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$($env:LOCALAPPDATA)\NVIDIA Corporation\NV_Cache\*" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$($env:ProgramData)\NVIDIA Corporation\NV_Cache\*" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$($env:TEMP)\*" -Recurse -ErrorAction SilentlyContinue
    
    __Beep
}

function global:Read-Info {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($isAdmin) {
        Write-Host "Administrator Rights: $isAdmin" -ForegroundColor Green
    }
    else {
        Write-Host "Administrator Rights: $isAdmin" -ForegroundColor Red
    }

    Write-Host "$($PSVersionTable.OS)" -ForegroundColor DarkCyan
    Write-Host "powershell version $($PSVersionTable.PSVersion)" -ForegroundColor DarkMagenta
    Write-Host "$(git --version)"
    Write-Host "node Version $(node --version)"

    __Beep
}

function global:Watch-Perfomance-Usage {
    <#
        .SYNOPSIS
            Displays perfmance usage every 2 seconds.
        .DESCRIPTION
            This cmdlet displays Date & Time, CPU Usage %, Available RAM MB (%), GPU Usage %, GPU Memory usage MB every 2 seconds+.
    #>

    $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum

    while ($true) {
        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $cpuTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        $gpuMem = (((Get-Counter "\GPU Process Memory(*)\Local Usage").CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum
        $gpuUse = (((Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage").CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum
        $date + ' > CPU: ' + $cpuTime.ToString("#,0.000") + '%, Available RAM: ' + $availMem + 'MB (' + (100 * $availMem / ($totalRam / 1MB)).ToString("#,0.0") + '%), GPU usage: ' + $([math]::Round($gpuUse, 2)) + '%, GPU Memory: ' + $([math]::Round($gpuMem / 1MB, 2)) + 'MB'
        Start-Sleep -s 2
    }
}

function global:ffmpeg-Compress {
    <#
        .SYNOPSIS
            Compresses video using x265 codec with medium preset.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-Compress -InputPath video
            ffmpeg-Compress -InputPath video.mp4
            ffmpeg-Compress -InputPath video.mp4 -OutputPath output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Compression preset. Defaults to Medium")]
        [String]
        $Preset,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-compressed.mp4 will be used")]
        [String]
        $OutputPath
    )
    
    $res = __ValidateCmdlet "ffmpeg"

    if (!$OutputPath) {
        $File = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $OutputPath = "$File-compressed"
    }
    else {
        $Extn = [IO.Path]::GetExtension($OutputPath)
    }

    if (!$Extn) {
        $OutputPath = "$OutputPath.mp4"
    }

    $Preset = $Preset ? $Preset : "medium"

    ffmpeg -i $InputPath -c:v libx265 -an -x265-params -crf=25 -c:a copy -preset $Preset $OutputPath

    __Beep
}

function global:ffmpeg-RemoveAudio {
    <#
        .SYNOPSIS
            Removes audio from the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-RemoveAudio -InputPath video
            ffmpeg-RemoveAudio -InputPath video.mp4
            ffmpeg-RemoveAudio -InputPath video.mp4 -OutputPath output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Output filename, if no filename specified, <InputFileName>-noaudio.mp4 will be used")]
        [String]
        $OutputPath
    )
    
    $res = __ValidateCmdlet "ffmpeg"
    
    if (!$OutputPath) {
        $File = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $OutputPath = "$File-noaudio"
    }
    else {
        $Extn = [IO.Path]::GetExtension($OutputPath)
    }

    if (!$Extn) {
        $Extn = [IO.Path]::GetExtension($InputPath) ? [IO.Path]::GetExtension($InputPath) : ".mp4"
        $OutputPath = "$OutputPath$Extn"
    }

    ffmpeg -i $InputPath -an -c copy -y $OutputPath

    __Beep
}

function global:ffmpeg-ExtractAudio {
    <#
        .SYNOPSIS
            Extracts audio from the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-ExtractAudio -InputPath video
            ffmpeg-ExtractAudio -InputPath video.mp4
            ffmpeg-ExtractAudio -InputPath video.mp4 -OutputPath output.m4a
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Output filename, if no filename specified, <InputFileName>-audio.m4a will be used")]
        [String]
        $OutputPath
    )
    
    $res = __ValidateCmdlet "ffmpeg"
    
    if (!$OutputPath) {
        $File = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $OutputPath = "$File-audio.mp3"
    }
    else {
        $Extn = [IO.Path]::GetExtension($OutputPath)
    }

    if (!$Extn) {
        $OutputPath = "$OutputPath.mp3"
    }

    ffmpeg -i $InputPath -vn -acodec copy $OutputPath

    __Beep
}

function global:ffmpeg-ChangeSpeed {
    <#
        .SYNOPSIS
            Changes speed of the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-ChangeSpeed -InputPath video -Speed 1.5
            ffmpeg-ChangeSpeed -InputPath video.mp4 -Speed 0.5
            ffmpeg-ChangeSpeed -InputPath video.mp4 -Speed 1.3 -OutputPath output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String]
        $InputPath,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Video speed multiplier, to slow down video use values < 1")]
        [Double]
        $Speed,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-x<speed>.mp4 will be used")]
        [String]
        $OutputPath
    )
    
    $res = __ValidateCmdlet "ffmpeg"

    $Speed = 1 / $Speed

    if (!$Speed) {
        $Speed = (0.5)
    }

    $audioSpeed = (1 / $Speed)

    if (!$OutputPath) {
        $File = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $OutputPath = "$File-x$(1 / $Speed)"
    }
    else {
        $Extn = [IO.Path]::GetExtension($OutputPath)
    }
    
    if (!$Extn) {
        $Extn = [IO.Path]::GetExtension($InputPath) ? [IO.Path]::GetExtension($InputPath) : ".mp4"
        $OutputPath = "$OutputPath$Extn"
    }

    ffmpeg -i $InputPath -vf "setpts=$Speed*PTS" -filter:a "atempo=$audioSpeed" $OutputPath

    __Beep
}

function global:ffmpeg-Trim {
    <#
        .SYNOPSIS
            Trims the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-ChangeSpeed -InputPath video -Start 01:40:00
            ffmpeg-ChangeSpeed -InputPath video.mp4 -Start 0:38:30 -End 1:10:10
            ffmpeg-ChangeSpeed -InputPath video.mp4 -Start 0:38:30 -End 1:10:10 -OutputPath out.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String]
        $InputPath,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Start time of the video trimming. Note that you can use two different time unit formats: sexagesimal (HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678), or in seconds.")]
        [String]
        $Start,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "End time of the video trimming. Note that you can use two different time unit formats: sexagesimal (HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678), or in seconds.")]
        [String]
        $End,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Output filename, if no filename specified, <InputFileName>-x<speed>.mp4 will be used")]
        [String]
        $OutputPath
    )

    $res = __ValidateCmdlet "ffmpeg"

    if (!$Start -and !$End) {
        __WriteError "End or start of the section to trim must be specified."
        
        EXIT 1
    }

    if (!$OutputPath) {
        $File = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
        $OutputPath = "$File-trimmed-$($Start ? $Start.Replace(":", ".") : "start")-$($End ? $End.Replace(":", ".") : "end")"
    }
    else {
        $Extn = [IO.Path]::GetExtension($OutputPath)
    }
    
    if (!$Extn) {
        $Extn = [IO.Path]::GetExtension($InputPath) ? [IO.Path]::GetExtension($InputPath) : ".mp4"
        $OutputPath = "$OutputPath$Extn"
    }

    if (!$End) {
        $End = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputPath
    }
    
    $Start = $Start ? $Start : 0

    ffmpeg -i $InputPath -ss $Start -to $End $OutputPath

    __Beep
}

function global:Youtube-Audio {
    <#
        .SYNOPSIS
            Downloads audio from the youtube video
        .LINK
            https://github.com/yt-dlp/yt-dlp
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Youtube video link")] 
        [String]
        $Link,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Target path")] 
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $Path = "./"
    )

    $res = __ValidateCmdlet "yt-dlp"

    & yt-dlp -f 251 --extract-audio --audio-format opus --audio-quality 0 --embed-thumbnail --convert-thumbnails jpg --exec-before-download "magick convert %(thumbnails.-1.filepath)q -fuzz 25% -trim -quality 100 -sampling-factor 4:2:0 -define jpeg:dct-method=float %(thumbnails.-1.filepath)q" --add-metadata -P $Path  -o "%(creator)s - %(title)s.%(ext)s" "$Link"

    __Beep
}

function global:Youtube-Thumbnail {
    <#
        .SYNOPSIS
            Downloads thumbnail from the youtube video
        .LINK
            https://github.com/yt-dlp/yt-dlp
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Youtube video link")] 
        [String]
        $Link,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Target path")] 
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $Path = "./"
    )
    
    $res = __ValidateCmdlet "yt-dlp"

    & yt-dlp --write-thumbnail --skip-download -P $Path "$Link"

    __Beep
}

function global:Magick-ConvertSvg {
    <#
        .SYNOPSIS
            Converts svg image to png
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path")] 
        [String]
        $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Density")] 
        [String]
        $Density = 1000
    )
    
    $res = __ValidateCmdlet "magick"

    $SupportedExtensions = $(
        ".svg"
    )


    if (Test-Path -Path $Path -PathType Container) {
        $Files = Get-ChildItem -Path $Path -File | Where-Object { [IO.Path]::GetExtension($_) -in $SupportedExtensions }

        if (-not (Test-Path "./magick")) {
            New-Item -ItemType Directory -Path "./magick" | Out-Null
        }

        foreach ($File in $Files) {
            $TargetFilename = __ModifyFilename $File "magick" "png"
    
            magick convert +antialias -background none -density "$Density" "$File" "./magick/$TargetFilename"
        }
    }
    elseif (Test-Path -Path $Path -PathType Leaf) {
        $res = __ValidateFileExtension $path $SupportedExtensions

        $TargetFilename = __ModifyFilename $Path "magick" "png"

        magick convert +antialias -background none -density "$Density" "$Path" "./$TargetFilename"
    }

    __Beep
}

function global:Opus-Convert {
    <#
        .SYNOPSIS
            Converts audio file to opus
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path")] 
        [String]
        $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Bitrate, kbps")] 
        [String]
        $Bitrate = 320
    )

    $res = __ValidateCmdlet "opusenc"

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
            $TargetFilename = __ModifyFilename $File -Extension "opus"
            
            opusenc --bitrate "$($Bitrate)kbps" $File "./opus/$TargetFilename"
        }
    }
    elseif (Test-Path -Path $Path -PathType Leaf) {
        $res = __ValidateFileExtension $path $SupportedExtensions

        $TargetFilename = __ModifyFilename $Path -Extension "opus"
        
        opusenc --bitrate "$($Bitrate)kbps" $Path "./$TargetFilename"
    }

    __Beep
}

function global:__ValidateFileExtension {
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
        __WriteError "File '$Filename' has invalid extension. Supported extensions are: $SupportedExtensionsString"
        
        EXIT 1
    }
}

function private:__ValidateCmdlet {
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
        __WriteError "Command '$Command' is required to run this command"

        EXIT 1
    }
}

function private:__ModifyFilename {
    <#
        .SYNOPSIS
            Transforms filename
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Filename")] 
        [String]
        $Filename,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Prefix")] 
        [String]
        $Prefix,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Postfix")] 
        [String]
        $Postfix,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Target Extension")] 
        [String]
        $Extension
    )

    $ResultFile = ""

    if ($Prefix) {
        $ResultFile += "$Prefix-"
    }

    $ResultFile += [System.IO.Path]::GetFileNameWithoutExtension($Filename)

    if ($Postfix) {
        $ResultFile += "-$Postfix"
    }
    
    if (!$Extension) {
        $Extension = [IO.Path]::GetExtension($Filename)
    }

    return "$ResultFile.$Extension"
}

function private:__WriteError {
    <#
        .SYNOPSIS
            Outputs formatted error
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Text")] 
        [String]
        $Message
    )
    
    Write-Host "`e[31mError:`e[0m $Message"
}

function private:__WriteSuccess {
    <#
        .SYNOPSIS
            Outputs formatted success
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Text")] 
        [String]
        $Message
    )
    
    Write-Host "`e[32m+`e[0m $Message"
}

function private:__WriteFail {
    <#
        .SYNOPSIS
            Outputs formatted fail
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Text")] 
        [String]
        $Message
    )
    
    Write-Host "`e[31m-`e[0m $Message"
}

function private:__WriteInfo {
    <#
        .SYNOPSIS
            Outputs formatted info
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Text")] 
        [String]
        $Message
    )
    
    Write-Host "`e[33m!`e[0m $Message"
}

function private:__Beep {
    <#
        .SYNOPSIS
            Makes system sound
    #>
    [System.Media.SystemSounds]::Hand.Play()
}

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })