# Hilbert's Hotel

An animated demonstration of Hilbert's Hotel paradox, showing how a fully occupied hotel with infinitely many rooms can still accommodate a new guest. This teaches the counterintuitive properties of infinite sets and one-to-one correspondence.

## How It Works

The artifact displays a row of numbered rooms, each occupied by a glowing guest sphere. When a new guest arrives, every existing guest shifts from room n to room n+1 in a smooth animation, freeing up room 1. The new guest then enters the vacant first room, visually proving that infinity + 1 = infinity. The cycle repeats continuously through four phases: full hotel, shifting, new guest entry, and a result pause.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `num_rooms` | int | 10 |
| `room_width` | float | 0.06 |
| `room_height` | float | 0.08 |
| `room_depth` | float | 0.05 |
| `room_gap` | float | 0.015 |
| `guest_radius` | float | 0.015 |
| `shift_duration` | float | 0.8 |
| `pause_between_shifts` | float | 1.2 |

## Features

- Four-phase looping animation: full, shift, enter, pause
- Smooth cubic ease-in-out motion with guest bobbing
- Last guest fades out as it moves beyond the visible rooms
- Room color transitions between occupied and empty states
- Infinity symbol and ellipsis at the row end to suggest infinite continuation
- Status label narrates each phase of the paradox

## Files

- `hilbert_hotel.gd` -- Main script
- `hilbert_hotel.tscn` -- Scene file
