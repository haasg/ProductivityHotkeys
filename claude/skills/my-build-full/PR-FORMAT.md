# PR conventions

`my-build-full`'s PR conventions: how a finished, proven change becomes a PR. The
repo-specific mechanics - the architecture-section format and vocabulary, the
Try-it command, the evidence bundle location, and the publish command with its
credential source - live in the repo profile's **PR & publish** section; where
this document and the profile differ, the profile wins.

## Branch & commit

- Create a branch named `build/<slug>` from the current branch (the uncommitted
  changes carry over). If that name is taken, append `-2`, `-3`, ... until it's
  free.
- Assemble what gets published at the profile's bundle location (see "Evidence
  bundle" below): the curated evidence bundle on a full-evidence run, the minimal
  proof page on a light one. Commit NOTHING from temp and no media - no screenshots, no
  clips, no plan/proof/review/retro `.md` files; if one ended up under the repo
  outside the profile's sanctioned gitignored homes, remove it before committing.
- Run the profile's fmt command first (if it names one) so the commit is
  format-clean; if fmt reflows a file outside the logical diff, leave that file
  out of the commit. Run any per-file hygiene rule the profile names (e.g. strict
  headers, annotations).
- **Text-hygiene before commit:** scan your diff for introduced BOMs, mojibake
  (double-encode artifacts - mind files carrying non-ASCII), whitespace-only hunks
  in files you had no reason to touch, and botched-replace artifacts (stray
  brackets, an old identifier surviving in comment prose). Test gates cannot see
  text corruption; this scan is its only gate.
- Stage the source/doc changes with `git add -A` scoped to the change - never
  `git add -u`/`commit -am`, which drop untracked new files and would ship a
  reference to a file without the file it names. Before committing, check
  `git status --porcelain` for stray `??` source files under the touched areas -
  an untracked new file at this point is a dropped feature waiting to happen. Then
  make ONE commit summarizing the change.
- **Sync with the default branch before opening.** A lot is usually in flight, so
  it may have advanced during the run. After committing, `git fetch origin
  <default>` then `git merge origin/<default>`. If the merge brought in ANY
  commits - conflicts or not - re-run the profile's check gate plus the touched
  units' tests: the proof ran against the pre-merge tree, and a semantic conflict
  (incoming work breaking this change with no textual overlap) is invisible to
  git. If the merge had textual conflicts, resolve them - keep both this change's
  intent and the incoming work - then run the profile's full gate instead: the
  resolution is code no stage has tested. The profile may additionally require
  re-running live validation for the paths this change moved - honor it. Only then
  open the PR. Merge brought in nothing -> nothing to do.
- Open a ready-for-review PR against the default branch with `gh`. If `gh` isn't
  authenticated: leave the commit on the branch and report "PR not opened: gh not
  authed" with the branch name (skip the publish too - there is no PR number to
  publish under).
- After the PR exists, publish - the bundle on a full run, the proof page on a
  light one - and edit the review URL into the body (see "Publish & link"
  below). Every run publishes; only what gets published scales.
