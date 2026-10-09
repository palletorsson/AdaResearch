# Compact Drink Me encounter

The playable room changes from a 6 × 6 metre room enlarged tenfold (60 × 60 metres) to a 4 × 4 metre room enlarged fourfold (16 × 16 metres). Its source hall is now 21 × 22 cells and explicitly contains the enlarged footprint, with a continuous museum floor under the room and its approach. The earlier 7 × 7 source grid did not contain its 60 × 60 metre grown artifact.

The crystal host, blooming food tower and pickup bottle stay. Thirteen porcelain landings still carry the descent. Their height differences after enlargement are 0.54 m, down from 1.35 m. The spiral advances 0.95 radians per plate; the old 0.65-radian arrangement left a body standing on the preceding plate at this smaller scale. Widening the angular spacing resolved that actual collision failure.

One comparison was added within the same primary encounter. The small exit grows from 0.45 × 0.60 m to 1.8 × 2.4 m. Immediately beyond it, a second frame already measures 1.8 × 2.4 m. It belongs outside the scaled Room parent and keeps its dimensions. Passing through both makes the hierarchy tangible: one changed, one did not, and both now admit the same body.

`checks.json` records 30 passing checks in the actual endless museum: desktop pickup finds and consumes the bottle; body and museum retain scale; the same capsule cannot cross the small exit but can cross the grown door and fixed frame; arrival has headroom; all landings have collision; the actual CharacterBody descends every plate under gravity and walks around the sculpture to both exits. A 16 × 16 × 4.8 m physics query found no foreign museum colliders inside the enlarged room. Headset reach, comfort and embodied interpretation remain untested.

The images are real Godot renders in the museum, using `ada_run/capture_compact_scale.tscn`: before pickup, arrival on the plate, expanded overview, and the two doorways. The capture uses the same bottle consumption callback after the separate runtime probe has verified the desktop pickup path. Only the capture camera and the player's costume visibility differ from ordinary play.

Run the collision probe with Godot 4.6:

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --path . --xr-mode off --audio-driver Dummy --log-file ada_run/compact-scale-check.log --quit-after 10000 --script res://commons/testing/probe_drink_me_room.gd
```

Files changed for this encounter: `algorithms/primitives/scaleme/drink_me_room.gd`, the Trans_Scale map and six local manuscripts (final, technical, critical, intent, summary, artifacts), and its existing runtime probe. The legacy scale_me behavior was not changed. Earlier source copies are under the sibling `before` directory.
