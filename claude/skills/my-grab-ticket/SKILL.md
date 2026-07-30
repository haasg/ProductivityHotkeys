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

1. **Pick the ticket - in a subagent.** Selection is delegated to the
   `my-ticket-picker` agent (defined next to this skill, junctioned into
   `~/.claude/agents`; pinned to low-effort Opus so picking never burns
   premium-model credits). It owns the selection doctrine: shortlist the queue,
   read candidates in full, disqualify blocked or colliding ones, rank the
   survivors. Spawn it synchronously (`subagent_type: my-ticket-picker`,
   `run_in_background: false`) and pass, verbatim:

   - the profile's **Work queue** section,
   - the repo root path (the queue CLI runs from there),
   - the invocation argument, if it names an issue (e.g. `CHA-12`). A named
     ticket is honoured, never silently overridden - the picker still runs its
     checks and reports what they flagged.

   The picker returns either the chosen ticket - ID, title, URL, priority, full
   description, a one-line estimated-scope line (`small` / `standard` /
   `large` plus the main risk), and a one-line rationale naming any
   higher-ranked candidate it skipped and why - or a no-survivor report listing
   each candidate with its rejection reason. Relay both the rationale and the
   scope estimate to the user; the skip has to be visible, since naming a ticket
   is how the user overrules the heuristic. On a no-survivor report, present it
   and ask which ticket to take. If nothing is grabbable at all, report that and
   stop.

   If the `my-ticket-picker` agent type is unavailable, read its definition
   file and run the same doctrine inline, and say so - never silently invent a
   different selection scheme.
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
4. **Compose the report - but never emit it mid-turn.** Text written between
   tool calls does not reach the desktop transcript; a report printed here and
   followed by the grill invocation is silently swallowed (2026-07-30: the
   session-name block never showed up). Only a turn's FINAL message - no tool
   calls after it - reliably renders. So compose the report now and carry it:
   the first message that ends a turn MUST open with it, before any other
   content. On the normal path that is the grill's opening round (step 5); on
   any path that stops short (no-survivor report, empty session ID, failed
   claim), the stopping message itself is final, so lead with whatever parts of
   the report exist. The report, in order:

   - **Session name to copy.** The desktop app names every grab-ticket session
     after this skill, so sessions are indistinguishable until renamed by hand.
     There is no tool that can rename the *current* session, so hand the user
     the name instead: print a fenced code block (code blocks get a copy button
     in the app) containing exactly one line - a compressed version of the
     ticket's title, eight words maximum, no ticket ID and no trailing
     punctuation, e.g. `herdr pane hotkeys`. Compress by dropping filler
     words, never by abbreviating domain terms into something unrecognisable.
   - **Ticket link.** Directly under the block, the ticket URL as a markdown
     link labelled with the ID and full title, so the ticket opens in the
     browser with one click.
   - **Status.** One line: ticket now In Progress, plus whether the session
     stamp landed.
5. **Grill it.** Invoke the `my-grill` skill with the ticket as its topic - pass
   the ID, title, and the full description text as the argument so the grill
   starts with a real topic, never an unfilled placeholder. Append the picker's
   scope line to that argument, labelled as what it is: a seed for the grill's
   own sizing step to confirm or override, e.g. `Picker scope seed (not
   binding - confirm or override): small - one prompt file; risk: ...`. The
   picker read only the ticket; the grill reads the code, so the grill's call
   wins.

   The grill's opening round is normally this turn's final message - open it
   with the step-4 report (name block, ticket link, status line) before any
   grill content, so the report actually lands in the transcript.

Marking the ticket done is NOT part of this skill - that happens when the
resulting work actually ships: `/my-build-full`'s ticket linkage closes it when
the PR opens (grab-ticket -> grill -> build-full is the intended arc).

</what-to-do>
