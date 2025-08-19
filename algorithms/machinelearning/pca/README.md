# Principal Component Analysis (PCA) Visualization

## 📊 Dimensional Reduction & Identity Compression

A comprehensive implementation of Principal Component Analysis with real-time visualization of eigenvalue decomposition, data projection, and variance explanation. This algorithm explores the politics of dimensionality reduction and demonstrates how high-dimensional identity data can be compressed while preserving essential information.

## 🎯 Algorithm Overview

Principal Component Analysis is a dimensionality reduction technique that projects high-dimensional data onto a lower-dimensional space by finding the directions (principal components) of maximum variance. It uses eigenvalue decomposition of the covariance matrix to identify these optimal directions.

### Key Concepts

1. **Eigenvalue Decomposition**: Finding eigenvectors and eigenvalues of the covariance matrix
2. **Principal Components**: Orthogonal directions of maximum variance in the data
3. **Variance Explained**: How much information each component captures
4. **Dimensionality Reduction**: Projecting onto fewer dimensions while preserving variance

## 🔧 Technical Implementation

### Core Algorithm Features

- **Step-by-Step Computation**: Animated eigenvalue decomposition process
- **3D Visualization**: Original and projected data in 3D space
- **Principal Component Vectors**: Visual representation of PC directions
- **Variance Analysis**: Real-time calculation of explained variance
- **Interactive Controls**: Toggle different visualization elements

### Mathematical Process

1. **Data Centering**: Subtract mean from each feature
2. **Normalization**: Optionally standardize features
3. **Covariance Matrix**: Compute feature covariances
4. **Eigendecomposition**: Find eigenvalues and eigenvectors
5. **Component Selection**: Choose top k components
6. **Data Projection**: Transform to reduced space

### Algorithm Steps
```
1. Center Data: X_centered = X - mean(X)
2. Normalize: X_norm = X_centered / std(X)
3. Covariance: C = (X_norm^T * X_norm) / (n-1)
4. Eigendecomposition: C * v = λ * v
5. Sort by eigenvalue: λ₁ ≥ λ₂ ≥ ... ≥ λₙ
6. Project: Y = X_norm * V_k
```

## 🎮 Interactive Controls

### Basic Controls
- **SPACE**: Start/Stop PCA computation
- **R**: Reset and regenerate data
- **1**: Toggle original data display
- **2**: Toggle projected data display
- **3**: Toggle principal component vectors

### Configuration Parameters
- **Original Dimensions**: Input data dimensionality (4D default)
- **Target Dimensions**: Reduced space dimensions (2D default)
- **Normalize Data**: Standardize features before PCA
- **Center Data**: Remove mean from features
- **Animation Speed**: Control computation visualization speed

## 📊 Visualization Features

### 3D Data Representation
- **Original Data**: Blue spheres showing high-dimensional data (first 3 dims)
- **Projected Data**: Red spheres showing reduced-dimensional data
- **Principal Components**: Colored arrows showing PC directions
- **Variance Labels**: Percentage of variance explained by each PC

### Color Coding
- **PC1**: Magenta (highest variance direction)
- **PC2**: Green (second highest variance)
- **PC3**: Yellow (third highest variance)
- **Original Data**: Semi-transparent blue
- **Projected Data**: Solid red

### Information Display
- **Eigenvalues**: Numerical values showing variance captured
- **Explained Variance**: Percentage and cumulative percentages
- **Reconstruction Error**: Quality measure of dimensionality reduction
- **Computation Progress**: Step-by-step algorithm progress

## 🏳️‍🌈 Identity Compression Framework

### Dimensional Politics
PCA raises critical questions about information compression and identity representation:

- **What gets lost in compression?** Non-principal variance often contains important edge cases
- **Who decides what's "principal"?** The algorithm privileges directions of maximum variance
- **How do we measure information loss?** Reconstruction error quantifies but doesn't qualify loss
- **What about rare but important variations?** Low-variance features may be crucial for minorities

### Algorithmic Justice Questions
1. **Variance Privilege**: Does maximizing variance reinforce dominant patterns?
2. **Information Hierarchy**: How do we value different types of variation?
3. **Compression Ethics**: Is lossy compression ever neutral?
4. **Dimensional Bias**: Do fewer dimensions necessarily mean better models?

## 🔬 Educational Applications

### Linear Algebra Concepts
- **Eigenvalue Decomposition**: Core mathematical foundation
- **Matrix Operations**: Covariance, multiplication, transposition
- **Vector Spaces**: Orthogonality and basis transformations
- **Optimization**: Maximizing variance under constraints

### Statistics Integration
- **Variance Analysis**: Understanding data spread and correlation
- **Dimensionality Curse**: Why reduction is often necessary
- **Information Theory**: Measuring and preserving information
- **Multivariate Analysis**: Handling correlated variables

## 📈 Performance Characteristics

### Computational Complexity
- **Covariance Computation**: O(n²d) where n=samples, d=dimensions
- **Eigendecomposition**: O(d³) for exact methods
- **Data Projection**: O(ndk) where k=target dimensions
- **Memory**: O(nd + d²) for data and covariance matrix