- **CI tail.** Once the PR is open and the evidence link is in, run
  `gh pr checks <number>`. No checks reported -> the repo has no
  PR CI; you're done. Otherwise wait for the checks to conclude (poll; cap the
  wait at ~15 minutes). On a failure, make AT MOST ONE fix attempt - read the
  failing log, fix, commit, push, re-check once - then stop either way and report
  the final CI state alongside the PR URL ("CI green" / "CI red: <reason>" / "CI
  still running after 15m"). Never loop past one attempt; a persistently red PR is
  the human's call.

## PR body - baseline sections

Keep prose minimal; let the images carry the proof. (SKILL.md layers its own extra
sections on top - the Reviews line, a findings section per review lane that ran,
and, on a full retro, the Token & time audit.)

- **Objective** - 1-2 sentences.
- **Architecture changes** - how the structure shifted, as an ASCII tree in a
  fenced code block. NO Mermaid, no flow diagrams. Derive it from `git diff` plus
  the repo layout: affected units under their path with box-drawing characters
  (`|- \`- `), each tagged `NEW`/`MODIFIED`/`REMOVED`/`MOVED` with a few words on
  its responsibility and the boundary-relevant change; call out NEW units
  prominently (a new unit is a structural event). The profile's **PR & publish**
  section gives this repo's exact format: its unit vocabulary, and the
  cross-cutting wiring lines to add under the tree (dependency edges,
  registrations, boot-order changes - whatever the repo's boundary graph is made
  of). If the change is internal to one unit with no structural delta, replace the
  tree with a single line naming the internal change.
- **Try it** - the exact copy-paste for a human to drive the change live, as a
  fenced code block: `cd <absolute path of the working tree the PR branch is
  checked out in>` on one line, the profile's Try-it launch command on the next.
  Verify the path with `git rev-parse --show-toplevel` before writing it; the
  reviewer shouldn't have to track the worktree down.
- **Validation** - two variants. `my-build-full`'s plan picks which, in its
  **Scope & risk** section, and **full is the default**:
  - **Full** - the evidence link, and nothing else: the section is
    `[Validation evidence](<review URL>)` - the published evidence page (see
    "Publish & link" below; use the placeholder `_evidence: publishing..._` at
    creation and `gh pr edit` the real URL in once the publish succeeds, or the
    bundle's local path if the publish failed). The claim-by-claim story lives on
    that page, told once, with each clip/screenshot rendered beside the claim it
    proves - do not restate it as prose here.
  - **Light** - the same shape, pointing at a humbler page: the section is
    `[Proof artifact](<review URL>)` - the published proof page (the proof
    artifact rendered as-is with its media; see "Evidence bundle" below). Same
    placeholder-then-`gh pr edit` flow as full. Do NOT copy the validation
    claims into the PR body - the claims are told once, in the proof artifact,
    and a duplicated list drifts from its source and doubles the read. Only if
    the publish itself failed does the section fall back to
    `Proof artifact: <absolute local path>` beside the reported publish error.

  Either way: the section is one clickable link, no claim-by-claim prose; embed
  no images in the PR body and commit none. Never write "tests pass" or "gate
  clean" as the proof - a green gate is a baseline requirement, not validation
  evidence. And light scales the *packaging*, never the *proving*: the change
  was still driven live and captured per EVIDENCE.md before the PR stage ever
  ran.

## Evidence bundle (load-bearing mechanics)

Both run kinds publish; what differs is curation. A **full**-evidence run
assembles the curated bundle described below. A **light**-evidence run skips the
curation and publishes the proof artifact itself as a minimal page: at the same
profile bundle location, write an `index.html` that mechanically renders the
proof artifact's content - its text as-is, unedited, with each screenshot/clip it
names embedded by relative path beside its mention - and copy that media in. No
re-authoring, no renaming, no claim-by-claim layout: light trims the curation,
never the publish. The publish contract below binds both pages.

The proof media ships as a self-contained bundle at the profile's bundle location,
NOT as committed images:

- **Location.** The profile names it, including how to discover the right root
  when workers run in worktrees. Never write the bundle anywhere else.
- **Contents.** An `index.html` plus the clips/screenshots it references, renamed
  descriptively from what each shows (e.g. `knight-runs-east.gif`,
  `after-newgame.png`). Media paths in the HTML are relative (the bundle must
  survive being moved or zipped); no base64 embedding for large media.
- **The page tells the validation story** claim-by-claim - it is the only place
  that story is told, since the PR's Validation section is just the link: each
  claim as a line of text (the scenario run, the concrete observed results vs what
  was expected) with its clip/screenshot rendered immediately beside it. A reviewer
  opens one page and sees every claim against its evidence. Lead with the motion
  clip for anything that moves; for an asset swap, lead with the before/after.
- **Publish rules.** The bundle is what gets published, so it must satisfy the
  publish contract the profile points at: `index.html` at the bundle root, all
  media referenced by relative path, fully self-contained (no CDN/external
  references - the viewer's CSP hard-blocks them; inline CSS/JS is fine), media in
  the supported types. Use `<video controls preload="metadata">` for clips.

## Publish & link (load-bearing mechanics)

Reviewers see the bundle through the evidence library (private, immutable,
login-protected), not from disk:

- Publish AFTER `gh pr create` returns the PR number - the URL is keyed to it.
  Run the profile's publish command exactly, including its credential-sourcing
  rule (never print credential values).
- On success stdout is the review URL. `gh pr edit <number>` the URL into the
  Validation section's placeholder. Nothing is printed until every upload
  succeeded, so any URL you get is live.
- Every publish mints a fresh immutable URL; re-publish (and re-link) rather than
  expecting to update a published page.
- **Fallback:** if the publish fails (missing env, network), keep the PR:
  reference the local path in the Validation section (the bundle's on full, the
  proof artifact's on light) and report the publish error alongside the PR URL -
  the publish is never a reason to block or close the PR.
