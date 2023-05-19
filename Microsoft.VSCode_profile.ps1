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

# change encoding to UTF-8
chcp 65001

# clear terminal after initialization
Clear-Host