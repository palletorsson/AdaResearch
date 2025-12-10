# Physics Layers & Collision Standards

This document serves as the source of truth for physics layers, collision masks, and group names used in the AdaResearch project.

## Collision Layers

| Layer | Bit | Value | Purpose |
| :--- | :--- | :--- | :--- |
| **1** | 0 | 1 | **Environment / Default**. Walls, floors, static geometry. |
| **2** | 1 | 2 | **Player Interaction / Projectiles**. Objects that interact with the player physics or trigger events. |
| **...** | ... | ... | ... |
| **20** | 19 | 524288 | **Player Body**. The physical capsule representing the player in XR. |

## Collision Masks

*   **Drone Projectiles**:
    *   Mask: `524290` (Layer 2 + Layer 20)
    *   Explanation: Hits standard interactables (Layer 2) AND the Player Body (Layer 20).

## Node Groups

*   **`player_body`**: The unique group assigned to the `PlayerBody` node (character controller). Used for:
    *   Damage calculation (projectiles check for this group).
    *   Targeting (AI looks for nodes in this group).
*   **`throwable`**: Objects that can be grabbed and thrown (e.g., balls).
*   **`xr_origin`**: The root of the XR setup.
