#!/usr/bin/env python3
"""Return the focused worktree to the treehouse pool and close its workspace.

Bound to `Ctrl-Space Shift+X`, replacing herdr's built-in remove_worktree - that
one runs `git worktree remove`, which would delete a pool member and throw away
the warm build cache treehouse exists to preserve.

Shared verbatim by Mac and Windows. See WORKFLOW.md.
"""

import json
import subprocess
import sys
import time
from pathlib import Path

LOG = Path.home() / ".herdr-agent.log"


def fail(msg):
    stamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with LOG.open("a", encoding="utf-8") as fh:
        fh.write(f"[{stamp}] return-agent: {msg}\n")
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


def strip_unc(path):
    """herdr sometimes hands back a \\\\?\\ extended-length path, which git rejects."""
    return path[4:] if path.startswith("\\\\?\\") else path


def main():
    workspace_id = focused_workspace()

    # Only workspaces opened as worktrees carry this block, so its absence is
    # exactly the "you are in the repo's own workspace" case.
    worktree = herdr("workspace", "get", workspace_id)["workspace"].get("worktree")
    if not worktree or not worktree.get("is_linked_worktree"):
        fail("focused workspace is the main checkout, not a pooled worktree")

    repo = strip_unc(worktree["repo_root"])
    # herdr reports checkout_path with forward slashes, including on Windows.
    path = str(Path(strip_unc(worktree["checkout_path"])))

    # Close first: `treehouse return` kills lingering processes in the tree, and
    # the pane's own shell counts as one.
    run(["herdr", "workspace", "close", workspace_id])

    # treehouse refuses any path it does not manage, so this cannot delete a
    # hand-made worktree even if the is_linked_worktree guard above is wrong.
    proc = subprocess.run(["treehouse", "return", path, "--force"],
                          cwd=repo, capture_output=True, text=True)
    if proc.returncode != 0:
        fail(f"workspace closed but the lease was NOT released: "
             f"{proc.stderr.strip()} - recover with: treehouse return {path} --force")


if __name__ == "__main__":
    main()
