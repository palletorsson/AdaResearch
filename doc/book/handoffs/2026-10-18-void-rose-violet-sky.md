# Slow rose / violet sky

User: make the Void sky pink/purple, procedural and very slowly shifting.

Shared tower/viewer environment: `commons/void/atmosphere.gd` and `cloud_sky.gdshader`. Twelve-minute seamless cycle (`cycle_seconds=720`), rose → violet → rose; circular noise UV drift closes without a jump. Fog and ambient colour follow the phase, sun direction stays fixed. Noise generated once. No per-frame shader TIME/POSITION dependency: phase uniform updated once per second, 128px incremental sky reflection updates. Depth fog still begins at6m; no volumetrics. `animate_sky=false` holds the sky; `set_sky_time(seconds)` samples known phases for captures.

`python tools/test_void_sky.py`:10/10 native checks, actual Mobile renders at0/180/360 seconds from roof, Trace and exterior; real synthetic XR camera binds same environment. No physical Quest performance test. Preview: `doc/book/iterations/2026-10-18-void-rose-violet-sky/index.html`. It switches actual captured moments, not a real-time browser reproduction. Lab Editor remains placement view. Restart The Void to load changes. Authored rooms/layout and artifacts untouched in this sky pass.
