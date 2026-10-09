# Local encyclopedia post

Written and added on 10 September 2026: http://localhost:3003/blog/2026-09-10-the-floor-is-yours

Source: `doc/blog/2026-09-10-the-floor-is-yours.md`. Installed copy: `C:/Users/palle/Documents/GitHub/ada_encyclopedia/src/content/blog/2026-09-10-the-floor-is-yours.md`.

Three unmodified Godot captures copied into the encyclopedia's `public/blog-images/2026-09-10-the-floor-is-yours/`: the actual museum catwalk, the dressing mirror and the rotation hall. Their original paths are `ada_run/drag_catwalk_shots/museum.png`, `ada_run/drag_catwalk_shots/dressing_end.png` and `ada_run/Trans_Rotation_wall_crossings.png`.

Verified over HTTP: post and all three PNGs return 200; title, alt text, three code blocks and comparison table render in server HTML; post appears on the blog index. Report: `ada_run/blog_catwalk_check.json`. Browser automation could not initialise its kernel, so no browser layout inspection is claimed. Game captures were visually inspected; the post uses the existing blog renderer. Opened the local URL in Codex. No remote deployment performed.

The post distinguishes transformation (operations and invariants), change (rates and accumulation) and forces (dynamical response under modelled interactions). The future comparison of prescribed oscillation, sampled motion and spring dynamics is explicitly a proposal, not an implemented catwalk feature. Current agents are choreographed and yield by proximity; wardrobe geometry does not change player collision. Sources checked: actual scripts, current map prose and sequence definitions, Godot 4.6 transform documentation and The Nature of Code's Forces chapter.
