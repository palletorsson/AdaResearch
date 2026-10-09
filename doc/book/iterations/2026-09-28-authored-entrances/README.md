# Authored museum entrances and VR landing repair

28 September 2026.

The previous landing slab did not fix the full VR launch path. The shipped rig's PlayerBoundsCheck treated the persistent portal loading cell (x = -1000) as outside its grid bounds and reset the visitor to an obsolete position. The old probe omitted that checker. A before-fix run with the real checker reproduced the reset.

There were also two staging hazards: choosing the staging screen's current headset rig instead of the museum's own sibling rig, and applying generic XRTools centering after the portal coordinator had already placed the body. Both paths now use the museum's own supported arrival.

## Where to place the entrance

- Put `sp` in the map's `layers.utilities` at the intended first floor cell. This marker wins over legacy `s`.
- On the front boundary (row 0), in a hall without simulation padding, `sp` makes a small glass landing cage before the entrance. The visitor arrives 1.85 metres before that cell, with the cage opening along the existing forward axis (+Z); their tracked head orientation is preserved.
- The cage has a 2.2 by 3 metre solid deck, side and rear glass, and a narrow guarded floor link into the hall. It belongs to the active hall and unloads with it.
- An interior `sp` lands at the marked floor cell. `map_info.museum.portal_entry.cage` can explicitly enable or disable the cage. This is a forward (+Z) entrance convention; side and rear entrances need further orientation support.
- The marker must have floor and body clearance. With a cage, the entire short path through the opening is checked too. An obstructed authored entrance keeps the visitor on the loading floor and reports the problem instead of quietly moving them past exhibits.
- Without `sp`, a usable legacy `s` near the front is respected. Old grid routes whose `s` lies in the back half retain the supported entrance-side fallback. Maps without either marker also use that fallback.
- Point Zero keeps its special opening and drop.

## Hall decisions

Point_Lines already had `sp` at (2, 0). Its entrance now follows that marker on the left, before the line demonstrations, rather than appearing near the middle at x = 14.5. No line artifacts were moved.

Point_Trace had `sp` at (1, 0), immediately before a wall. It is now at (3, 0), the adjacent open lane. The monitor in column 2 stays in place.

## VR behavior

The museum coordinator owns loading and fall recovery while portal navigation is active. The grid bounds checker resumes its normal role outside that museum. The actual XRTools physics body and tracking origin move together, with room-scale head offset preserved. Generic staging recentering is bypassed only for portal museums.

An accidental fall below the hall returns the visitor to the supported arrival. SpawnPoint is updated to that arrival. Portal travel still keeps at most one resident hall.

## Verification

See verification.json and reports/ for the frozen results. The test uses the shipped base rig, real XRToolsPlayerBody and PlayerBoundsCheck, a simulated headset offset of (1.4, 1.7, -1.1), and a second current staging rig. It checks a delayed scene_loaded callback, floor/headroom, the cage link, gravity settling, forward travel, return, and forced fall recovery. A separate smoke check loads the actual endless_museum_staged.tscn.

Additional routes checked: Point_Zero to Point_One, Color_Nails to Color_Rainbow, and Trans_Pre to Trans_Introduction. A desktop Point_Lines run supplied the actual Godot renders.

These are selected engine regressions, not a physical headset acceptance test or traversal of every map. Existing artifact/material warnings and an exit-time ObjectDB leak warning remain in the runtime logs.

Restart the running museum before trying this in VR so the new scene-base and bounds behavior are loaded.

## Relevant source

- commons/scenes/em/em_portal_stream.gd
- commons/scenes/em/em_portal_frame.gd
- commons/scenes/em/em_portal_scene_base.gd
- commons/scenes/endless_museum.gd
- commons/scenes/endless_museum_staged.tscn
- commons/scenes/mapobjects/PlayerBoundsCheck.gd
- commons/maps/Point_Trace/map_data.json
- tools/probes/hall_portal_navigation.gd

changes.diff compares this task with its starting working tree; it does not include unrelated earlier edits.

