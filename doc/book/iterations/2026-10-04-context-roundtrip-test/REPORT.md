# Can the local finding survive the return?

An Ada memory pilot · 4 October 2026

**Yes, in this bounded test.** A fresh reader kept all eight required distinctions from a 402-word packet and returned the local finding to sequence and project level. The test used the existing museum's Point Zero and Lines → Trace → Grid passage, with the later return in Arrays. It supports using compact, explicit working memory. It does not establish that a short summary can replace the project or that the whole curriculum is correct.

## What we tested

We froze thirteen source and planning files with their hashes. A reader without this conversation checked six claims against that selection. A second fresh reader then received only a compact packet and questions, with no source, conversation or scoring rubric. Its task was to recover the next action, the carry between halls and the limits of the evidence.

The eight criteria were written beforehand. The coordinating reader assembled the packet and assessed the reply. These were known cases from earlier work, so this was a regression test of memory and reasoning, not a blind search for new defects. Source reading and precedent research ran in parallel; the handoff test followed the source review.

| Check | Result | Meaning |
| --- | --- | --- |
| Frozen selection | 13 of 13 hashes match | The source reader used the saved versions. |
| Selected working files | 13 of 13 unchanged | The inspected museum code, map data and planning inputs were not edited. |
| Compact handoff | 402 words | Whitespace word count; not measured model tokens. |
| Fresh reader | 8 of 8 distinctions preserved | One clean handoff; not a long-term reliability rate. |
| Simulated source change | Different hash detected | The evidence needs review; no claim was automatically declared false. |

## The useful local finding

The pen retains an **accepted record**, potentially filtered, projected or quantized. Its default behavior permits a released record to span pickups. Grid takes that record, centres and fits it to the display, then rounds the display positions in XYZ. It retains source data separately. These are different stages, and a summary that collapses them into “snap the original drawing” loses something that matters.

Rounding cannot be inverted to recover arbitrary original positions. Generating a position from an array index is a useful later operation, but does not restore information discarded by rounding. The existing store also establishes retention during a session, not a promise that traces survive restarting. Scene overrides and other persistence mechanisms outside the saved selection were not checked. [Source review](SOURCE_REVIEW.md).

The source review also confirms the counter as existing material in Point Zero. The older subject register proposes creating a display and describes a later Array operation as “reversing” the earlier mapping. These are **documentary conflicts to reconcile**, not instructions to alter the artifacts. This pass leaves those documents intact so the conflict remains inspectable in the frozen evidence.

## Moving back to the whole

**Map:** distinguish the list entry, the accepted source position and the fitted/rounded address. Keep the original accepted record available for comparison.

**Sequence:** Lines provides a relation between positions; Trace retains a list; Grid introduces a lattice address. Arrays can return to the list and generate positions. This finding sharpens the relationship between lessons without requiring a new hall order.

**Project:** supplied, encountered and learned are different states. An artifact can be present without becoming a lesson. A verified operation constrains factual claims; it does not determine the critical or poetic meaning of the encounter.

The fresh reader preserved all three levels. It also retained the unresolved choice: **where does the learner's reduced construction run inside the existing museum?** Source fidelity alone cannot settle that teaching decision. [Compact packet](PACKET.md) · [Fresh reply](HANDOFF_REPLY.md) · [Assessment](ASSESSMENT.md).

## What a changed source should do

The small verification script appended a hypothetical comment to Grid's source bytes in memory. The hash changed; no file was modified. Because even a comment changes a fingerprint, a stale record must mean **recheck the evidence**, not **the claim is false**.

For the experiment, the affected claims and Grid/Array summaries were declared manually. This does not test automatic dependency discovery. It illustrates the rule we should adopt: a local source change should reopen the conclusions that depend on it, while unrelated work remains available. [Checks](checks.json) · [Verification script](verify.py).

## Existing systems we can learn from

The strongest match is a combination of patterns, rather than one complete replacement for our workflow.

| System | Useful pattern for Ada |
| --- | --- |
| [Microsoft GraphRAG](https://microsoft.github.io/graphrag/query/global_search/) | Separate broad synthesis from detailed local retrieval. |
| [RAPTOR](https://arxiv.org/html/2401.18059v1) | Retain several abstraction levels and permit links across branches. |
| [Letta memory blocks](https://docs.letta.com/v1-sdk/memory/memory-blocks) | Make the small active memory explicit, persistent and editable. |
| [Bazel Skyframe](https://bazel.build/reference/skyframe) | Record dependencies and reconsider affected results when inputs change. |
| [W3C PROV](https://www.w3.org/TR/prov-overview/) | Keep the source, activity and author behind each finding visible. |

These are proposed applications to Ada. Retrieval systems choose context; provenance records its origin; dependency systems identify what may need rechecking. None decides whether a hall is artistically strong or a curriculum is good. [Research notes and primary sources](PRECEDENTS.md).

## What to improve next

Keep a short author brief stable during each parallel pass. Give each reader a bounded sequence and a separate report. Require every finding to name its source, status, affected neighbours and consequence for the larger argument. Reconcile those reports through one synthesis pass, including disagreements and gaps between sequences.

The summaries should retain **why** a choice was made and what remains unresolved. Compression that drops those distinctions would make the work harder to evolve. The existing hierarchy can also gain thematic links: drawing, memory and positional data do not belong to only one sequence.

A stronger next test would use several sequence boundaries, conflicting older notes, a fresh resumption after interruption and a real changed dependency. Compare the compact handoff with an uncompressed baseline. Our current test has no token, speed or long-term advantage measurement, and no runtime or learner trial. It does show that a precise local fact can survive compression and change the wider plan without displacing the author's intent.

## Audit trail

[Predeclared protocol](PROTOCOL.md) · [Frozen-file manifest](manifest.json) · [Source review](SOURCE_REVIEW.md) · [Packet](PACKET.md) · [Fresh reply](HANDOFF_REPLY.md) · [Manual assessment](ASSESSMENT.md) · [Checks](checks.json)

[Return to the museum storyboards](../2026-10-04-museum-tutorial-storyboards/index.html) · [The earlier essay: A memory we can change](../2026-10-04-memory-that-can-change/index.html)
