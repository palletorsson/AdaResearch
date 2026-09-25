# wavefunctions × Nature of Code ch. 3 — applied 25 September 2026

Reading: `doc/book/readings/NOC_wavefunctions_2026-09-25.md`. Tasks `book_wavefunctions.014`–`.024`, all applied here and closed. Palle: "commit and apply" (10:35).

Two of the eleven were predictions, and both were measured before a word was written. `probe_wave_tick_rate.gd` (copied here with its report `probe_wave_tick_rate.json`) ran the recorder and the pendulum at 60 and at 90 physics ticks a second, the desk's rate and the headset's:

| prediction | measured |
|---|---|
| .014 FINE's 25 ms request records gaps of 16.7/33.3 ms at 60 Hz and 22.2/33.3 ms at 90 Hz | 60 Hz: 59 gaps of 16.7 and 59 of 33.3; 90 Hz: 90 gaps of 22.2 and 29 of 33.3 |
| .015 the free swing's velocity keeps 0.995^60 = 0.740 a second at 60 Hz and 0.995^90 = 0.637 at 90 Hz, so it dies sooner in the headset | amplitude kept after six seconds: 0.451 at 60 Hz, 0.294 at 90 Hz |

Both sentences went in with the measured numbers. For .015 the prose option (a) was taken; option (b), making the shipped `free` regime rate-independent, changes a shipped default in every Intro placement and stays Palle's call.

| task | hall | what landed |
|---|---|---|
| .014 | Pendulum | the physics clock is the desk's sixty or the headset's seventy-two or ninety; the gap pair at each |
| .015 | Intro | the damping line named as the per-tick trick, with the measured six-second comparison |
| .016 | Pendulum | the wagon-wheel effect at STROBE; footnote `[^wagon-wheel]` |
| .017 | Pendulum, Sine_Space | a period becomes a length: 2.84 s at 0.6 m/s is 1.7 m of record; 4.5 cycles in 7 m is a wavelength of about 1.5 m |
| .018 | Intro, 3D_Wave_Propagation | the small-angle approximation turns the pendulum into a Hooke oscillator; Hooke named at the lattice; footnote `[^hooke]` |
| .019 | Unit_Circle | the second rod restores what one number loses; the two-argument arctangent |
| .020 | Unit_Circle | the radian as distance along the rim, in radii; the graph stretches a turn to fourteen |
| .021 | Effect_Sound | 440 returns a second is 2.3 ms each; the scope's two periods are under 5 ms |
| .022 | TrigWalkingPath | the Lissajous figure named: 1:1 the circle, 3:2 a knot, 1:φ never closes |
| .023 | Pendulum | the Foucault pendulum's turning paper and the three double-pendulum painters; footnote `[^foucault]` |
| .024 | Intro | push the bob: the listening cube changes, the clocked one does not |

Verification: every footnote reference has a definition; endings preserved (Intro LF, the rest CRLF, none mixed); word counts after: Intro 785 · Pendulum 965 · Sine_Space 1,093 · Unit_Circle 555 · 3D_Wave 661 · Effect_Sound 793 · TrigWalkingPath 517. No code changed.

Disclosure: these seven files carried uncommitted hunks from another writer (Codex's application of tasks .001–.013, closed by Codex at 09:24, last touched 09:01–09:12, idle since; forum 260925-irf7y and 260925-0vmbf). `before/` is the tree as found, so the diffs here are this pass alone; the commit lands the files whole. AirMusic, Bernini, Sky_Stairs and Synthesis_Lab also carry Codex's hunks and are not in this pass.
