# Void nearby-floor loading

User asks for about five visible structural levels, current-floor artifacts and a shaft-side preview below, using fog. Implemented in actual Void runtime; layout/editor JSON remains the user's source of truth.

- `architecture.gd`: `stream_content` opt-in, lazy FloorContent, per-storey column/service/sign visibility. Simple structural collision remains everywhere. Viewer/export defaults still build all content.
- `game.gd`: `stream_floors=true`; creates FloorStream after rig/environment; initializes on spawn and retry; coordinate point discovery follows lazy content creation. Standard depth fog 6→22 m, density 1; sun shadow distance 28 m. Existing sky animation remains.
- `floor_content.gd`: roots by floor; queued assemblies; one background resource request at a time, retain result, then construct one assembly per frame. Immediate destination loading joins outstanding I/O before synchronous factories. Concurrent shared-script background loads produced empty artifact instances in native tests; avoid reintroducing parallel resource requests here. Main-thread construction can still hitch.
- `floor_stream.gd`: visible indices current−1 through current+3, clipped to authored range. Current live, next preview, visited others asleep. Switch after feet drop 0.85 m below floor, preserving ordinary jumps. Held objects pin their source floor; released travellers farther than 4 m vertically from source remain live within 8 m of camera. This pins the whole source floor, intentionally conservative.
- `floor_residency.gd`: preserve original visibility/process/physics/audio/viewport/particle settings. Explicitly disable descendant process modes, including ALWAYS. Preview units use world AABB intersecting either shaft footprint grown 1.5 m; assemblies split at authored part boundaries. Preview keeps frozen visible PhysicsBody supports; hidden units and Areas leave physics. Sleep hides and removes all artifact physics. Restore same instances on return.
- All visited content stays in RAM; no claim of bounded total memory. Incremental unloading needs serializable state contracts before arbitrary artifact deletion is safe.
- `rooms.json`, `layout.json` and editor placement data were not edited. User moved Trace's point/ramp; tests approach actual point coordinates rather than invent a long synthetic arm.

Verification: `python tools/test_void_stream.py --capture` passed 24 actual Godot assertions. Real Mobile PNGs and checks.json in `doc/book/iterations/2026-10-18-void-floor-streaming`. Includes paused monitor, collisions, state retention, real synthetic XR pickup/release and checkpoint retry. Twelve-level test is the window selection policy, not twelve authored/rendered floors. Capture run largest queued assembly ~77 ms; not hitch-free or a Quest benchmark.

Report: http://localhost:3003/book-review/doc/book/iterations/2026-10-18-void-floor-streaming/index.html

Final regressions after loading changes: `python tools/test_void_avatar.py` 20/20; `python tools/test_void_game.py --reuse --trace --out=doc/book/iterations/2026-10-18-void-floor-streaming/trace` 48/48. Total 92 focused native checks. HTTP report 200; native screenshots visually inspected. User's running editor/game process left alone; relaunch Void to load changes.

Follow-up design: profile on Quest; split heavy assembly factories across frames; serialize ink, loose objects, changed cells and artifact-specific state before evicting old floor instances. Keep a deliberate safety path for held objects and prebuilt landing collision.
