#!/usr/bin/env python3
"""Claude Code statusLine: shows context usage as "<tokens> | <model>"."""
import json
import subprocess
import sys


def fmt_tokens(t: int) -> str:
    if t >= 1_000_000:
        return f"{t / 1_000_000:.1f}M"
    return f"{t / 1_000:.1f}k"


def git_branch(cwd: str) -> str:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=cwd or None,
            capture_output=True,
            text=True,
            timeout=1,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return out.stdout.strip() if out.returncode == 0 else ""


def git_dirty(cwd: str) -> bool:
    try:
        out = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=cwd or None,
            capture_output=True,
            text=True,
            timeout=1,
        )
    except (OSError, subprocess.SubprocessError):
        return False
    return bool(out.stdout.strip())


def color_for(t: int) -> str:
    if t > 200_000:
        return "\x1b[31m"  # red
    if t > 100_000:
        return "\x1b[33m"  # yellow
    return ""


def pct_color(p: float) -> str:
    if p >= 90:
        return "\x1b[31m"  # red
    if p >= 70:
        return "\x1b[33m"  # yellow
    return "\x1b[32m"  # green


def usage_part(label: str, window: dict) -> str:
    """Format one rate-limit window as "label:NN%", or "" if unavailable."""
    p = (window or {}).get("used_percentage")
    if p is None:
        return ""
    return f"{label}:{pct_color(p)}{p:.0f}%\x1b[0m"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return
    cw = data.get("context_window") or {}
    usage = cw.get("current_usage") or {}
    tokens = (
        (usage.get("input_tokens") or 0)
        + (usage.get("cache_creation_input_tokens") or 0)
        + (usage.get("cache_read_input_tokens") or 0)
    )
    # Just the family name: "Opus 4.8 (1M context)" -> "Opus"
    model = ((data.get("model") or {}).get("display_name") or "?").split()[0]
    effort = (data.get("effort") or {}).get("level")  # absent if model has no effort param
    label = f"{model} ({effort})" if effort else model
    color = color_for(tokens)
    reset = "\x1b[0m" if color else ""
    parts = [f"{color}{fmt_tokens(tokens)}{reset}", label]
    cwd = data.get("cwd") or ""
    branch = git_branch(cwd)
    if branch:
        bcolor = "\x1b[33m" if git_dirty(cwd) else "\x1b[32m"  # yellow dirty / green clean
        parts.append(f"{bcolor}{branch}\x1b[0m")
    rl = data.get("rate_limits") or {}
    for part in (usage_part("5h", rl.get("five_hour")), usage_part("wk", rl.get("seven_day"))):
        if part:
            parts.append(part)
    sys.stdout.write(" | ".join(parts))


if __name__ == "__main__":
    main()
