---
name: my-grab-ticket
description: Grab a ticket from the repo's work queue - a specific ID if given as an argument, else the best available one, favouring priority while skipping tickets that are blocked or collide with work already in progress - move it to In Progress, stamp the current Claude session on it, and start a grill session on the ticket's topic. Use when the user wants to pull the next work item from the backlog and start planning it.
---

<what-to-do>

Pull one ticket from the repo's work queue and turn it into a grill session.

**Step 0 - load the repo profile.** This skill is shared across repos; the
work-queue tooling comes from a profile.

1. Resolve the key: the basename of `git remote get-url origin`, minus `.git`
   (so `https://github.com/haasg/PixelGenerator.git` gives `PixelGenerator`). It
   is stable across worktrees. No git repo or no `origin`? Use the repo root
   directory name.
2. Read `$env:USERPROFILE\.claude\skill-profiles\<key>.md` and find its
   **Work queue** section.
3. If there is no profile for the key, or its Work queue section is missing or
   "None configured", STOP and say so - a queue skill must never guess which
   tracker a repo uses. Point at
   `ProductivityHotkeys/claude/profiles/<key>.md` as the place to configure it.

Then, using the queue CLI the profile names:

1. **Pick the ticket.** If the invocation argument names an issue (e.g.
   `CHA-12`), that is the ticket - fetch it in full and take it even if the
   checks below flag it, but still run them and say what they found. A named
   ticket is honoured, never silently overridden.

   Otherwise choose one. The aim is a ticket that can actually be worked right
   now - not merely the one at the top of the list:

   a. **Shortlist.** List the queue and take the top ~5 issues in the profile's
      grabbable state(s) as candidates, in the CLI's own order. From the same
      listing, note every issue in a started state; that, plus any local
      in-flight signal the profile names, is the work already underway.
   b. **Read.** Fetch each candidate in full, and each started issue too - a
      one-line title badly under-describes what a ticket touches.
   c. **Disqualify.** Drop a candidate that hits either:
      - **Unmet prerequisite.** Its description names another issue as a
        precondition - "blocked by", "depends on", "after X lands", "once X
        ships". Resolve that issue's state; if it is not done or cancelled, drop
        the candidate. Judge from the sentence, not the bare ID: "see CHA-3 for
        context" is a pointer, not a dependency. An unmet prerequisite that is
        itself grabbable is a hint - consider it as a candidate in its own right.
      - **Collision with in-flight work.** It would edit the same ground as
        something already started. Same file, same module boundary, or the same
        contract or data shape disqualifies. Merely the same broad subsystem is
        a warning to weigh, not a veto.
   d. **Rank the survivors.** Priority field first, as the tracker reports it.
      Then importance you can actually justify from the text: it unblocks other
      queued tickets, it fixes something broken or user-visible, or later
      candidates name it as their prerequisite. Then the CLI's own order as the
      tiebreak.
   e. **Pick the top, and say why in one line** - including the higher-ranked
      candidate you skipped and what disqualified it. This ranking is a
      heuristic on thin evidence, so the skip has to be visible; that is what
      lets the user overrule it by naming a ticket instead.
   f. **Nothing survives?** Widen to the next batch of candidates once. If that
      is also empty, do not quietly claim a colliding or blocked ticket - report
      the shortlist with each rejection reason and ask which to take.

   If nothing is grabbable at all, report that and stop.
2. **Claim it.** Move it to In Progress.
3. **Stamp this session on it.** Post a note on the ticket naming the Claude
   session that claimed it, so a session lost later can be found and resumed
   rather than guessed at. Gather:
   - `$env:CLAUDE_CODE_SESSION_ID` - the resumable session ID. It is set for
     every Claude Code session; if it is somehow empty, skip this step and say
     so rather than posting a note with a blank ID.
   - The directory the session runs in (`git rev-parse --show-toplevel`, else
     the cwd). `--resume` only finds a session from the directory it started in,
     so a worktree path must be recorded exactly as-is, not normalised to the
     main checkout.
   - The branch (`git rev-parse --abbrev-ref HEAD`) and the machine name
     (`$env:COMPUTERNAME`, or `hostname`).

   Post it with the profile's note verb, in this shape:

   ```
   Claude session `<session-id>`
   Resume: `cd <dir>` then `claude --resume <session-id>` (on <machine>)
   Branch `<branch>` - claimed <YYYY-MM-DD HH:mm>
   ```

   This is best effort. If the profile names no note verb, or the post fails,
   print the same block to the user and carry on - a failed stamp must never
   leave the ticket claimed but unreported. Do not edit the ticket description
   to work around a missing note verb.

   Grabbing the same ticket again later just adds another note; the newest one
   names the session that currently holds it.
4. **Report.** One line to the user: ticket ID, title, and URL, now In Progress,
   plus whether the session stamp landed.
5. **Grill it.** Invoke the `my-grill` skill with the ticket as its topic - pass
   the ID, title, and the full description text as the argument so the grill
   starts with a real topic, never an unfilled placeholder.

Marking the ticket done is NOT part of this skill - that happens when the
resulting work actually ships: `/my-build-full`'s ticket linkage closes it when
the PR opens (grab-ticket -> grill -> build-full is the intended arc).

</what-to-do>
