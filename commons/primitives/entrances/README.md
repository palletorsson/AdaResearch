# Entrances

Portal/doorway entrance frame for level transitions.

## Files

- `LevelEntrance.gd`: configurable entrance with frame, label, and activation signal
- `level_entrance.tscn`: scene wrapper

## Behavior

- Exports width, height, depth for frame dimensions.
- Displays configurable label text.
- Emits `entrance_activated` signal on player entry.
