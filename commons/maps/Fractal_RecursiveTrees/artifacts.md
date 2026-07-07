# Fractal RecursiveTrees — Artifacts
*Fractals: Infinite Within Finite · lambda_edge · 10 artifacts*

> Trees grow without blueprints. The recursive tree encodes growth without memory—just a rule: divide, reduce, repeat. The stochastic tree introduces randomness into recursion, same grammar, different outcomes. Trees grow down as well as up—roots and canopy mirror each other. Walk through a computed wilderness where every trunk branches by the same rule.

The map, read through what it holds — its artifacts in the order you meet them:

## Living Paper
![Living Paper](/scene-catalog/living_paper.png)

Universal grabbable 2D canvas. Grab to run the algorithm, drop to pause. Defaults to simple random walk. Use #algorithm:<name> config to select cartridge.

`living_paper`

## L-System Tree
![L-System Tree](/scene-catalog/fractal_lsystem_tree.png)

L-System tree generation with formal grammar rules

`fractal_lsystem_tree`

## recursive_tree_2
![recursive_tree_2](/scene-catalog/recursive_tree_2.png)

recursive_tree_2

`recursive_tree_2`

## small_subdivision_cube
![small_subdivision_cube](/scene-catalog/small_subdivision_cube.png)

small_subdivision_cube

`small_subdivision_cube`

## inverted_tree_cloud
![inverted_tree_cloud](/scene-catalog/inverted_tree_cloud.png)

tree(depth) = trunk_down + branches_down(random_angle, shrink) + cube_cloud(orbit, fade_timeline)

`inverted_tree_cloud`

## recursive_tree
![recursive_tree](/scene-catalog/recursive_tree.png)

branch(pos, dir, len, depth) = cylinder(tapered) + branch_count * branch(end, rotated_dir, len * 0.7, depth+1)

`recursive_tree`

## Dark Sphere
![Dark Sphere](/scene-catalog/dark_sphere.png)

USE a neutral sphere as a reference for scale, silhouette, and atmospheric change.

`dark_sphere`

## Cube Desk
![Cube Desk](/scene-catalog/cube_desk.png)

Modern desk with drawer unit created through cube subdivision

`cube_desk`

## fractal_scene
![fractal_scene](/scene-catalog/fractal_scene.png)

fractal_scene

`fractal_scene`

## MÃ¶bius World
![MÃ¶bius World](/scene-catalog/mobius_world.png)

Walkable MÃ¶bius strip - non-orientable surface. Requires MovementWallWalk on player (collision layer 4).

`mobius_world`