### Algorithm Strengths
- **Optimal Linear Reduction**: Maximizes preserved variance
- **Decorrelates Features**: Removes linear correlations
- **Interpretable Components**: PCs have clear geometric meaning
- **Analytical Solution**: No iterative optimization required

### Algorithm Limitations
- **Linear Assumptions**: Cannot capture non-linear relationships
- **Variance Bias**: May discard low-variance but important features
- **Interpretability Loss**: Original features become combinations
- **Sensitive to Scaling**: Requires normalization for meaningful results

## 🎓 Learning Objectives

### Primary Goals
1. **Understand eigenvalue decomposition** and its geometric interpretation
2. **Explore variance maximization** as an optimization principle
3. **Analyze information loss** in dimensionality reduction
4. **Examine the politics of compression** and what gets preserved vs. discarded

### Advanced Topics
- **Kernel PCA**: Non-linear dimensionality reduction
- **Sparse PCA**: Interpretable component selection
- **Incremental PCA**: Handling large datasets
- **Probabilistic PCA**: Uncertainty quantification

## 🔍 Experimental Scenarios

### Recommended Explorations

1. **Correlation Impact**
   - Generate highly correlated features
   - Observe PC1 direction alignment
   - Compare explained variance ratios

2. **Noise Analysis**
   - Add increasing levels of noise
   - Study reconstruction error changes
   - Identify when PCA breaks down

3. **Dimensionality Effects**
   - Vary original dimensions (2-8)
   - Change target dimensions (1-4)
   - Analyze cumulative variance explained

4. **Normalization Impact**
   - Compare normalized vs. raw data
   - Use features with different scales
   - Observe PC direction changes

## 🚀 Advanced Features

### Customization Options
- **Data Generation**: Controllable correlation structure
- **Visualization Modes**: Toggle different display elements
- **Animation Control**: Step-by-step or immediate computation
- **Statistical Analysis**: Detailed variance and error metrics

### Extension Possibilities
- **Non-linear Methods**: t-SNE, UMAP integration
- **Interactive Projection**: Real-time dimension selection
- **Reconstruction Visualization**: Show information loss visually
- **Feature Importance**: Highlight most influential original features

## 🎯 Critical Questions for Reflection

1. **How does PCA privilege certain types of variation over others?**
2. **What are the ethical implications of lossy data compression?**
3. **When might low-variance features be more important than high-variance ones?**
4. **How do we balance interpretability with dimensionality reduction?**

## 📚 Further Reading

### Foundational Mathematics
- Jolliffe, I. T. (2002). Principal Component Analysis (2nd ed.)
- Pearson, K. (1901). On Lines and Planes of Closest Fit
- Hotelling, H. (1933). Analysis of a Complex of Statistical Variables

### Modern Applications
- Abdi, H., & Williams, L. J. (2010). Principal Component Analysis
- Shlens, J. (2014). A Tutorial on Principal Component Analysis
- Wold, S., Esbensen, K., & Geladi, P. (1987). Principal Component Analysis

### Critical Algorithm Studies
- D'Ignazio, C., & Klein, L. F. (2020). Data Feminism
- Benjamin, R. (2019). Race After Technology
- Eubanks, V. (2018). Automating Inequality

## 🔧 Technical Implementation Details

### Power Iteration Method
```gdscript
# Simplified eigenvalue computation
func power_iteration(matrix, max_iterations):
    vector = random_unit_vector()
    
    for i in range(max_iterations):
        new_vector = matrix * vector
        eigenvalue = dot(vector, new_vector)
        vector = normalize(new_vector)
        
        if converged():
            break
    
    return {eigenvalue, eigenvector}
```

### Data Projection
```gdscript
# Project data onto principal components
func project_data(data, components):
    projected = []
    for sample in data:
        projection = []
        for pc in components:
            projection.append(dot(sample, pc))
        projected.append(projection)
    return projected
```

### Variance Calculation
```gdscript
# Calculate explained variance ratios
func calculate_variance_explained(eigenvalues):
    total_variance = sum(eigenvalues)
    explained_ratios = []
    for eigenvalue in eigenvalues:
        explained_ratios.append(eigenvalue / total_variance)
    return explained_ratios
```

## 📊 Evaluation Metrics

### Quality Measures
- **Explained Variance Ratio**: Proportion of variance captured
- **Cumulative Variance**: Total variance preserved
- **Reconstruction Error**: Average distance between original and reconstructed
- **Component Orthogonality**: Ensuring PCs are perpendicular

### Diagnostic Tools
- **Scree Plot**: Eigenvalue magnitude visualization
- **Biplot**: Simultaneous data and PC visualization
- **Loading Matrix**: Feature contributions to PCs
- **Reconstruction Quality**: Per-sample error analysis

---

**Status**: ✅ Complete - Production Ready  
**Complexity**: Advanced Machine Learning  
**Prerequisites**: Linear Algebra, Statistics, Matrix Calculus  
**Estimated Learning Time**: 4-6 hours for mathematical concepts, 10+ hours for deep understanding 