# environmental variables
$env:POSH="DARK"

# Set PSReadLine options
$PSReadLineOptions = @{
    CompletionQueryItems = 1
    HistoryNoDuplicates = $true
    PredictionSource = "Plugin"
    PredictionViewStyle = "InlineView"
    ShowToolTips = $true
    WordDelimiters = ";:,.[]{}()/\|^&*-=+'""–—―_"
    Colors = @{
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

# init oh-my-posh with a theme
oh-my-posh --init --shell pwsh --config "$env:USERPROFILE\oh-my-posh\inasena.json" | Invoke-Expression

# import modules
Enable-PowerType
Import-Module -Name Terminal-Icons
Import-Module -Name posh-git
Import-Module -Name DockerCompletion

# change encoding to UTF-8
chcp 65001

# clear terminal after initialization
Clear-Host

function Stop-SSH {
    <#
        .SYNOPSIS
            Stops SSHD service
    #>
    Stop-service sshd
    Write-Host "Done." -ForegroundColor Green
    Beep
}

function Start-SSH {
    <#
        .SYNOPSIS
            Starts SSHD service with ngrok
    #>
    Start-service sshd
    ngrok tcp 22
}

function Remove-NV-Cache {
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
    Write-Host "Done." -ForegroundColor Green
    Beep
}

function Read-Info {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        Write-Host "Administrator Rights: $isAdmin" -ForegroundColor Green
    } else {
        Write-Host "Administrator Rights: $isAdmin" -ForegroundColor Red
    }
    Write-Host "$($PSVersionTable.OS)" -ForegroundColor DarkCyan
    Write-Host "powershell version $($PSVersionTable.PSVersion)" -ForegroundColor DarkMagenta
    Write-Host "$(git --version)"
    Write-Host "node Version $(node --version)"
    Beep
}

function Watch-Perfomance-Usage {
    <#
        .SYNOPSIS
            Displays perfmance usage every 2 seconds.
        .DESCRIPTION
            This cmdlet displays Date & Time, CPU Usage %, Available RAM MB (%), GPU Usage %, GPU Memory usage MB every 2 seconds+.
    #>

    $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum
    while($true) {
        $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $cpuTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        $gpuMem = (((Get-Counter "\GPU Process Memory(*)\Local Usage").CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum
        $gpuUse = (((Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage").CounterSamples | Where-Object CookedValue).CookedValue | Measure-Object -sum).sum
        $date + ' > CPU: ' + $cpuTime.ToString("#,0.000") + '%, Available RAM: ' + $availMem + 'MB (' + (100 * $availMem / ($totalRam / 1MB)).ToString("#,0.0") + '%), GPU usage: ' + $([math]::Round($gpuUse,2)) + '%, GPU Memory: ' + $([math]::Round($gpuMem/1MB,2)) + 'MB'
        Start-Sleep -s 2
    }
}

function ffmpeg-Compress {
    <#
        .SYNOPSIS
            Compresses video using x265 codec with medium preset.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-Compress -Input video
            ffmpeg-Compress -Input video.mp4
            ffmpeg-Compress -Input video.mp4 -Output output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [Alias("Input", "Inp", "I", "Video")]
        [String]
        $inputFile,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Compression preset. Defaults to Medium")]
        [Alias("Fast")]
        [String]
        $preset,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-compressed.mp4 will be used")]
        [Alias("Output", "Out", "O")]
        [String]
        $outputFile
    )
    
    # process video file naming
    if (!$outputFile) {
        $file = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = "$file-compressed"
    } else {
        $extn = [IO.Path]::GetExtension($outputFile)
    }
    if (!$extn -or $extn -ne "mp4") {
        $outputFile = "$outputFile.mp4"
    }

    $preset = $preset ? $preset : "medium"

    ffmpeg -i $inputFile -c:v libx264 -crf 18 -preset $preset $outputFile

    Beep
}

function ffmpeg-Youtube {
<#
        .SYNOPSIS
            Compresses video using optimal settings for the youtube.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-Compress -Input video
            ffmpeg-Compress -Input video.mp4
            ffmpeg-Compress -Input video.mp4 -Output output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [Alias("Input", "Inp", "I", "Video")]
        [String]
        $inputFile,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-compressed.mp4 will be used")]
        [Alias("Output", "Out", "O")]
        [String]
        $outputFile
    )
    
    # process video file naming
    if (!$outputFile) {
        $file = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = "$file-compressed"
    } else {
        $extn = [IO.Path]::GetExtension($outputFile)
    }
    if (!$extn) {
        $outputFile = "$outputFile.mp4"
    }

    ffmpeg -i $inputFile -vf yadif,format=yuv422p -force_key_frames "expr:gte(t,n_forced/2)" -c:v libx264 -b:v 60M -bf 2 -c:a flac -ac 2 -ar 44100 -strict -2 -use_editlist 0 -movflags +faststart $outputFile

    Beep
}

function ffmpeg-RemoveAudio {
    <#
        .SYNOPSIS
            Removes audio from the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-RemoveAudio -Input video
            ffmpeg-RemoveAudio -Input video.mp4
            ffmpeg-RemoveAudio -Input video.mp4 -Output output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [Alias("Input", "Inp", "I", "Video")]
        [String]
        $inputFile,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Output filename, if no filename specified, <InputFileName>-noaudio.mp4 will be used")]
        [Alias("Output", "Out", "O")]
        [String]
        $outputFile
    )
    
    # process video file naming
    if (!$outputFile) {
        $file = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = "$file-noaudio"
    } else {
        $extn = [IO.Path]::GetExtension($outputFile)
    }
    if (!$extn) {
        $outExtn = [IO.Path]::GetExtension($inputFile) ? [IO.Path]::GetExtension($inputFile) : ".mp4"
        $outputFile = "$outputFile$outExtn"
    }

    ffmpeg -i $inputFile -an -c copy -y $outputFile

    Beep
}

function ffmpeg-ExtractAudio {
    <#
        .SYNOPSIS
            Extracts audio from the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-ExtractAudio -Input video
            ffmpeg-ExtractAudio -Input video.mp4
            ffmpeg-ExtractAudio -Input video.mp4 -Output output.m4a
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [Alias("Input", "Inp", "I", "Video")]
        [String]
        $inputFile,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Output filename, if no filename specified, <InputFileName>-audio.m4a will be used")]
        [Alias("Output", "Out", "O")]
        [String]
        $outputFile
    )
    
    # process video file naming
    if (!$outputFile) {
        $file = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = "$file-audio"
    } else {
        $extn = [IO.Path]::GetExtension($outputFile)
    }
    if (!$extn) {
        $outputFile = "$outputFile.m4a"
    }

    ffmpeg -i $inputFile -vn -acodec copy $outputFile

    Beep
}

function ffmpeg-ChangeSpeed {
    <#
        .SYNOPSIS
            Changes speed of the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-ChangeSpeed -Input video -Speed 1.5
            ffmpeg-ChangeSpeed -Input video.mp4 -Speed 0.5
            ffmpeg-ChangeSpeed -Input video.mp4 -Speed 1.3 -Output output.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [Alias("Input", "Inp", "I", "Video")]
        [String]
        $inputFile,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Video speed multiplier, to slow down video use values < 1")]
        [Alias("Spd", "S")]
        [Double]
        $speed,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Output filename, if no filename specified, <InputFileName>-x<speed>.mp4 will be used")]
        [Alias("Output", "Out", "O")]
        [String]
        $outputFile
    )

    # get video and audio speed
    $speed = 1 / $speed
    if (!$speed) {
        $speed = (0.5)
    }
    $audioSpeed = (1 / $speed)

    # process video file naming
    if (!$outputFile) {
        $file = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = "$file-x$(1 / $speed)"
    } else {
        $extn = [IO.Path]::GetExtension($outputFile)
    }
    if (!$extn) {
        $outExtn = [IO.Path]::GetExtension($inputFile) ? [IO.Path]::GetExtension($inputFile) : ".mp4"
        $outputFile = "$outputFile$outExtn"
    }

    ffmpeg -i $inputFile -vf "setpts=$speed*PTS" -filter:a "atempo=$audioSpeed" $outputFile

    Beep
}

function ffmpeg-Trim {
    <#
        .SYNOPSIS
            Trims the video.
        .LINK
            https://ffmpeg.org/documentation.html
        .EXAMPLE
            ffmpeg-ChangeSpeed -Input video -Start 01:40:00
            ffmpeg-ChangeSpeed -Input video.mp4 -Start 0:38:30 -End 1:10:10
            ffmpeg-ChangeSpeed -Input video.mp4 -Start 0:38:30 -End 1:10:10 -Output out.mp4
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Input filename, if no extension specified, mp4 will be used")] 
        [Alias("Input", "Inp", "I", "Video")]
        [String]
        $inputFile,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Start time of the video trimming. Note that you can use two different time unit formats: sexagesimal (HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678), or in seconds.")]
        [Alias("S, From, F")]
        [String]
        $start,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "End time of the video trimming. Note that you can use two different time unit formats: sexagesimal (HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678), or in seconds.")]
        [Alias("E, To, T")]
        [String]
        $end,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Output filename, if no filename specified, <InputFileName>-x<speed>.mp4 will be used")]
        [Alias("Output", "Out", "O")]
        [String]
        $outputFile
    )

    # return if neither start nor end defined
    if (!$start -and !$end) {
        Write-Host "End or start of the section to trim must be specified."
        return
    }

    # process video file naming
    if (!$outputFile) {
        $file = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = "$file-trimmed-$($start ? $start.Replace(":", ".") : "start")-$($end ? $end.Replace(":", ".") : "end")"
    } else {
        $extn = [IO.Path]::GetExtension($outputFile)
    }
    if (!$extn) {
        $outExtn = [IO.Path]::GetExtension($inputFile) ? [IO.Path]::GetExtension($inputFile) : ".mp4"
        $outputFile = "$outputFile$outExtn"
    }

    # if end is not defined use video length
    if (!$end) {
        $end = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $inputFile
    }
    
    $start = $start ? $start : 0

    ffmpeg -i $inputFile -ss $start -to $end $outputFile

    Beep
}

