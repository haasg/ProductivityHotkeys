# Bootstrap a new Windows machine for the keyboard-driven dev workflow.
# Run from anywhere: .\PC\setup.ps1   (safe to re-run; existing configs are backed up)
# See WORKFLOW.md for what all of this builds.

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

function Copy-WithBackup($src, $dest) {
    if (Test-Path $dest) {
        $bak = "$dest.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Move-Item $dest $bak
        Write-Host "  (existing $dest backed up to $bak)"
    }
    $dir = Split-Path $dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Copy-Item $src $dest
}

# ── 1. scoop + packages ─────────────────────────────────────
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}
scoop bucket add main
scoop bucket add extras
scoop bucket add nerd-fonts
scoop install neovim lazygit delta difftastic ripgrep fd fzf zoxide gh mingw pwsh JetBrainsMono-NF

# ── 2. rust-analyzer (needs rustup already installed) ───────
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    rustup component add rust-analyzer
} else {
    Write-Warning "rustup not found - install Rust from https://rustup.rs then run: rustup component add rust-analyzer"
}

# ── 3. git: delta pager + difftastic alias ──────────────────
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global merge.conflictstyle zdiff3
git config --global alias.dft "-c diff.external=difft diff"

# ── 4. LazyVim starter (only if no nvim config exists) ──────
$nvimDir = "$env:LOCALAPPDATA\nvim"
if (-not (Test-Path $nvimDir)) {
    git clone https://github.com/LazyVim/starter $nvimDir
    Remove-Item "$nvimDir\.git" -Recurse -Force
}

# ── 5. overlay configs from this repo ───────────────────────
# nvim: lazyvim.json (enables lang.rust extra) + plugin/option files
Copy-Item "$here\nvim\lazyvim.json" $nvimDir -Force
Copy-Item "$here\nvim\lua\config\options.lua" "$nvimDir\lua\config\" -Force
New-Item -ItemType Directory -Force "$nvimDir\lua\plugins" | Out-Null
Copy-Item "$here\nvim\lua\plugins\*.lua" "$nvimDir\lua\plugins\" -Force

Copy-WithBackup "$here\wezterm.lua" "$env:USERPROFILE\.wezterm.lua"
Copy-WithBackup "$here\lazygit-config.yml" "$env:LOCALAPPDATA\lazygit\config.yml"
Copy-WithBackup "$here\powershell-profile.ps1" "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# ── 6. bootstrap nvim plugins ───────────────────────────────
# First headless run can hit a benign "Package is already installing" race on
# tree-sitter-cli; the second run completes it. Parsers/mason tools finish
# installing on first interactive launch.
nvim --headless "+Lazy! sync" +qa
nvim --headless "+Lazy! sync" +qa

Write-Host ""
Write-Host "Done. Next: open nvim, let mason/treesitter finish, then run :checkhealth."
Write-Host "Gate: do not use until checkhealth is clean (see WORKFLOW.md troubleshooting)."
