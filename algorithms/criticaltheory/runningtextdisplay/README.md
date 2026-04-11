# Running Text Display -- LED Scrolling Text

A scrolling LED text display that renders moving text on a 3D panel using a `SubViewport` and `Sprite3D`. The artifact demonstrates **viewport-based texture rendering**, **2D-to-3D text projection**, and **directional scroll animation** -- evoking the electronic text installations of artists like Jenny Holzer.

## Concept Taught

**Viewport textures and text animation in 3D space.** This artifact teaches how Godot's SubViewport system can render 2D content (scrolling text) onto a texture that is then displayed on a 3D surface. It demonstrates the pipeline from Label rendering through viewport capture to Sprite3D display -- a technique used for dynamic signage, HUDs, and information displays in both games and VR applications. The conceptual reference to LED text art connects computational display to critical theory and public text installations.

## How It Works

1. A flat `BoxMesh` panel is created with dark emissive material to simulate an LED display housing.
2. A `SubViewport` is created at a resolution proportional to the display dimensions (width * 100, height * 100).
3. A `Label` node is placed inside the viewport with configurable text, font size, and color. The label is made extra wide (10x viewport width) to accommodate scrolling.
4. A `Sprite3D` is positioned slightly in front of the panel, using the viewport's texture as its display surface.
5. Each frame, the label position is offset by `direction * scroll_speed * delta * 100`.
6. When the text scrolls completely off-screen, its position wraps back to the opposite edge.
7. Five scroll directions are supported: left, right, up, down, and diagonal.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | String | (sample text) | The message to display |
| `font_size` | int | 24 | Text font size in pixels |
| `text_color` | Color | cyan | Text rendering color |
| `background_color` | Color | black | Display background color |
| `display_width` | float | 2.0 | Physical width of the display panel |
| `display_height` | float | 0.2 | Physical height of the display panel |
| `scroll_speed` | float | 0.5 | Text movement speed |
| `scroll_direction` | enum | Left | Left, Right, Up, Down, or Diagonal |

## Features

- SubViewport-based text rendering for resolution-independent display
- Five configurable scroll directions with automatic position wrapping
- Emissive LED panel material for glow effect
- Sprite3D projection for proper 3D scene integration
- Configurable text content, color, and font size
- Transparent viewport background for clean text overlay

## Files

- `running_text_display.gd` -- SubViewport text display with directional scrolling animation
- `RunningTextDisplay.tscn` -- Scene file
