---
name: my-grab-ticket
description: Grab a ticket from the repo's work queue (a specific ID if given as an argument, else the top of the Todo queue), move it to In Progress, and start a grill session on the ticket's topic. Use when the user wants to pull the next work item from the backlog and start planning it.
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
   `CHA-12`), that is the ticket. Otherwise list the queue and take the topmost
   issue in the profile's grabbable state(s). If nothing is grabbable, report
   that and stop.
2. **Read it.** Fetch the full ticket - title, description, URL.
3. **Claim it.** Move it to In Progress.
4. **Report.** One line to the user: ticket ID, title, and URL, now In Progress.
5. **Grill it.** Invoke the `my-grill` skill with the ticket as its topic - pass
   the ID, title, and the full description text as the argument so the grill
   starts with a real topic, never an unfilled placeholder.

Marking the ticket done is NOT part of this skill - that happens when the
resulting work actually ships.

</what-to-do>
