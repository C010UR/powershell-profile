# environmental variables

$env:POSH="DARK"

# Set PSReadLine options
$PSReadLineOptions = @{
    PredictionSource = "None"
    PredictionViewStyle = "InlineView"
    WordDelimiters = ";:,.[]{}()/\|^&*-=+'""–—―_"
    Colors = @{
        "Command"                   = [ConsoleColor]::Yellow
        "Comment"                   = "`e[97;42m"
        "ContinuationPrompt"        = [ConsoleColor]::White
        "Default"                   = [ConsoleColor]::White
        "Emphasis"                  = "`e[93;40m"
        "Error"                     = [ConsoleColor]::Red
        "InlinePrediction"          = "`e[90m" # bright black fg
        "Keyword"                   = [ConsoleColor]::Green
        "ListPrediction"            = [ConsoleColor]::DarkYellow
        "ListPredictionSelected"    = "`e[100m"
        "Member"                    = [ConsoleColor]::White
        "Number"                    = [ConsoleColor]::DarkYellow
        "Operator"                  = [ConsoleColor]::White
        "Parameter"                 = [ConsoleColor]::Cyan
        "Selection"                 = "`e[30;47m"
        "String"                    = [ConsoleColor]::Blue
        "Type"                      = [ConsoleColor]::DarkBlue
        "Variable"                  = [ConsoleColor]::Green
    }
}
Set-PSReadLineOption @PSReadLineOptions

# init oh-my-posh with a theme
oh-my-posh --init --shell pwsh --config "$env:USERPROFILE\oh-my-posh\inasena.json" | Invoke-Expression

# import modules
Import-Module -Name Terminal-Icons
Import-Module -Name posh-git

# change encoding to UTF-8
chcp 65001

# clear terminal after initialization
Clear-Host