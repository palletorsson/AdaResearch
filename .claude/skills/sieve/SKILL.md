---
name: sieve
description: Apply the three-question cognitive-water sieve to any design decision, artifact, sequence, file, or substrate. Use when evaluating a substantial change, before committing a load-bearing decision, or as a session-opening ritual on the day's main target. Triggers - "sieve", "apply the sieve", "sieve pass", "thicken the water", "what is foreclosed", "dark spot", "self-q", "self-Q".
argument-hint: "<target> [--record]"
allowed-tools: Bash, Read
---

# Sieve — the three-question cognitive-water sieve

You apply the three-question sieve to a target the user names. The sieve is the operational form of the **Self-Q recursion on QFEP** (see `doc/ENTRY.md` § The Self-Q). It came out of the cognitive-water blog arc (2026-05-11). It is qualitative, not a metric.

## The three questions

1. **Does this thicken the cognitive water?** (relational handles, ways of moving through, things made thinkable)
2. **What is foreclosed?** (thinking made harder under this structure)
3. **What lives in the dark spot?** (what the encoding hides — generative habitat or sterilising seal?)

Q1 stops thin/optimised/scoreboard-shaped systems. Q2 stops confusing thick with good. Q3 stops over-specification — leaves the dark spot inhabited.

## Workflow

Based on `$ARGUMENTS`:

1. **Surface the questions.** Run `python tools/sieve.py <target>` and present the framed output to the user. The CLI prints a markdown block with the target named and the three questions with sub-prompts.

2. **Pair with context** if the target is a known sequence, artifact, or file. Optionally run `python tools/lod_query.py <target>` to fold project context next to the sieve frame. Don't force this — only if it helps the user think.

3. **Walk the questions in conversation.** Take them one at a time. **Don't answer for the user.** Ask. The sieve is theirs to apply. You are surfacing structure for their thinking, not evaluating for them.

4. **Push back honestly.**
   - If the user only answers Q1 ("this thickens X"), prompt Q2 and Q3 explicitly. The most common failure is skipping Q2 and Q3.
   - If an answer is generic ("this is more flexible"), ask for a concrete handle the answer points to.
   - If Q3 (dark spot) is being treated as mystification rather than habitat, say so. The dark spot is generative *because* the surrounding encoding is rigorous, not as an excuse for hand-waving.

5. **Offer to record the pass.** If the conversation has produced real answers, propose `python tools/sieve.py <target> --record` (interactive) — or capture the answers in conversation and write them to `doc/sieve_passes/<timestamp>_<slug>.md` directly. Recorded passes are durable notes; future sessions can read them.

6. **To browse past passes:**
   - `python tools/sieve.py --list` — newest first
   - `python tools/sieve.py --show <query>` — print a recorded pass whose filename contains `<query>`

## What to surface in the response

- The target framed clearly (echo it back).
- The three questions (the CLI output is enough).
- A walking question — *"Want to take Q1 first, or which one is the one you actually want to think about?"*
- Optional context fold (lod_query) only if useful.
- Recording offer at the end, if the conversation generated real material.

## What NOT to do

- **Don't answer the questions for the user without asking.** The sieve is a thinking ritual; you are the structure-holder, not the answerer.
- **Don't reduce the sieve to a metric or pass/fail.** It is qualitative. There is no score.
- **Don't skip Q3.** It is the question that catches over-specification and is the easiest to forget. If the user wants to stop after Q1 and Q2, prompt Q3 once before letting it go.
- **Don't moralise.** The sieve is for clarity, not for judging. The user is welcome to decide "this thins, and I'm going to do it anyway because the foreclosure is worth it" — that's a valid pass.

## Background

- `doc/ENTRY.md` § The Self-Q — framework integration with QFEP
- `/blog/2026-05-11-cognitive-water` — the original frame
- `/blog/2026-05-11-watersheds-not-ladders` — sieve applied outward (curriculum)
- `/blog/2026-05-11-the-makers-water` — sieve applied inward (makers, AI-in-the-flow)
- `/blog/2026-05-11-self-colonial-recognition` — the pattern, generalised for outside Ada Research

## Integration

- Pairs with `/ada-task-manager` to record a sieve-pass alongside a task decision.
- Pairs with `/ada-queer-theory-expert` for grounding the Self-Q in critical theory lineage (Glissant, Hui, Stiegler, Quijano, Neimanis).
- Use *before* big substrate decisions (new system, new artifact family, curriculum reframe), not after.
