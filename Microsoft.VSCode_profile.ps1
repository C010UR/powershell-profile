# Change encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Environmental variables
$env:POSH = "DARK"
$env:EDITOR = "nvim"

# Local modules
Import-Module ~\Documents\PowerShell\utils.ps1
Import-Module ~\Documents\PowerShell\commands.ps1

# Other modules
# Invoke-ImportOrInstallModule('Terminal-Icons')
Invoke-ImportOrInstallModule('PSReadLine')
Invoke-ImportOrInstallModule('posh-git')
Invoke-ImportOrInstallModule('PowerType')

Enable-PowerType

$psReadLineOptions = @{
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

Set-PSReadLineOption @psReadLineOptions

Invoke-Expression (&starship init powershell)
# oh-my-posh --init --shell pwsh --config "$env:USERPROFILE\oh-my-posh\inasena.yaml" | Invoke-Expression

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })