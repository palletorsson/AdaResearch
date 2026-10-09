# Menger flight cube — 14 September 2026

[Review with actual captures](../../research/possible-bodies/menger-flight.html).

50 Godot checks pass, PID 41228; 25 content/preservation/HTTP checks pass. The actual museum walker uses synthetic InputEventKey events, flushed before state assertions. A synthetic XRControllerTracker drives the real XRTools receiver. No headset claim. The first run's immediate key assertions preceded the buffered event flush; its movement paths passed. Correcting the assertion timing produced the accepted run.

The final configuration keeps all map layers except one specimen token: `menger_sponge:0:2#flight_box:true`. The offset brings the basin-seated specimen to museum floor level. All other plan rows and the saved hand are preserved. Only this specimen opts into the enclosure; other sponge scenes retain their default behaviour.

The reusable mechanism lives in commons/movement/museum_flight_box.gd and museum_flight_provider.gd. The museum walker and standalone desktop rig query the same bounded group; the XR adapter is installed once per player body. This review verifies the museum walker and XR receiver, not a separate standalone DesktopPlayer input run. The envelope remains across sponge rebuilds.

The physical cube has two 3 m wide, 2.6 m high ground doors. Motion is capped at 2.4 m/s. The roof accounts for the museum camera sitting above its capsule. Retained sponge cells remain solid.

Evidence: receipt.json, report.json, engine.log, content-verification.json, browser-verification.json and the before/ files. Editor PID 40112 remained open. The owned game process exited normally. Existing UID and viewport-texture startup diagnostics remain; no script or parse errors.
