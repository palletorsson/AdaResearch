# Re-run the focused experiment

Use a working copy of the prepared Ada museum project with its existing XRTools installation. This folder is not a standalone project.

Copy this review-variation folder to `doc/book/iterations/2026-10-09-lsystems-feedback` inside that project, keeping printed/ and turns-reversed/ beside run.gd. Then invoke your Godot 4.6 executable:

```text
Godot --headless --path <prepared-project> --xr-mode off --audio-driver Dummy --script res://doc/book/iterations/2026-10-09-lsystems-feedback/run.gd
```

run.gd is the exact probe used for the receipt. It loads both complete programs, reports each assertion and writes variation-checks.json in that folder, replacing the copied receipt. Keep the original ZIP for comparison. A nonzero exit or SCRIPT ERROR is a failure. The run is headless and does not establish headset behavior or independent learning.
