# Films inside the Endless Museum

These 52 short Godot scenes and interactive studies reveal operations in existing museum artifacts. Each monitor films a separate 3D stage with its own camera and `World3D`; the resulting viewport texture appears on the screen in the hall. The stage uses independent source instances, recorded states or source data. It does not take control of the original artifact.

[catalog.json](catalog.json) lists the films in spine order, their museum maps, source paths and limits. A film is a staged explanation of a process, not a recording of everything the live artifact does. For example, the cloth film replays sampled states from its source simulation; the shader film supplies an independent clock so its animation can pause.

The second collection adds 20 concrete studies in `more_early/`, `more_motion/` and `more_structure/`. The review page's **The 20 additional films** filter isolates them. Subjects include the cube's shared corner, a moving doorway, inherited scale, two colour interpolation paths, a replayed random state, repeated middle-third removal, a summed field and a rejected graph cycle.

The third collection ports the six working [foundation comparisons](FOUNDATIONS.md) into native 3D monitors. A separate lower row lets the visitor change values, read and write records, and compare independent or shared state. It pauses the demonstration and retains those choices until the visitor returns to DEMO. These reduced studies do not control neighbouring exhibits.

## Try a film

Open [spine_preview.tscn](spine_preview.tscn) in the existing Godot project and run that scene with F6. The picker switches between films. To choose one from PowerShell at the repository root:

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --path . --xr-mode off res://commons/artifacts/spine_films/spine_preview.tscn -- --film-id=cloth_relations
```

Look at the screen to play. Right-drag to look away; Home looks back. Use the mouse wheel to approach, click the monitor's controls to pause, replay or step, and use the arrow keys to turn the filmed view.

Playback uses the player's camera/head direction, screen bounds, distance and an obstruction check. This is **not eye tracking**. Looking away freezes the private stage; a manual pause remains paused when looking back.

## Capture and check

Run these commands from the repository root with Python configured for `imageio_ffmpeg`. Set `GODOT_EXE` if the executable is elsewhere.

```powershell
python tools/render_spine_films.py --only cloth_relations --headless
python tools/render_spine_films.py --only cloth_relations
python tools/render_spine_films.py --only cloth_relations --film
python tools/capture_spine_museums.py --only cloth_relations
python tools/build_spine_film_review.py
```

The commands respectively check the native stage without GPU images, capture its phases, render and encode a movie, capture the registered monitor inside its authored museum hall, and rebuild the review page. Omit `--only` to process the full catalog. Movie capture renders the actual Godot viewport at 12 fps, then decodes the MP4 to check the encoded result. Rendering records hashes of referenced original source files before and after.

The [review page](../../../doc/book/iterations/2026-10-04-spine-films/index.html) reports stage checks, movie decoding and museum placement separately. Each film's folder contains the corresponding JSON reports. Scratch files and logs are under `ada_run/spine_films/`.

## Maintain the set

[film_stage.gd](film_stage.gd) supplies the camera, geometry helpers, phase captions and playback controls. Individual stages implement `_build()` and `_draw(time)`; their manifests supply the catalog metadata. Preserve the original sources and global random stream when adding a stage. Record any rescaling, reduced sample, recorded state or visual overlay in its limitation note.

`python tools/build_spine_films.py` assembles the catalog and monitor wrappers from the manifests. Its optional `--place` flag also adds monitor entries to the authored maps and museum plans; placement is a separate editing operation, not required for ordinary capture or review.

The current verification covers native desktop rendering, phase images, playback checks and museum captures. It does **not** establish headset interaction, comfort or Quest performance; those still need testing in a headset.
