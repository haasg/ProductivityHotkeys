# Bootstrap CLI tooling on a new Windows machine (mouseless workflow).
# Installs scoop if missing, then the tool list.

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

scoop bucket add main
scoop bucket add extras

scoop install neovim lazygit delta difftastic ripgrep fd fzf zoxide gh mingw
