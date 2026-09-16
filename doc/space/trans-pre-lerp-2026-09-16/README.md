# Trans_Pre: lerp before sine

Palle requested code examples using linear interpolation, reserving sine for the later wave lessons. The book and tutorial now explain two heights, two sizes and a weight between zero and one. Rotation remains an incremental turn each frame. Intent records the same teaching order.

All eight pickup placements opt into `motion_curve:lerp`. The scale marker also uses lerp; the rotation marker uses continuous turning and displays the matching formula and mode label. Existing default animations in other halls are retained. The map and both cached museum plans contain the same settings. All placements, structures and artifact roles are retained.

The actual endless-museum probe passed 63 checks, including cumulative stages, equal travel over equal intervals, upper and lower endpoints, scale factors, update partition independence, collection modes, marker settings and unchanged legacy pickup motion. Godot exited 0 with no script or parse errors. This was a headless runtime check, not a headset test. The first launch failed while opening its default user log; the successful run uses an explicit workspace log path. An unrelated certificate-store warning remains in that log.

The live book API matches final.md, tutorial.md and intent.md. Code excerpts match the runtime source. Structural comparisons of both cached plans confirm that only the ten intended Trans_Pre artifact configurations changed. Prior files are archived under `before/`.
