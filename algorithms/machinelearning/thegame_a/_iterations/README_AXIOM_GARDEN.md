# The Axiom Garden

**"Code becomes Life."**

A puzzle-exploration game where you grow plants using L-Systems to solve spatial challenges.

## How to Play (Godot Editor)

1.  Open the project in Godot 4.
2.  Open `algorithms/machinelearning/thegame_a/AxiomGarden.gd` (or create a scene with it).
3.  Run the scene.
4.  **Controls:**
    *   **Rule Input:** Type your L-System rule (e.g., `F=F[+F]F[-F]`).
    *   **Grow:** Click the button to generate the plant.
    *   **Goal:** Try to make the plant touch the Blue Sphere (Target) without hitting Red Boxes (Obstacles).

## Mechanics

*   **L-Systems:** You define the DNA of the plant.
    *   `F`: Grow forward.
    *   `+` / `-`: Rotate Yaw.
    *   `&` / `^`: Rotate Pitch.
    *   `\` / `/`: Rotate Roll.
    *   `[` / `]`: Branch (Save/Restore position).
*   **Withering:** If your plant is too complex (>2000 segments), it will wither and die. Optimize your code!
*   **Chaos:** You can use arrays for stochastic rules (in code), e.g., `rules = {"F": ["F[+F]", "F[-F]"]}`.

## Files

*   `AxiomGarden.gd`: Main game controller.
*   `LSystem.gd`: String rewriting logic.
*   `Turtle.gd`: Interprets strings to 3D vectors.
*   `GardenRenderer.gd`: Renders the plant using MultiMesh.
*   `Target.gd`: The goal object.
*   `Obstacle.gd`: Static obstacles.
*   `AxiomEnvironment.gd`: Visual atmosphere settings.

## Credits

Designed and Built by **Antigravity** (AI Agent) & **User**.
Iteration 10/10 Complete.
