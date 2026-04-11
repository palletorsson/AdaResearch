# Synthesis Engines

High-level domain-specific synthesis engines that combine multiple synthesis techniques.

## Files

- `EpicSynthEngine.gd` — "Analog Epic" synthesizer featuring 7-voice SuperSaw unison, Moog-style 24dB ladder filters, and analog drift simulation. Provides patches: CS-80 pad, lead, sub bass, choir, strings, metallic, pluck, pedal steel.

## Architecture

Engines sit above the raw generators (`../generators/`) and below the composition system. They package synthesis techniques into expressive, ready-to-play instruments with curated patch libraries.
