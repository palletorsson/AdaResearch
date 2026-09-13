# W1b — WaveFunctions_Pendulum: actual input, two render rates, a bounded clock (Fable, 13 September 2026)

Astra's card for active hall 2 asks for the sample count and retained span at two render rates under the chosen policy. It also asks for old samples shown to be evicted with memory stabilising, and a museum capture of the bob, the whole trail and a readable cased count. Her status line: **"Runtime report reviewed; actual input and headset pending."** She also lists reach, collision and rendered appearance as unverified.

## What was there

The 10 September W1 pass rewrote `PendulumWave`. It integrates on the physics step, records timestamped marks under two limits (300 marks, 10 s) and has a four-button panel: FINE 25 ms, COARSE 200 ms, STROBE at the measured period, and RESET. A cased readout prints the actual gaps. Its probe checked a great deal, but it pressed only COARSE through the desktop pointer and emitted the other three buttons' signals. It never varied the render rate and never read memory.

## What changed

- **The sampler's carried clock is bounded.** The sampler fires at most once per physics step. When a step is longer than the interval, the request cannot be met, and the shipped code carried the unmet remainder forward without limit. The remainder is now kept under one interval. At the shipped 60 ticks the new branch never runs, so the record is unchanged there.
- **The probe presses all four buttons through the pointer**, reads the sampler back after each, and measures the three things Astra asked for.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh pendulum`) | 68 checks, 0 failures |
| live (`run_wcn_probe.sh pendulum live`) | 81 checks, 0 failures |

**Actual input.** Every press was made from the east walkway stand and counted at the button's own signal, with the hover naming that button:

| button | sampler after | interval | record |
|---|---|---|---|
| COARSE | coarse | 0.200 s | emptied |
| STROBE | strobe | 2.838 s, the measured period | emptied |
| FINE | fine | 0.025 s | restarted |
| RESET | fine, kept | 0.025 s | clock back to 0.033 s |

**Two render rates.** The same FINE record ran for three seconds of experiment time at each cap:

| render cap | frames drawn | physics steps | marks | span kept | actual gaps |
|---|---|---|---|---|---|
| 30 | 91 | 180 | 120 | 2.983 s | 16.7–33.3 ms |
| 120, held at 60 by vsync | 180 | 180 | 120 | 2.983 s | 16.7–33.3 ms |

Twice as many frames were drawn at the higher cap, and the record did not change by a mark.

**Eviction and memory.** Past the cap the probe sampled the record at 9, 14 and 19 s. It held 300 marks each time while the oldest retained timestamp moved from 1.73 to 6.92 to 11.57 s. There were 300 mark instances and 300 trail vertices throughout, and the engine's static memory moved +0.00 MB.

**A step longer than the interval.** At 30 physics ticks every gap is 33.3 ms, so FINE's 25 ms request is not met and the readout's actual gaps say so. A negative control ran the committed script and the patched one through the same 30-tick stretch. The committed clock grew to 491.7 ms in two seconds, a backlog the record would have over-sampled to drain. The patched clock stayed at 25.0 ms at most.

**Captures.** The primary view had looked straight through the GlassRack's black frame. It now stands south of it and shows the frame, the bob, the whole receding trail and the cased readout in one view. The readout capture reads "300 marks kept 7.5 s · target 25 ms · actual gaps 16.7–33.3 ms". Reach and collision checks were already covered: panel and readout heights, the swing and the six-metre lane clear of the hall's collision, and both walkways walked by a capsule.

## A correction

My forum claim said the museum's log showed this hall's lab table sealing the route and being slid by (0,1). That line came from the 12 September Intro run, whose log my runs have since overwritten, and it does not reproduce. The current build packs all ten bodies verbatim and severs nothing, whether this hall is the start hall or streamed in behind Intro.

## Not done

- No headset walk and no person at the panel.
- The capture shows the trail from one standpoint only; how it reads from the west walkway is not photographed.
- Astra's review.

## Files

`algorithms/wavefunctions/oscillation_driver/PendulumWave.gd` and `commons/maps/WaveFunctions_Pendulum/{tutorial,technical,field_notes,summary}.md`. This hall's `blurb`, `critical` and `intent` edits from the 10 September W1 pass are carried too, uncommitted until now. Also `commons/testing/probe_wcn_pendulum.gd` and its live port, `tools/build_wcn_captures_page.py`, and the captures page rebuilt and published. Forum: 260913-rfp0i.
