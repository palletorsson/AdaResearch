# Gameplay Displays

HUD elements for player health and hit tracking. Both connect to `GameManager` signals and update automatically when health changes.

## Health Display

Shows the player's current health as a color-coded number. Connects to `GameManager.health_updated` on ready and polls the initial value via `GameManager.get_health()`.

### How It Works

When health changes, the display updates a Label3D with the ceiling of the health value. The label color shifts based on thresholds: green (health > 2), yellow (health 1--2), and red (health <= 1).

### Features

- Automatic connection to `GameManager.health_updated` signal
- Color-coded warnings (green / yellow / red)
- Displays whole-number health via `ceil()`

## Hits Reset Display

Shows how many hits the player has taken out of the maximum, displayed as "taken / max". This is the inverse of the health display -- it counts upward toward the reset threshold.

### How It Works

Listens to the same `GameManager.health_updated` signal but computes hits taken as `max_player_health - current_health`. The label turns red at 2+ hits, yellow at 1 hit, and orange at 0.

### Features

- Inverse health view showing progress toward failure
- Fraction format (e.g., "2 / 3")
- Color-coded severity (orange / yellow / red)

## Files

- `health_display.gd` -- Health value display with color thresholds
- `health_display.tscn` -- Scene for the health display
- `hits_reset_display.gd` -- Hits-taken counter with inverse health logic
- `hits_reset_display.tscn` -- Scene for the hits reset display
