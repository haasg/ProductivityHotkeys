# PowerShell profile - the Windows mirror of the Mac zsh block in dotfiles/home.nix.
# Kept deliberately close to it: starship prompt, history autosuggestions with
# Ctrl+f to accept, EDITOR=nvim, and the same short git aliases.
# Live path: ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 (symlinked by link-configs.ps1).

$env:EDITOR = 'nvim'

# --- prompt: starship (same prompt binary as the Mac) ---
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# --- autosuggestions: ghost text from history, Ctrl+f to accept (zsh: bindkey '^f' autosuggest-accept) ---
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion

# --- aliases (mirror of shellAliases in home.nix) ---
# PowerShell aliases can't carry arguments, so the git ones are thin functions.
function .. { Set-Location .. }
function gst { git status @args }
function add { git add . }
function push { git push @args }
function pull { git pull @args }
function m { git switch main }
function cc { claude @args }

# --- optional PC-only niceties (not on the Mac; uncomment if you want them) ---
# if (Get-Command zoxide -ErrorAction SilentlyContinue) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
# Set-Alias lg lazygit
