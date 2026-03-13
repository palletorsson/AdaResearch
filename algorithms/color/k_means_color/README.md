# K-Means Color Quantization

An interactive demonstration of the k-means clustering algorithm applied to color quantization, showing how an image's palette can be reduced to k representative colors.

## How It Works

The main script generates a synthetic portrait image and runs a simplified k-means algorithm to cluster its pixel colors into k groups. Three rows of output illustrate different aspects: Row 1 compares the original image against quantizations at k=2, 5, 10, and 15. Row 2 shows how pixel resolution interacts with color quantization. Row 3 displays the extracted color palettes (the cluster centroids) with their RGB values. The algorithm iterates through centroid assignment and update steps, using Euclidean distance in RGB space to find the nearest centroid for each pixel. A 3D wrapper script renders this 2D Control UI onto a Sprite3D via SubViewport for display in 3D/VR space.

## Features

- Full k-means clustering implementation in GDScript
- Side-by-side comparison of different k values
- Resolution scaling with nearest-neighbor interpolation
- Extracted palette visualization with RGB readouts
- 3D wrapper for embedding 2D UI in VR scenes

## Files

- `k_means_color.gd` -- K-means algorithm and 2D UI layout
- `k_means_color_3d_wrapper.gd` -- SubViewport-to-Sprite3D bridge for 3D display
- `k_means_color.tscn` -- 2D Control scene
- `2d_in_3d_k_means_color.tscn` -- 3D scene with SubViewport wrapper