## Quest follow-up: Point One could not open

The connected Quest's own app log identified a separate Android packaging failure: SoundscapeRadioRack.scn depended on `res://doc/reports/interfaces-2026-09-21/angular-controls/before/commons__interactables__wheel_smooth.tscn`. That historical file shares the live wheel's scene UID but is excluded from the APK. The error therefore did not reproduce by loading loose files on Windows.

`doc/.gdignore` now excludes documentation and historical snapshots from Godot's resource index. After refreshing the index, the radio, wheel and lever IDs resolve to their canonical files in commons/, and serialization uses the runtime wheel path. Local probe folders are also excluded from resource indexing.

The full shipped rig now passes Point_Zero -> Point_One -> return as well as direct Point_One -> Point_Lines -> return. The test accounts for Point Zero's intentional drop settling during its staging wait. A staged-scene smoke test is checked for script errors as well as its exit status.

The device log, dependency checks and build evidence for this follow-up are in `ada_run/point_one_portal_failure/`.

The exported APK was inspected directly: its binary radio scene references the live wheel, the wheel binary is present, and both radio controls instantiate. The verified APK was installed successfully on the connected Quest 3 with `adb install -r`, preserving application data. A physical Point Zero -> Point One crossing is still to be confirmed in the headset.

The APK UID table was also inspected: no res://doc/ mappings remain and the wheel UID resolves to the live resource. Starting the updated app reached the Quest controller-required dialog; the app has not yet produced a fresh runtime log. Wake the controllers and open the updated museum to confirm the crossing. The previous error log is timestamped before the installation.

## Repeated Techno Noir parser error: the older installed app

The editor's remote debugger was connected to `com.example.adaresearchzero`, labelled **Ada Research Zero**. Its APK, last updated 7 November 2025, does not contain TechnoNoirGenerator. The current project installs as `com.example.adaresearchzeroone`, labelled **Ada Research Zero One**. Its APK contains the generator's remap and bytecode; both the source startup and the extracted export pass a short generated-audio check.

The older app was stopped (not uninstalled); Zero One was opened. Its fresh Quest boot at 19:00:01 on 28 September 2026 has no script/parser or exhibit-loading failure. Select **Ada Research Zero One** in the headset. Evidence is saved in `ada_run/techno-noir-preload-2026-09-28/verification.json` and `quest-correct-app.log`. This confirms startup; a physical crossing still needs to be exercised.

## Polyhedra and Animated Cube entrances

The Quest log confirms successful arrivals in Point_One, Point_Lines, Point_Trace, Point_Line_Grid and Point_Triangle_Context. The subsequent failure is a supported-landing rejection in Primitives_Polythedra. A full-rig reproduction finds the cage link clipping a bench collision at room coordinate (7.79, 0.22, 1.5), size (0.42, 0.44, 0.95). Its `sp` is now one cell left, at (6,0); the annotation token swaps to (7,0).

Point_Animatedcube also fails on direct launch: its `sp` was inside wall cell (0,0). It now occupies open floor cell (5,0), before the opening exhibits. No artifacts or safety checks were removed.

The full shipped rig with simulated room-scale offset passes direct arrival, gravity settling, the complete cage link, forward travel and return for Triangle -> Polyhedra, Polyhedra -> Animated Cube and Animated Cube -> Ignorance. Each keeps one resident hall. Frozen reports and the exact map diff are in `reports/cube-entrances/`.

Both installed APK map copies matched the source before the repair. Only the two entrance-row edits were pushed to the connected Quest's `user://maps/<map>/map_data.json`, and their contents were read back and verified. At an existing error panel, touch RETURN, then enter again; the destination reads the corrected map when it is rebuilt. Headset traversal after this patch remains to be confirmed.

These device overrides persist across APK updates. Once a future APK contains the corrected source maps, clear these two matching overrides through the normal override cleanup process so later map edits are not shadowed. No prior overrides existed for these halls; that fact and the original packaged maps are preserved in `ada_run/animated-cube-load-2026-09-28/`.
