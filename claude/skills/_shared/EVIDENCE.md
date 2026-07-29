# Proof & evidence doctrine

`my-build-full`'s proof doctrine - the universal rules. The repo's concrete proof
mechanics (drivers, verbs, readiness checks, evidence homes, and hard-won repo
lessons) live in the repo profile's **Proof surface** section; both documents are
binding on the implementing agent. Plan docs' **Validation plan** sections are
written against this doctrine. When a run teaches a new evidence lesson, the
generic form is folded in here and the repo-specific form into the profile.

## Reach observable behavior LIVE

Run the plan's validation scenario on the profile's proof surface and confirm the
observations match the predictions. Derive the live scenario from what THIS diff
changed - the plan's scenario is the floor, not the ceiling. A standard demo ride
proves nothing about the paths you moved unless it exercises them with NON-DEFAULT
values: don't prove a camera refactor without panning and zooming, or an input
change without pressing that input. Don't lean on a unit test for something the
live surface can show.

If the change is NOT observable (pure refactor, type-only, a behavior-preserving
swap), the profile's check/full gates stand in - a green existing suite IS the
proof for a behavior-preserving change. But when a behavior IS observable, specify
and run a concrete scenario that reaches it live, including any seed/setup needed
to put the condition in range. Do not pre-authorize a unit-test fallback for an
observable behavior - the most interesting emergent behavior is often the hardest
to reach, and a stand-in lets everyone skip proving it live (this has happened: an
observable transition shipped that no live run ever showed). Defer to a unit test
only when reaching the behavior live is genuinely impossible, and say why.

## Add the instrumentation you need

If a code path you are writing has no observable row, attribute, or visible
effect, part of the change is adding the lightweight instrumentation (a log row,
an assertion surface) that makes it verifiable - never report a path proven that
nothing could observe. Adding an observability row at a decision point in code you
are already writing is normal instrumentation, not net-new tooling. Building a new
validation *surface* (a new driver verb, a new query channel) is net-new tooling -
that stops the run (see below).

## Screenshots are the default evidence for anything visible; video for anything that moves

If the change touches anything on-screen (a sprite, a HUD, a panel, a color, a
layout), capture a screenshot at each meaningful moment - not numbers alone - each
named so its meaning is unambiguous. Pictures over prose, every time it's
possible. If the change makes anything MOVE - an animation, movement, a fade, a
transition - record it with the profile's recording mechanism; the clip is the
default evidence for motion, with screenshots kept for the static states around
it. A still frame of a walk proves a pose, not the walk. Save shots and clips to a
run-unique subdir of the OS temp dir or the profile's sanctioned gitignored homes,
never loose in the repo tree; the PR step assembles them into the evidence bundle
(see PR-FORMAT.md). Only fall back to numbers-only proof when there is genuinely
nothing visible to show. For an asset swap, the before/after of the asset in place
is the lead evidence.

**A clip must cover the full scenario, with a 5-second floor.** Record a beat of
steady lead-in, the behavior itself, and the settled end state it leaves behind,
at real-time playback speed - never sped up, never trimmed to just the moving
frames. **Five seconds is the minimum**; a clip under the floor, or one too short
for a reviewer to judge the motion it exists to show, is a flagged finding, not
acceptable evidence (this has happened: few-frame clips shipped as compliant proof
because no duration rule existed). If the behavior itself is briefer than the
floor, pad it with the steady states around it - lead-in and settle are part of
what a reviewer reads.

**Evidence scales with content risk, not visual surface.** A change adding N
player-facing content/decision paths owes evidence per path: a shot of each path
live, or an explicitly-justified note tying it to a live-proven twin (same
machinery, named). When the N paths are **functionally identical** - one
mechanism, one row shape, content-only variation - a few representative shots
typically suffice; name which paths ride the sample. A path with its own gate,
cost, or effect wiring is not "identical" and owes its own evidence. An unshot
path is an unreviewed path.

## An "unreachable" visual is a claim to prove, not an excuse

When some shipped visual state genuinely cannot be captured through the proof
surface (e.g. it renders only while a pointer is held and the driver can't hold
one), a logic-only unit test must NOT silently stand in for it. Record the exact
steps you tried and why they cannot reach the state, then prove that state at the
highest level that CAN read it - typically a pure assertion on the read-time
query/mapping that drives it. A logic-only test that never touches the mapping is
not a stand-in. (This has happened: a press/depress visual shipped "Done" with no
test or screenshot touching the code that renders it.)

## A leg with missing named evidence is PARTIAL, never "matched"