# DEFAULT DOWNLOAD PATH
$ytDownloadPath = "$env:USERPROFILE\Desktop"

function yt-Audio {
    <#
        .SYNOPSIS
            Downloads audio from the youtube video
        .LINK
            https://github.com/yt-dlp/yt-dlp
        .EXAMPLE
            yt-Audio https://youtu.be/dQw4w9WgXcQ
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Youtube video link")] 
        [Alias("Input", "Inp", "I", "Video", "Lnk", "L")]
        [String]
        $link
    )

    & yt-dlp -f 251 --extract-audio --audio-format opus --audio-quality 0 --embed-thumbnail --convert-thumbnails jpg --exec-before-download "magick convert %(thumbnails.-1.filepath)q -fuzz 25% -trim -quality 100 -sampling-factor 4:2:0 -define jpeg:dct-method=float %(thumbnails.-1.filepath)q" --add-metadata -P $ytDownloadPath  -o "%(creator)s - %(title)s.%(ext)s" "$link"
    Beep
}

function yt-Thumbnail {
    <#
        .SYNOPSIS
            Downloads audio from the youtube video
        .LINK
            https://github.com/yt-dlp/yt-dlp
        .EXAMPLE
            yt-Audio https://youtu.be/dQw4w9WgXcQ
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Youtube video link")] 
        [Alias("Input", "Inp", "I", "Video", "Lnk", "L")]
        [String]
        $link
    )

    & yt-dlp --write-thumbnail --skip-download -P $ytDownloadPath "$link"

    Beep
}

function Magick-ConvertSvgToPng {
    <#
        .SYNOPSIS
            Converts svg image to png
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "File name")] 
        [String]
        $filename,
        [Parameter(Mandatory = $false, Position = 10, HelpMessage = "Density")] 
        [String]
        $density = 1000
    )

    $newFilename = Modify-Filename $filename "magick" "png"

    magick convert +antialias -background none -density "$density" "$filename" "$newFilename"

    Beep
}

function Modify-Filename {
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "File name")] 
        [String]
        $filename,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Modifier")] 
        [String]
        $modifier,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Extension")] 
        [String]
        $extension
    )
    $file = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    if (!$extension) {
        $extension = [IO.Path]::GetExtension($filename)
    }
    return "$file-$modifier.$extension";
}

function Beep {
    <#
        .SYNOPSIS
            Makes system sound
    #>
    [System.Media.SystemSounds]::Hand.Play()
}