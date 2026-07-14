#Requires -Version 5.1
<#
    link-configs.ps1 - one place that declares every dotfile symlink for this machine.

    This is the Windows analog of the Mac side's nix `mkOutOfStoreSymlink` block
    (dotfiles/home.nix): each row maps a LIVE location (where the app looks for
    its config) to the TARGET repo file (the real, version-controlled source of
    truth). Running this makes each live path a symlink into the repo, so you
    only ever edit the repo copy and git tracks every change - and both machines
    read the SAME files where possible (wezterm, nvim, AGENTS.md).

    Safe to re-run:
      - already correct  -> left alone
      - wrong/stale link -> repaired
      - a real file/dir  -> backed up to <name>.bak-<timestamp> before linking

    Creating symlinks on Windows needs elevation OR Developer Mode. If you get an
    "access denied" / privilege error, either:
      - run this from an elevated PowerShell (Start > "PowerShell" > Run as administrator), or
      - turn on Settings > System > For developers > Developer Mode once, then run it normally.

    To ADD a config later: append one row to $links below. That row is both the
    setup step and the documentation of what points where.
#>

$here = $PSScriptRoot                       # ...\ProductivityHotkeys\PC
$repo = Split-Path $here -Parent            # ...\ProductivityHotkeys
$dot  = Join-Path $repo 'dotfiles\home'     # shared (Mac + Windows) config tree

# Live path  ->  repo file. Shared rows point into dotfiles\home so Windows reads
# the exact same file the Mac reads; Windows-only rows point into PC\.
$links = @(
    # Terminal + nvim: identical files on both platforms (OS branches live inside them).
    @{ Link = "$env:USERPROFILE\.config\wezterm\wezterm.lua"; Target = "$dot\.config\wezterm\wezterm.lua" }
    @{ Link = "$env:LOCALAPPDATA\nvim";                       Target = "$dot\.config\nvim" }

    # herdr: Windows needs its own config (the [[keys.command]] shell block differs).
    # Windows config dir is %APPDATA%\herdr, NOT ~/.config/herdr (that's the Mac path).
    # Linking the Mac path here is a silent no-op: herdr reads %APPDATA% and your
    # keybindings never load.
    @{ Link = "$env:APPDATA\herdr\config.toml";              Target = "$here\herdr-config.toml" }

    # ...but the two scripts its Shift+C / Shift+X bindings call ARE shared with the Mac.
    @{ Link = "$env:APPDATA\herdr\new-agent.py";             Target = "$dot\.config\herdr\new-agent.py" }
    @{ Link = "$env:APPDATA\herdr\return-agent.py";          Target = "$dot\.config\herdr\return-agent.py" }

    # treehouse: owns the git-worktree pool that Shift+C leases from. Unlike herdr it
    # reads ~/.config on Windows too, so this file is shared with the Mac verbatim.
    @{ Link = "$env:USERPROFILE\.config\treehouse\config.toml"; Target = "$dot\.config\treehouse\config.toml" }

    # Global agent instructions - shared verbatim with Mac (Claude reads CLAUDE.md, Codex reads AGENTS.md).
    @{ Link = "$env:USERPROFILE\.claude\CLAUDE.md";          Target = "$dot\AGENTS.md" }
    @{ Link = "$env:USERPROFILE\.codex\AGENTS.md";           Target = "$dot\AGENTS.md" }

    # PowerShell profile (the zsh-equivalent): pwsh loads it from Documents.
    @{ Link = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"; Target = "$here\powershell-profile.ps1" }

    # NOTE: ~/.claude/settings.json is intentionally NOT shared - it hardcodes a
    # Mac path and python3 for the statusLine. setup.ps1 writes the Windows one.
)

# WezTerm looks for ~/.wezterm.lua BEFORE ~/.config/wezterm/wezterm.lua, so a
# leftover file there silently shadows the symlink below and none of this repo's
# WezTerm config loads. That is not hypothetical: the pre-herdr config lived
# there, kept Ctrl+Space as a WezTerm *leader*, and ate herdr's prefix whole.
# Nothing in the repo is supposed to install it, so its presence is always drift.
$shadow = "$env:USERPROFILE\.wezterm.lua"
if (Test-Path -LiteralPath $shadow) {
    $shadowBak = "$shadow.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $shadow -Destination $shadowBak
    Write-Warning "shadow  $shadow outranks the repo's wezterm.lua - moved to $shadowBak"
}

foreach ($l in $links) {
    $link   = $l.Link
    $target = $l.Target

    if (-not (Test-Path -LiteralPath $target)) {
        Write-Warning "SKIP  source missing: $target"
        continue
    }
    # Normalize so the "already correct" comparison below isn't defeated by ..\ segments.
    $target = (Resolve-Path -LiteralPath $target).Path

    # Ensure the parent directory of the link exists (e.g. ~\.config\wezterm\).
    $parent = Split-Path -Parent $link
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    # Displacing the old path and creating the link must be all-or-nothing: creating a
    # symlink needs elevation/Developer Mode, and a failure here used to leave the live
    # path EMPTY (the real config already moved to .bak). Track what we displaced so the
    # catch can put it back.
    $backup = $null
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $target) {
            Write-Host "ok    $link"
            continue
        }
        if ($existing.LinkType) {
            # A link, but pointing somewhere else - replace it.
            Remove-Item -LiteralPath $link -Force -Recurse
            Write-Host "fix   removed stale link at $link"
        }
        else {
            # A real file/dir - preserve it before we replace it with a link.
            $backup = "$link.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Move-Item -LiteralPath $link -Destination $backup
            Write-Host "save  backed up real path -> $backup"
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null
        Write-Host "link  $link -> $target" -ForegroundColor Green
    }
    catch {
        Write-Warning "FAIL  $link : $($_.Exception.Message)"
        Write-Warning "      (need an elevated shell or Developer Mode - see the header of this script)"
        if ($backup) {
            Move-Item -LiteralPath $backup -Destination $link
            Write-Warning "      restored the original file - $link is unchanged"
        }
    }
}

# Audit: show the current state of every managed link so this script doubles as
# the "what is linked to what" report.
Write-Host "`n--- managed links ---"
$links |
    ForEach-Object { Get-Item -LiteralPath $_.Link -Force -ErrorAction SilentlyContinue } |
    Where-Object { $_ } |
    Format-Table FullName, LinkType, Target -AutoSize
