# The Uncertain Surface — museum prototype

9 October 2026. Installed in Random_Noise_Types, Noise sequence. One Gaussian displacement experiment; no general fuzzy-computer implementation.

## Built

Two 2m surfaces, 289 shared logical positions per copy, 512 indexed triangles each. The same pale material and matching lights. Frozen local Gaussian sample, scaled by strength; next seed, zero, reset and edge overlay. Labels expose sigma, measured RMS, maximum and centroid drift; population RMS remains separate. The experimental surfaces have no collision. Only supports and ordinary controls collide. Meshes update on parameter changes, not idle frames. In-memory receipt ring holds64 events.

Source plane, index list and saved offsets are independent. No clipping or centroid correction disguises the distribution. Indexed normals are recomputed after displacement. Fixed topology does not establish an intersection-free embedding or meaningful navigation.

## Measured

Seed1847 / strength0.18 / sigma0.045m: measured RMS 0.07759170m; maximum 0.16402331m; centroid drift 0.00148868m. Population RMS 0.07794229m is a reference, not the measured sample.

28 native core/scene assertions pass. 16 museum assertions pass, including capture-camera checks. The latter operates four buttons through the existing desktop pointer rig, supplies real XRTools pickup/movement/release poses to the slider, and checks 78 floor/capsule samples on the approach and eastern bypass. Capsule radius0.28m/height1.7m, physics masks1|4. Rebuild timing is recorded in the receipts; it is not an FPS or Quest benchmark.

## Placement and review

The comparison occupies cell[3,11], rotated90degrees toward the west wall. All five earlier authored artifacts retain their cells and tokens. Structure, utilities and sequence order unchanged by this addition. Only this hall's generated plan row was rederived.

The first position overlapped the temporal-weather apparatus's foreground. Native inspection revealed its controller extends5.65m before its central token. The final bay separates the controls, improves the readout and keeps the eastern route. The existing weather sign still appears at the edge of the view; neighbouring works were not removed for the close photographs. Overhead images hide neighbouring halls/player for framing, not this hall's walls.

## Evidence limits and diagnostics

No physical headset, Quest performance, independent student or adaptation experiment tested. Existing authored entry is blocked and the museum uses its prior safe-spawn fallback; this predates the new artifact and remains unresolved. Existing UID/Jolt warnings remain. The final logs contain no SCRIPT ERROR or Parse Error.

The first core probe compared a packed GPU normal with an excessively tight zero-component tolerance; a0.0001 vector-distance check accommodates mesh normal packing. No normal algorithm change was needed. First interaction probe used the wrong handle child path; corrected to HandleOrigin/InteractableHandle. The first two placements and failed probe logs are retained as diagnostics. All final assertions pass.

## Text and continuation

The map tutorial gains a short optional study with a link to the complete three-file companion; its earlier lesson is retained. final.md gains a separate three-paragraph reflection on what survives displacement. The entire opening has not been rewritten or assessed as a complete learner chapter.

The uncertainty plan now records G0 and twelve possible injection sites. Pendulum(G1), navigator(G2), fuzzy inference and deliberate failure-threshold tests remain proposals. Next geometric experiment must name a criterion before calling a result a glitch.
