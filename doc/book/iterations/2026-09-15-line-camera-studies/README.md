# Four live line studies — 15 September 2026

The existing two-, three-, four- and more-line animation now has four cameras filming the real grabbable rods in the museum world. Tilted monitors show frontal monochrome, oblique ink threshold, a slowly orbiting contour view, and oblique tinted scan lines. No button interface or prerecorded movies.

The current map already placed the workshop at (16,16). This pass preserved that location and turned it to 180 degrees, facing the open floor; at 0 degrees the neighboring science screen obscured the monitors. The encounter route now visits (16,16). Other placements, floor cells, utilities and prose outside the workshop section were preserved against the snapshots here.

The added book paragraphs invite comparison between the filmed crossing and the separated rods. Filters affect the image; they do not alter geometry or measure topology. Existing animations and grab pauses are retained.

## Evidence

- camera-report.json: 40 rendered checks passed, including visible feeds in the shared world, isolation between bays, real grab-driven image change, orbit and off-screen render suppression.
- animation-report.json: 22 animation/grab checks passed before the final visibility optimization, which does not change the animation code.
- route-report.json: the primary role, source passage and saved visit agree; all model route legs connect. Other content preserved.
- museum.png: actual endless museum desktop capture at the current placement.
- The 29-case geometric research was regenerated separately with current source hashes.

Feeds are 384 × 288, at most 12 updates/second while visible. Visual layers 17–20 isolate this exhibit, with short camera ranges; the screens stay on layer 1. Multiple overlapping copies would need a different isolation scheme. Physics pickability stays on layer 3.

Headset reach, comfort and device performance have not been tested. Existing Godot UID/certificate, shader-cache and unrelated map warnings appear in the logs; no workshop script/shader compilation errors occurred in the final runs.
