# Translation course merge, 2026-09-09

Before contains the exact map JSON and markdown from both source rooms before compiling the longer course. These snapshots are not rewritten when the compiler runs again.

The active room is commons/maps/Trans_Translation. The transformation sequence goes from Trans_Introduction through this combined room directly to Trans_Rotation. Trans_AxisDecomposition remains available as a source room but is no longer a separate stop. The active spine therefore has one fewer room (189).

The compiler is commons/testing/compile_translation_course.py. It is an authoring recipe, not an automatic startup hook; rerunning it overwrites the combined map. The route manifest in map_data.json records its seven transport vectors and thirteen pickup positions for runtime checks.
