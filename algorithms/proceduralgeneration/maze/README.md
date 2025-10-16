# Godot 4 Maze Game

A procedurally generated maze game with AI agents that use scent-based pathfinding.

## How to Run

1. Open Godot 4
2. Click "Import" and select this folder
3. Open main.tscn
4. Press F5 to run

## Controls

- **WASD**: Move
- **Mouse**: Look around
- **ESC**: Toggle mouse capture
- **Space**: Start new game

## Objective

Catch the yellow agent (goal) before the red or blue agents catch you!

## Customization

Edit the export variables in game.gd:
- maze_size: Change maze dimensions
- seed_value: Use 0 for random mazes
- pick_last_probability: Affects maze style (0.0-1.0)
- open_dead_end_probability: More loops (0.0-1.0)
- open_arbitrary_probability: More open areas (0.0-1.0)
