# Wavefunctions: restore the platform/wall distinction

10 September 2026. Requested by Palle before the Waves/Randomness/Noise handoff.

The current structure mostly retained its original raised cells. The museum's default wall threshold interpreted every numeric value >=2 as a wall. Recover the meaning of those cells while retaining later artifact placements and the museum perimeter; a wholesale git revert is unnecessary for this correction.

## Contract

- Interior numeric `2` stays `2`. The standalone grid builds two stacked cubes; the museum's floor-relative top is one metre.
- Numeric `2` on the outermost row or column of the actual structure array becomes explicit `w`. Existing openings, holes, `w` cells and higher numeric walls remain intact.
- Each of the twelve authored maps declares `map_info.museum.wall_height: 3`.
- Each declares `map_info.museum.gate_depth_rows: 0`. The first runtime probe found that the old freestanding loading gate's jamb walls covered one platform in Effect Sound and one in Synthesis Lab. The boundary doorway now carries the gate.
- The museum already implements numeric raised-floor collision and artifact seating. The Python plan builder now reports the same support height, rather than 0.95m. No plinth is added merely for these raised cells.

Boundary means the current array rectangle, not obsolete declared dimensions or the pre-expansion footprint. An old edge inside an expanded room therefore becomes a low platform if it contains `2`, as requested. Taller internal structures retain their previous wall behavior. This is not a claim that every historical elevation was recovered.

Do not replace `2` with `p`: `p` currently has different floor-base semantics in the standalone grid and the museum. Do not rerun broad hall normalization: that can add piers, cut paths and shift anchors. `tools/recover_wave_platforms.py --apply` refreshes only the six active plan rows' geometry, support values and gate-depth declaration, preserving order and curation.

## Provenance and retained work

`before/` contains the exact working files before this intervention, including uncommitted changes. `pre-museum/` contains all twelve source maps from git commit `a36f33c996004abcdc67ea2a0ac3fce72eba42fd`, the parent of the first endless-museum commit `62e08730f` on 31 July 2026. The later source-map rewriting landed in `d7a9dbd15` on 31 August. None of these old maps was copied wholesale over a current map.

`recovery.json` lists all 193 interior platform cells and 137 perimeter cells made explicit. `source-checks.json` verifies all twelve maps against the working baseline, all 136 retained artifact placements, unchanged route/curation and unaffected plan rows. The current museum still uses six wave halls; the other six remain authored extensions. Existing finals, roles, utilities and artifact configuration tokens are unchanged.

## Evidence and limits

- Six active halls: **630 checks, zero failures**, including physical ray hits at exactly one metre for all 102 active platform cells and gates at the boundary doorway.
- Intro with actual artifacts: **189 checks, zero failures**, 21 artifact records.
- Effect Sound with actual artifacts: **152 checks, zero failures**, 33 artifact records.
- No extra pedestals were found on the raised-floor artifact instances in those two rooms. Both captures were visually inspected.
- Six extensions: source/plan-derivation checks only; no new runtime or headset walkthrough.
- The full Effect Sound run also reported existing pre-ready configuration errors in `commons/audio/UniversalVRAudioController.gd` (`_clear_controls`, `load_eurorack_preset`) and `algorithms/wavefunctions/mariocontrol/MelodyChaser3D.gd` (`_setup_note_positions`, `_create_note_markers`). Geometry passing does not certify the sound interactions. These are added to Fable's Effect Sound card.
- Ordinary startup UID/certificate/logger messages and renderer teardown warnings remain in the logs. The geometry verdict is based on the probe reports, not an error-free engine log.

Run `python tools/check_wave_platform_recovery.py` for source preservation. Runtime probe: `commons/testing/probe_wave_platform_recovery.gd`; no `--map` checks the six active halls with architecture only. `--map=WaveFunctions_Intro --artifacts --capture` and the corresponding Effect Sound command load the actual artifacts. Evidence copies are in `evidence/` and images in the published recovery page.

## Next work

Use the recovered grid as the material for the individual encounter plans. Begin with Intro's pendulum/state comparison and its final.md. Before rebuilding another room, compare its archived original with the current scene: restore a specific missing structure only when that comparison supports it. Keep the distinction between geometry recovery, successful interaction and a good lesson visible in the handback.
