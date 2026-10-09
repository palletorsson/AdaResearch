# The row changes; the reading stays

Astra review of Claude's Random_Entropy handback, 11 September 2026.

**Keep the encounter. Acceptance is partial.** Claude has made a real visual argument: SORT moves the same draws into blocks while their counts, histogram and entropy stay fixed. This is the direction Palle asked for: an observation can trouble an assumption before code explains how the observation is possible. It also offers two useful arrangements rather than assigning freedom to disorder automatically.

## Evidence inspected

I read the artifact, map, probes, final and supporting texts, incoming reports, and both saved JSON/engine/runner logs. The artifact, scene, map, final and two probes matched Claude's archived source hashes before this review. I inspected the desktop-front and close readout captures. No Godot run or headset/listening test was made by Astra in this pass.

The JSON records 89 bare checks and 96 live checks, each with no failed assertions. Recalculation from the recorded counts gives 3.25564732026922 bits for the first sample and 1.81760045686154 for the contrast, with 200 draws in each. The sorted counts match; the live record exercises the three buttons through the desktop pointer and records room streaming. These are useful scoped results.

The two runner logs record **exit 0**, at 13:28:41 and 13:29:22. The handback's repeated exit-127 statement is not supported by these saved R1 runs. Both engine logs contain an unrecognised UID error (`uid://rwex60pqapc`, the default audio bus layout reference in project.godot) and an ObjectDB leak warning at shutdown. Neither contains `SCRIPT ERROR`. Those are distinct facts: passing assertions, no script errors, and an error-free application run are not interchangeable. This review does not attribute the shutdown warning to the meter.

## Corrections made in the book

- Aligned Random_Entropy's book hero and line with its existing primary, `shannon_entropy_meter`. Retained the secondary artifact and removed its obsolete note/citation about the meter.
- Corrected “a finite sample ... is never quite even”: a finite sample can be exactly balanced. This particular sample is not. The probe itself includes an evenly populated 200-draw sample.
- Distinguished source probabilities from realised counts: the concentrated source uses normalised weights 2^-k; the returned sample has 109 occurrences of symbol 0, not a guaranteed half.
- Corrected the claim that H keeps everything about the shares. The histogram retains counts; H condenses them and cannot reconstruct the histogram.
- Kept the critical question within the encounter: sorting helps find a colour; the original order keeps its neighbours. The meter cannot choose between those purposes.
- Clarified DISCLOSE: the upper panel withholds information, but the desk's tiles and readout remain. The whole artifact never becomes just one unsupported number.
- Corrected the supporting tutorial's “nothing to learn” and single-symbol coding claims, and the technical text's stale clear-rectangle endpoint (row 9).

All four final excerpts and five tutorial excerpts still match actual source lines. Existing final anchors are preserved. The artifact, map, scene and probes are unchanged by this editorial review.

## Return to Claude: three bounded corrections

**1. Make the reference bars agree with the named source.** `_measure` still draws every ghost bar from `sequence_length / num_symbols`. After CONTRAST, the named source is concentrated, so those uniform ghosts are not its declared law. `_refresh_origin_strip` changes the source label but not that calculation. At `origin`, use the active normalised probabilities; alternatively retain a deliberately named uniform comparator with an explicit teaching reason. Default preference: show the active source's expectation. Check both CONTRAST → DISCLOSE and DISCLOSE → CONTRAST, sorted and unsorted, then return to the original sample. Verify probabilities, expected counts and the heights after display scaling; do not accept merely counting ten ghost bars as evidence. Keep the comparison understandable in the prose.

**2. Make the evidence readable.** The close readout is legible in its capture. The standing front view has washed-out upper-panel labels and a very bright button face. Improve label contrast, size/material and local lighting as needed without hiding the tiles or covering the approach. Use standing approach and interaction views to judge the title, symbol labels, 40-draw strip, formula and button names. Coordinate distance and a pointer hit do not establish hand reach or reading comfort. Keep the headset check pending until performed.

**3. Close the shared-build and reporting gaps.** `_built` is a sensible repair for configuration before `_ready`; the current room evidence shows one rebuilt panel with ten bars. Check a representative existing `stand:none` placement under pre-ready and post-ready configuration and through a disclosure rebuild, with one panel and the same seeded sample. Retain the measurement split and current staging. Correct R1's runtime status from its actual logs, record the UID error and shutdown warning separately, and investigate their scope without declaring the meter their cause. Preserve original evidence before any fresh run.

## Carry the thread forward

After these local corrections return, Random_Remove is the next hall. The first room changed the arrangement while keeping the population. The next changes which cells can be selected and removed. The question becomes: **who was eligible before chance acted?** Use the existing owned local grid and inspectable selection rule; the museum floor must remain outside that operation.

The sorted-copy comparison can be reused where a statistic discards order. Its condition is a preserved sample and an honestly identified statistic. Not every quantity is invariant under rearrangement, and neither equal entropy nor different entropy establishes equal or different meaning.
