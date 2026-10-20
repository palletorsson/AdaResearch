# Rendered music

Place the author's rendered MP3 (or OGG/WAV) tracks here. Add their paths to
`../manifest.json`, for example:

```json
"music": ["res://commons/void/audio/music/your_track.mp3"]
```

Restart the scene. Tracks advance in the listed order and cycle. Music has its
own `VoidMusic` bus; `mix_db.music` sets the level independently of ambience and
object feedback. A running controller can switch via
`game.soundscape.play_music(path, 2.0)`; that crossfades between its two players.

No user music has been supplied yet. The tiny MP3 under `tools/probes/fixtures/`
is a test fixture and is never added to this playlist.
