**PCA: Principal Component Analysis**
Dimensionality Reduction, Eigenvalues, Variance Maximization

**PCA reduces high-dimensional data to lower dimensions while preserving variance.**

**Core idea:** Find **principal components** - directions of maximum variance.

**Result:** Transform data to new coordinate system where axes = principal components.

---

## Concept

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

---

## Algorithm

**Steps:**
1. **Center data** (subtract mean)
2. **Compute covariance matrix**
3. **Find eigenvalues and eigenvectors** of covariance matrix
4. **Sort eigenvectors** by eigenvalue (descending)
5. **Select top k eigenvectors** (principal components)
6. **Project data** onto principal components

**Code:**

func pca(data: Array, num_components: int) -> Dictionary:
    var n_samples = data.size()
    var n_features = data[0].size()

    # Step 1: Center data (subtract mean)
    var mean = compute_mean(data)
    var centered = []
    for sample in data:
        var centered_sample = []
        for i in range(n_features):
            centered_sample.append(sample - mean)
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
        var idx = sorted_indices
        principal_components.append(eigenvectors)

    # Step 6: Project data
    var transformed = project_data(centered, principal_components)

    return {