# Subtitles

VR-compatible subtitle system with typewriter effect, speaker labels, and configurable verbosity levels. Displays text at the bottom of the screen (2D overlay) or attached to the XR camera (3D Label3D).

## How It Works

`SubtitleManager` is a global autoload ("Subtitles") that finds or creates a Label3D on the XR camera. Calling `Subtitles.show("text", "Speaker")` triggers a typewriter animation that reveals characters progressively, then auto-hides after a configurable duration. Three verbosity levels (Essential, Info, Verbose) let players control how much text they see. `SubtitleOverlay` provides a 2D CanvasLayer alternative with the same typewriter effect, fade transitions, and a queue for sequential subtitles.

## Files

- `SubtitleManager.gd` -- Global autoload. Typewriter display on XR camera Label3D with verbosity filtering.
- `SubtitleOverlay.gd` -- 2D CanvasLayer overlay with RichTextLabel, fade transitions, and subtitle queue.
- `SubtitleOverlay.tscn` -- Scene file for the 2D overlay variant.
