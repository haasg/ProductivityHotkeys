#!/usr/bin/env python3
"""New agent: lease a warm worktree from treehouse, open it in herdr, run claude.

Bound to `Ctrl-Space Shift+C`. treehouse owns the worktree pool; herdr only
renders whatever treehouse hands out. See WORKFLOW.md.

Shared verbatim by Mac and Windows - only the interpreter name differs in the
herdr `[[keys.command]]` block (python3 vs python), same split as statusline.py.
"""

import json
import subprocess
import sys
import time
from pathlib import Path

# herdr discards the output of a `type = "shell"` binding, so a failed keypress
# would otherwise be silent.
LOG = Path.home() / ".herdr-agent.log"


def fail(msg):
    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with LOG.open("a", encoding="utf-8") as fh:
        fh.write(f"[{stamp}] new-agent: {msg}\n")
    print(msg, file=sys.stderr)
    raise SystemExit(1)


def run(cmd, cwd=None):
    proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if proc.returncode != 0:
        fail(f"{' '.join(cmd)} -> {proc.stderr.strip() or proc.stdout.strip()}")
    return proc.stdout


def herdr(*args):
    return json.loads(run(["herdr", *args]))["result"]


def focused_workspace():
    for ws in herdr("workspace", "list")["workspaces"]:
        if ws["focused"]:
            return ws["workspace_id"]
    fail("no focused herdr workspace")


def repo_root(workspace_id):
    """The MAIN checkout behind a workspace, whether or not it is a worktree.

    `workspace get` only carries a `worktree` block for workspaces that were
    themselves opened as worktrees, so it answers nothing for the ordinary case
    of pressing this key in the repo's own workspace. `worktree list` resolves
    the source repo for both.
    """
    source = herdr("worktree", "list", "--workspace", workspace_id, "--json")["source"]
    root = source["repo_root"]
    # herdr sometimes hands back a \\?\ extended-length path, which git rejects.
    return root[4:] if root.startswith("\\\\?\\") else root


def main():
    workspace_id = focused_workspace()

    # treehouse only finds a pool from the MAIN checkout: run it from inside a
    # linked worktree and it reports an empty pool, then starts a second one.
    repo = repo_root(workspace_id)

    # --lease prints the path on stdout and its banners on stderr.
    path = run(["treehouse", "get", "--lease", "--lease-holder", "herdr"], cwd=repo).strip()

    try:
        # Pool worktrees are detached at the default branch; `gh pr create` needs
        # a branch. `treehouse return` later resets the tree but leaves the ref.
        branch = time.strftime("agent/%Y%m%d-%H%M%S")
        run(["git", "-C", path, "switch", "-c", branch])

        opened = herdr("worktree", "open", "--workspace", workspace_id,
                       "--path", path, "--label", branch, "--focus", "--json")
        run(["herdr", "pane", "run", opened["root_pane"]["pane_id"], "claude"])
    except SystemExit:
        # A leaked lease is never handed out again and survives prune, so the
        # tree would be stranded for good.
        subprocess.run(["treehouse", "return", path, "--force"],
                       cwd=repo, capture_output=True)
        raise


if __name__ == "__main__":
    main()
