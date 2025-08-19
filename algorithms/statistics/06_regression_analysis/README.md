# Interactive VR Regression Analysis - Predictive Modeling

## Overview
This VR experience teaches regression analysis through interactive data visualization. Players can manipulate data points, fit regression lines, and understand how models predict outcomes while learning about correlation, R-squared, and residual analysis.

## Educational Objectives
- **Linear Relationships**: Understanding correlation and causation
- **Least Squares Method**: How regression lines minimize prediction errors
- **Model Evaluation**: R-squared, RMSE, and residual analysis
- **Overfitting vs Underfitting**: Model complexity trade-offs
- **Prediction vs Explanation**: Different goals of statistical modeling

## VR Interaction
- **Trigger**: Fit regression model to current data
- **Grip**: Toggle interactive point adding mode
- **Point Manipulation**: Add/remove data points to see model changes
- **Visual Feedback**: Real-time regression line and statistics updates

## Algorithm Features
1. **Multiple Regression Types**: Linear, polynomial, multiple, and logistic
2. **Interactive Data Points**: Add/modify points and see immediate effects
3. **Real-Time Model Fitting**: Instant least squares calculations
4. **Residual Visualization**: Color-coded prediction errors
5. **Statistical Metrics**: R², correlation, RMSE, and more

## Regression Methods

### Linear Regression
- **Model**: y = mx + b
- **Method**: Minimize sum of squared residuals using least squares
- **Assumptions**: Linear relationship, constant variance, independence
- **Output**: Slope (m) and intercept (b) coefficients

### Multiple Regression
- **Model**: y = β₀ + β₁x₁ + β₂x₂ + ... + βₙxₙ
- **3D Visualization**: Plane fitting through data points
- **Applications**: Multiple predictor variables
- **Implementation**: Matrix-based least squares solution
- **Challenges**: Multicollinearity and interpretation

### Polynomial Regression
- **Model**: y = β₀ + β₁x + β₂x² + ... + βₙxⁿ
- **Implementation**: Full matrix-based solution using Cramer's rule
- **Use Case**: Non-linear relationships
- **Risk**: Overfitting with high degrees
- **Visualization**: Curved regression lines

### Logistic Regression
- **Model**: P(y=1) = 1 / (1 + e^(-(β₀ + β₁x)))
- **Implementation**: Gradient descent optimization
- **Use Case**: Binary classification problems
- **Metrics**: McFadden's pseudo R-squared, deviance residuals
- **Visualization**: Sigmoid curve

### Ridge Regression (L2 Regularization)
- **Model**: y = β₀ + β₁x with penalty λΣβᵢ²
- **Implementation**: Analytical solution with regularized normal equations
- **Use Case**: Handling multicollinearity, preventing overfitting
- **Parameter**: Regularization strength λ
- **Effect**: Shrinks coefficients toward zero

### Lasso Regression (L1 Regularization)
- **Model**: y = β₀ + β₁x with penalty λΣ|βᵢ|
- **Implementation**: Coordinate descent with soft thresholding
- **Use Case**: Feature selection, sparse models
- **Parameter**: Regularization strength λ
- **Effect**: Can set coefficients exactly to zero

## Key Concepts

### Least Squares Method
- **Objective**: Minimize Σ(yᵢ - ŷᵢ)²
- **Solution**: Mathematical optimization for best fit
- **Properties**: Unbiased, minimum variance estimator
- **Visual**: Line that minimizes total residual distances

### Model Evaluation Metrics

#### R-squared (Coefficient of Determination)
- **Definition**: Proportion of variance explained by model
- **Range**: 0 to 1 (higher = better fit)
- **Formula**: R² = 1 - (SS_res / SS_tot)
- **Interpretation**: 0.8 means 80% of variance explained

#### Correlation Coefficient
- **Definition**: Strength and direction of linear relationship
- **Range**: -1 to +1
- **Interpretation**: ±1 = perfect linear relationship, 0 = no relationship

#### Root Mean Square Error (RMSE)
- **Definition**: Standard deviation of residuals
- **Units**: Same as dependent variable
- **Use**: Comparing models, assessing prediction accuracy

#### Adjusted R-squared
- **Definition**: R² adjusted for number of predictors
- **Formula**: 1 - (1 - R²)(n-1)/(n-p-1)
- **Use**: Comparing models with different numbers of parameters

#### Information Criteria
- **AIC**: Akaike Information Criterion - n×ln(MSE) + 2p
- **BIC**: Bayesian Information Criterion - n×ln(MSE) + p×ln(n)
- **Use**: Model selection, balancing fit and complexity

### Residual Analysis
- **Residual**: Difference between observed and predicted values
- **Pattern Check**: Random residuals indicate good model
- **Outlier Detection**: Large residuals may indicate unusual data
- **Assumption Validation**: Check for constant variance

## Visual Elements
- **Scatter Plot**: Data points in 2D/3D space
- **Regression Line/Plane**: Best-fit model visualization
- **Residual Lines**: Green (positive) and orange (negative) error lines
- **Statistics Panel**: Real-time R², correlation, RMSE display
- **Equation Display**: Mathematical model representation

## Parameters
- `num_data_points`: Number of sample data points (default: 50)
- `noise_level`: Amount of random error in data (default: 0.3)
- `true_slope`: Hidden true relationship slope (default: 2.0)
- `true_intercept`: Hidden true relationship intercept (default: 1.0)
- `regularization_lambda`: Regularization strength for Ridge/Lasso (default: 0.1)
- `max_iterations`: Maximum iterations for iterative methods (default: 1000)
- `learning_rate`: Learning rate for gradient descent (default: 0.01)
- `convergence_threshold`: Convergence criterion (default: 1e-6)

## Key Insights
- **Correlation ≠ Causation**: Strong relationships don't imply cause
- **Model Assumptions**: Violations can invalidate conclusions
- **Sample Size**: More data generally improves model reliability
- **Outlier Influence**: Single points can dramatically affect results
- **Prediction Uncertainty**: Models have inherent limitations

## Interactive Learning
- Add outliers and observe their effect on the regression line
- Compare R² values with different data patterns
- Experiment with sample sizes and noise levels
- Try different regression types on the same data

## Real-World Applications
- **Economics**: Demand forecasting, price modeling
- **Medicine**: Dose-response relationships, risk factors
- **Engineering**: Performance optimization, quality control
- **Marketing**: Sales prediction, customer behavior
- **Science**: Experimental data analysis, theory testing

## Implemented Features ✅
- **Complete Regression Suite**: Linear, polynomial, multiple, logistic, Ridge, Lasso
- **Advanced Statistics**: Adjusted R², AIC, BIC, confidence intervals
- **Interactive Visualization**: Real-time fitting, residual analysis
- **Proper Implementations**: Matrix operations, gradient descent, regularization
- **VR Integration**: Immersive data manipulation and visualization

## Potential Extensions
- Cross-validation for model selection
- Bootstrap confidence intervals
- More advanced regularization (Elastic Net)
- Interactive hyperparameter tuning
- Model comparison dashboard
- Time series regression
- Robust regression methods