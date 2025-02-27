function Invoke-ImportOrInstallModule([string]$module) {        
    if (-not (Get-Module -ListAvailable -Name "$module")) {
        Install-Module -Name "$module" -Scope CurrentUser -Force -SkipPublisherCheck -AllowPrerelease
    }

    Import-Module -Name "$module"
}

function Write-Formatted([string]$inputText) {
    $colorTags = @{
        'info'    = "`e[32m"         # Green
        'comment' = "`e[33m"         # Yellow
        'error'   = "`e[37;41m"      # White on Red
        'windows' = "`e[36m"         # Cyan
    }    
    $selfClosingTags = @{
        'info'    = "`e[32m!`e[0m"   # Green !
        'comment' = "`e[33m+`e[0m"   # Yellow +
        'error'   = "`e[31m-`e[0m"   # Red -
    }
    $parametrisedTags = @{
        'move-up'    = "`e[#A"       # Move Up
        'move-down'  = "`e[#B"       # Move Down 
        'move-right' = "`e[#C"       # Move Right
        'move-left ' = "`e[#D"       # Move Left
    }

    $resetTag = "`e[0m"              # Reset

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
        }
        elseif ($tagContent -like "/*" -and $stack.Count -gt 0 -and ($stack[$stack.Count - 1] -eq $tagContent.Substring(1) -or $tagContent -eq "/")) {
            $output += $resetTag
            $null = $stack.RemoveAt($stack.Count - 1)
                
            if ($stack.Count -gt 0) {
                $output += $colorTags[$stack[$stack.Count - 1]]
            }
        }
        elseif ($colorTags.ContainsKey($tagContent)) {
            $null = $stack.Add($tagContent)
            $output += $colorTags[$tagContent]
        }
        elseif ($tagContent -match '^([a-z0-9-_]+):(\d+)/$' -and $parametrisedTags.ContainsKey($matches[1])) {
            $tagName = $matches[1]
            $paramValue = $matches[2]

            $output += $parametrisedTags[$tagName] -replace '#', $paramValue
        }
        else {
            $output += "<$($tagContent)>"
        }

        $i = $endTag + 1
    }

    if ($stack.Count -gt 0) {
        $output += $resetTag
    }

    Write-Host $output;
}

function Invoke-NormalizeFilename(
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
    }
    else {
        $extension = [IO.Path]::GetExtension($outputPath)
    }

    if (!$extension) {
        $outputPath += ".$defaultExtension"
    }

    return $outputPath
}

function Test-FileExtenstion {
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
        Write-Formatted " <error/> File '$Filename' has invalid extension. Supported extensions are: $SupportedExtensionsString"
        return
    }
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command
    )

    $Result = Get-Command $Command -ErrorAction SilentlyContinue

    if (!$Result) {
        Write-Formatted " <error/> Command '$Command' is required to run this command"
        return
    }
}

function Invoke-Sound {
    [System.Media.SystemSounds]::Hand.Play()
}