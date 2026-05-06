extends Node

var text = '''[center][font_size=28][b]PCA: Principal Component Analysis[/b][/font_size][/center]
[center][i]Dimensionality Reduction, Eigenvalues, Variance Maximization[/i][/center]

**PCA reduces high-dimensional data to lower dimensions while preserving variance.**

**Core idea:** Find **principal components** - directions of maximum variance.

**Result:** Transform data to new coordinate system where axes = principal components.

[hr]

[b]Concept[/b]

**Problem:** Data in high dimensions (thousands of features).
**Goal:** Reduce to low dimensions (2-3 for visualization, 10-100 for processing).

**PCA finds:** Directions (axes) capturing most data variation.

**Example - 3D to 2D:**
Data points form ellipsoid in 3D.
PCA finds:
- **PC1:** Direction of maximum variance (longest axis)
- **PC2:** Direction of 2nd max variance (perpendicular to PC1)
- *Discard PC3* (least variance)

Project data onto PC1-PC2 plane → 2D representation.

[hr]

[b]Algorithm[/b]

[color=yellow][b]Steps:[/b][/color]
1. **Center data** (subtract mean)
2. **Compute covariance matrix**
3. **Find eigenvalues and eigenvectors** of covariance matrix
4. **Sort eigenvectors** by eigenvalue (descending)
5. **Select top k eigenvectors** (principal components)
6. **Project data** onto principal components

[color=yellow][b]Code:[/b][/color]
[code]
func pca(data: Array, num_components: int) -> Dictionary:
    var n_samples = data.size()
    var n_features = data[0].size()

    # Step 1: Center data (subtract mean)
    var mean = compute_mean(data)
    var centered = []
    for sample in data:
        var centered_sample = []
        for i in range(n_features):
            centered_sample.append(sample[i] - mean[i])
        centered.append(centered_sample)

    # Step 2: Compute covariance matrix
    var cov_matrix = compute_covariance(centered)

    # Step 3: Compute eigenvalues and eigenvectors
    var eigen_result = compute_eigen(cov_matrix)
    var eigenvalues = eigen_result.values
    var eigenvectors = eigen_result.vectors

    # Step 4: Sort by eigenvalue (descending)
    var sorted_indices = argsort_descending(eigenvalues)

    # Step 5: Select top k components
    var principal_components = []
    for i in range(num_components):
        var idx = sorted_indices[i]
        principal_components.append(eigenvectors[idx])

    # Step 6: Project data
    var transformed = project_data(centered, principal_components)

    return {
        "transformed": transformed,
        "components": principal_components,
        "explained_variance": eigenvalues
    }

func compute_mean(data: Array) -> Array:
    var n_samples = data.size()
    var n_features = data[0].size()
    var mean = []
    mean.resize(n_features)

    for i in range(n_features):
        var sum = 0.0
        for sample in data:
            sum += sample[i]
        mean[i] = sum / n_samples

    return mean

func compute_covariance(centered_data: Array) -> Array:
    var n_samples = centered_data.size()
    var n_features = centered_data[0].size()
    var cov = []

    for i in range(n_features):
        cov.append([])
        for j in range(n_features):
            var sum = 0.0
            for sample in centered_data:
                sum += sample[i] * sample[j]
            cov[i].append(sum / (n_samples - 1))

    return cov

func project_data(data: Array, components: Array) -> Array:
    var transformed = []

    for sample in data:
        var projected = []
        for component in components:
            var dot = 0.0
            for i in range(sample.size()):
                dot += sample[i] * component[i]
            projected.append(dot)
        transformed.append(projected)

    return transformed
[/code]

[hr]

[b]Eigenvalues and Eigenvectors[/b]

**Eigenvector:** Direction that matrix only scales (doesn't rotate).
**Eigenvalue:** Scale factor along eigenvector.

**For covariance matrix:**
- **Eigenvectors** = principal components (directions of variance)
- **Eigenvalues** = variance along each component

**Largest eigenvalue** → direction of maximum variance.

[hr]

[b]Explained Variance[/b]

**Each principal component explains some % of total variance.**

[color=yellow][b]Formula:[/b][/color]
```
Explained variance ratio = eigenvalue_i / sum(all eigenvalues)
```

[color=yellow][b]Example:[/b][/color]
```
Eigenvalues: [8.2, 3.1, 0.7]
Total: 12.0

PC1 explains: 8.2 / 12.0 = 68.3%
PC2 explains: 3.1 / 12.0 = 25.8%
PC3 explains: 0.7 / 12.0 = 5.8%

Keep PC1 + PC2 → retain 94.1% variance!
```

**Choose num_components based on cumulative explained variance** (e.g., keep components explaining 95% variance).

[hr]

[b]Applications[/b]

- **Visualization** (reduce to 2D/3D for plotting)
- **Compression** (images, signals - discard low-variance components)
- **Noise reduction** (keep high-variance signal, discard low-variance noise)
- **Feature extraction** (preprocessing for ML)
- **Data exploration** (understand data structure)

[hr]

[b]Example - Image Compression[/b]

[color=yellow][b]Grayscale image compression:[/b][/color]
[code]
func compress_image(image: Image, num_components: int) -> Image:
    var width = image.get_width()
    var height = image.get_height()

    # Treat each row as sample, each column as feature
    var data = []
    for y in range(height):
        var row = []
        for x in range(width):
            row.append(image.get_pixel(x, y).r)  # Grayscale
        data.append(row)

    # Apply PCA
    var pca_result = pca(data, num_components)

    # Reconstruct (project back to original space)
    var reconstructed = reconstruct_from_pca(
        pca_result.transformed,
        pca_result.components,
        compute_mean(data)
    )

    # Convert back to image
    var compressed = Image.new()
    # ... fill image from reconstructed data

    return compressed

# Typical: 512 features (columns) → 50 components
# Compression ratio: ~10x
# Quality: Often visually indistinguishable
[/code]

[hr]

[b]Limitations[/b]

**1. Linear only**
PCA finds linear combinations - cannot capture nonlinear patterns.
**Solution:** Kernel PCA, t-SNE, UMAP (nonlinear methods).

**2. Variance ≠ importance**
PCA assumes high-variance directions are important - not always true.

**3. Sensitive to scaling**
Features with large values dominate. **Must standardize** (z-score normalization).

**4. Interpretability**
Principal components = linear combinations of original features - hard to interpret.

[hr]

[b]Queer PCA[/b]

**PCA asks: which dimensions matter most?**

**It reduces dimensions** - discards "unimportant" axes.

**This is dimensional compression:**
- **Some dimensions privileged** (high variance → kept)
- **Others erased** (low variance → discarded)
- **Projection loses information** (cannot recover discarded components)

**Queer question:** Who decides which dimensions are "noise"?

**Low variance ≠ unimportant** - might be crucial but rare signal.

[hr]

[b]Explained Variance as Normative[/b]

**PCA keeps dimensions explaining most variance.**

**Rare patterns (low variance) discarded** as "noise."

**This is majoritarian logic:**
- **Common patterns preserved** (high variance)
- **Rare patterns erased** (low variance)
- **Majority defines signal** (minority = noise)

**Queer patterns often low-variance** - rare, not fitting dominant distribution.

**PCA might erase queerness** as statistical noise.

[hr]

[b]Centering as Normalization[/b]

**PCA requires centering** - subtract mean from all data.

**Mean = average identity** - center of data distribution.

**After centering:** Everything measured as deviation from average.

**This is normative centering:**
- **Mean becomes origin** (zero point)
- **Everything relative to average** (deviation from norm)
- **Outliers defined by distance from mean**

**Queer bodies far from mean** - PCA emphasizes our deviation.

**Centering enforces norm** - literally makes average = zero, all else = distance from average.

[hr]

[b]Orthogonal Components[/b]

**Principal components are orthogonal** (perpendicular).

**Each PC independent** - no correlation between them.

**This is decorrelation:**
- **Entangled features → independent components**
- **Correlation removed** (orthogonalized)
- **Axes aligned to variance** (not to original features)

**Queer decorrelation:** PCA separates what was entangled.

**Original axes might be correlated** (height and weight).
**New axes uncorrelated** (PC1, PC2 independent).

**Orthogonality enforced** - components cannot overlap.

[hr]

[b]Reconstruction Loss[/b]

**Discarding components loses information.**

**Reconstruction:** Project to k dimensions, then back to original space.

**Reconstruction error** = information lost.

[color=yellow][b]What's lost:[/b][/color]
- **Fine details** (high-frequency noise)
- **Rare patterns** (low-variance structure)
- **Nuance** (subtlety in discarded dimensions)

**Queer loss:** What cannot be reconstructed after dimensional reduction?

**Some identities don't survive compression** - too nuanced, too rare, too many dimensions.

**PCA says:** This much variance is "good enough."

**But for whom?** Reconstruction loss not evenly distributed.

[hr]

[b]Eigenvalues as Hierarchy[/b]

**Eigenvalues ranked** - largest first.

**This creates hierarchy of dimensions:**
- **PC1 = most important** (largest eigenvalue)
- **PC2 = second** (next largest)
- **PC_n = least important** (smallest)

**Queer resistance to hierarchy:** Why rank dimensions?

**All dimensions might matter** - for different reasons, at different times.

**PCA imposes global ranking** - assumes universal importance order.

**But importance is contextual** - what's signal to one is noise to another.

[hr]

[color=cyan][b]Summary:[/b][/color]
PCA: dimensionality reduction via principal components. Find directions of maximum variance (eigenvectors of covariance matrix). Eigenvalues = variance along components. Keep top k components explaining most variance. Steps: center data, covariance matrix, eigendecomposition, sort, project. Applications: visualization, compression, noise reduction, feature extraction. Limitations: linear only, variance ≠ importance, scaling-sensitive, interpretation hard. Queer PCA: dimensional compression (some dimensions erased), explained variance as majoritarian (rare = noise), centering as normalization (mean = origin), orthogonal components (decorrelation enforced), reconstruction loss (what doesn't survive compression), eigenvalue hierarchy (global ranking assumes universal importance). Low-variance patterns might be queer signal, not noise.

'''