When a validation leg's named artifact (a screenshot, a clip, a log dump) could
not be captured, grade that leg PARTIAL/UNPROVEN and say why - code-read reasoning
beside a missing artifact is a disclosed gap, not a pass. (This has happened: a
leg was graded "matched predictions" while its named screenshot was never captured
and the visual it existed to prove was never observed.) For a state that exists
only briefly, capture BEFORE advancing past it: step to the moment, capture, then
advance.

## Prove the human input path

An agent driver can reach the same end state by a DIFFERENT code path than the
human's, pass every agent check, and still ship the human path broken - it has
happened (an input surface fired only intermittently in live play while every
agent-driven check was green). Whenever the change adds or alters a way the human
interacts - a driver verb, an input mapping, a UI control - prove it on the
channel the HUMAN uses. For each such surface, EITHER:

- **(a)** the driver exercises the same pipeline/channel the human does (injects
  the real event through the one handler, or pushes on the same input channel a
  real key does) - so proving the driver IS proving the human path; **or**
- **(b)** the driver deliberately diverges (for determinism, or because the OS
  event genuinely can't be synthesized) - in which case name the divergence
  explicitly and prove the human-only channel DIRECTLY: a test that drives that
  exact channel, not the driver.

"The agent driver passed" is never evidence for a divergent human path. The
profile's Proof surface section names which of this repo's drivers ride the human
channel and which diverge.

## Missing tooling stops the run

If proving the change would need validation tooling that doesn't exist yet (a new
driver verb, a new log/query surface), do NOT build it - report `cant_prove` with
what's missing, and stop. Building net-new validation surface is the user's call.

## Test gate vs. iteration loop

The full gate is usually the expensive one; don't pay it on every edit.

- **While iterating, run only the profile's iteration checks** - the cheap,
  scoped ones. Filter to a single test by name when that's all you're working on.
- **The end-of-stage gate is the profile's full gate**, run **once** after your
  last change. A single green full run is the proof the suite still holds;
  per-edit full runs are waste. You own not breaking unrelated behavior, not just
  your new scenario - the one full run is that proof.
- **Sequence the tail so once means once: fmt -> gate-with-captured-output ->
  commit.** Run the profile's fmt command (and any text-hygiene scan) *before* the
  gate, and capture the gate's output to a file as it runs so a verbatim-tail
  paste never forces a re-run. The failure shape this kills: three full gates in
  one change - gate, re-run-to-capture-output, re-gate-after-fmt. Formatting
  cannot change test results; never re-gate because of it.
- **The gate runs foreground, as ONE synchronous shell call** with a generous
  timeout sized to the profile's stated gate duration - never `run_in_background`.
  A backgrounded gate leaves a turn boundary to stall across, and ending the turn
  to "continue when the task completes" is the recurring gate-wait stall (it
  survived every prose guard until made structural). Background-with-in-turn
  self-poll is the fallback only for a run that genuinely cannot fit the max
  timeout; even then, poll the output file yourself and never end the turn to
  wait.
- **Gate attestation:** any gate claim you report or record must paste the
  verbatim result tail (explicit pass/fail counts + exit status) - never a
  paraphrase like "all green". A red you believe pre-existing must be
  stash-verified against the pristine baseline (`git stash` -> rerun -> `git
  stash pop`) and named with that evidence; never claimed green, never silently
  absorbed.

## Don't disturb the human's machine

The human may be working on the machine while the run proceeds. Never escalate to
a visible window, a focused launch, or any surface the profile marks as the
human-watch rig in order to reach a state the hidden path can't. If a state is
unreachable through the sanctioned drivers, cover it in-code, record the named gap
honestly (the `cant_prove` shape), and let the orchestrator decide. The profile's
Proof surface section names this repo's specific prohibitions.

## Evidence hygiene

Write proof artifacts and screenshots only to your own stage-unique temp subdir or
to the profile's sanctioned gitignored homes - never loose into the repo working
tree (anything under it gets swept into the PR diff). A checked-in test may emit
files, but only into an isolated per-process work dir it creates - NEVER to fixed
pipeline-convention names in the shared temp dir. (This has happened: a checked-in
test wrote "the PR's" images to fixed temp names and a later stage's re-runs
silently overwrote them.)

Every screenshot you submit must be a frame you captured live this run, and its
caption must match its own bytes - the seed/state you claim is the one actually
rendered in that file. If you couldn't capture a frame for some moment, omit the
shot and say why in the proof; never caption an old or reused frame as something
it isn't.
