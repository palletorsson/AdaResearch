# Queer Cyborg Subjectivity — Technical

The map is a 10×10 room with one primary `super_drag_mirror` artifact on a central plinth. The mirror should render the same avatar state used by the player, so the reflection is a check on the actual body rather than a catalogue image.

Keep the state explicit and reversible. Store outfit, posture, material, and interface choices separately; emit a change event after one field changes; and retain the previous state for comparison. A later pass can add hand tracking, but the desktop fallback must expose the same parameters.
