# Recursion Algorithms Collection

## Overview
Explore the elegant world of self-referential algorithms through immersive VR experiences. From fractal trees to recursive data structures, discover how simple recursive rules create infinite complexity and solve problems by breaking them into smaller versions of themselves.

## Contents

### 🌳 **Recursive Structures**
- **[Recursive Tree](recursivetree/)** - Self-similar branching structures in nature
- **[Koch Curve](koshcurve/)** - Fractal coastlines and self-similar geometry

## 🎯 **Learning Objectives**
- Master the fundamental concept of recursion in computer science
- Understand base cases, recursive cases, and termination conditions
- Visualize recursive algorithms through growing fractal structures
- Experience the relationship between recursion and mathematical induction
- Explore how recursive thinking applies to problem-solving

## 🔄 **Recursion Fundamentals**

### **Recursive Algorithm Structure**
```gdscript
# Basic recursive function template
func recursive_function(input: Variant, depth: int = 0) -> Variant:
    # Base case - prevents infinite recursion
    if base_condition_met(input) or depth > MAX_DEPTH:
        return base_case_result(input)
    
    # Recursive case - function calls itself with modified input
    var modified_input = transform_input(input)
    return combine_results(
        process_current_level(input),
        recursive_function(modified_input, depth + 1)
    )

# Example: Factorial calculation
func factorial(n: int) -> int:
    if n <= 1:  # Base case
        return 1
    else:       # Recursive case
        return n * factorial(n - 1)
```

### **Key Concepts**
- **Base Case**: The stopping condition that prevents infinite recursion
- **Recursive Case**: The part where the function calls itself
- **Problem Reduction**: Breaking larger problems into smaller subproblems
- **Stack Depth**: Memory usage considerations in recursive calls
- **Tail Recursion**: Optimization technique for certain recursive patterns

## 🌿 **Recursive Tree Generation**

### **L-System Tree Growth**
```gdscript
class RecursiveTree:
    var branch_angle: float = 30.0
    var length_ratio: float = 0.7
    var min_length: float = 5.0
    
    func generate_tree(start_pos: Vector3, direction: Vector3, length: float, depth: int):
        # Base case - stop when branches become too small
        if length < min_length or depth <= 0:
            return
        
        # Draw current branch
        var end_pos = start_pos + direction * length
        draw_branch(start_pos, end_pos)
        
        # Recursive case - generate child branches
        var new_length = length * length_ratio
        var left_direction = direction.rotated(Vector3.UP, deg_to_rad(branch_angle))
        var right_direction = direction.rotated(Vector3.UP, deg_to_rad(-branch_angle))
        
        # Recursive calls for left and right branches
        generate_tree(end_pos, left_direction, new_length, depth - 1)
        generate_tree(end_pos, right_direction, new_length, depth - 1)
        
        # Optional: Add randomness for natural appearance
        if randf() > 0.3:  # Sometimes add a third branch
            var up_direction = direction.rotated(Vector3.RIGHT, deg_to_rad(15))
            generate_tree(end_pos, up_direction, new_length * 0.5, depth - 1)
```

### **Fractal Properties**
- **Self-Similarity**: Each branch is a scaled copy of the whole tree
- **Infinite Detail**: Recursive generation can continue indefinitely
- **Scale Invariance**: Patterns look similar at different zoom levels
- **Emergent Complexity**: Complex forms from simple recursive rules

## ❄️ **Koch Curve and Fractals**

### **Koch Snowflake Generation**
```gdscript
class KochCurve:
    func generate_koch_curve(start: Vector2, end: Vector2, depth: int) -> Array[Vector2]:
        # Base case - return straight line
        if depth == 0:
            return [start, end]
        
        # Recursive case - divide line into Koch segments
        var points = []
        var direction = end - start
        var segment_length = direction.length() / 3.0
        var unit_direction = direction.normalized()
        
        # Calculate the four points of Koch curve segment
        var p1 = start
        var p2 = start + unit_direction * segment_length
        var p3 = p2 + unit_direction.rotated(deg_to_rad(60)) * segment_length
        var p4 = start + unit_direction * segment_length * 2
        var p5 = end
        
        # Recursive calls for each segment
        points.append_array(generate_koch_curve(p1, p2, depth - 1))
        points.append_array(generate_koch_curve(p2, p3, depth - 1))
        points.append_array(generate_koch_curve(p3, p4, depth - 1))
        points.append_array(generate_koch_curve(p4, p5, depth - 1))
        
        return points
```

### **Fractal Mathematics**
- **Hausdorff Dimension**: Non-integer dimensional measurements
- **Iteration Rules**: How patterns transform at each recursive level
- **Geometric Series**: Mathematical foundation of fractal scaling
- **Measure Theory**: Understanding length, area, and volume in fractals

## 🔢 **Recursive Data Structures**

### **Binary Tree Operations**
```gdscript
class TreeNode:
    var value: Variant
    var left: TreeNode
    var right: TreeNode
    
    func insert(new_value: Variant):
        if new_value < value:
            if left == null:
                left = TreeNode.new(new_value)
            else:
                left.insert(new_value)  # Recursive call
        else:
            if right == null:
                right = TreeNode.new(new_value)
            else:
                right.insert(new_value)  # Recursive call
    
    func search(target: Variant) -> bool:
        if value == target:
            return true
        elif target < value and left != null:
            return left.search(target)  # Recursive call
        elif target > value and right != null:
            return right.search(target)  # Recursive call
        else:
            return false
    
    func in_order_traversal() -> Array:
        var result = []
        if left != null:
            result.append_array(left.in_order_traversal())  # Recursive call
        result.append(value)
        if right != null:
            result.append_array(right.in_order_traversal())  # Recursive call
        return result
```

## 🚀 **VR Recursive Experience**

### **Immersive Recursion Visualization**
- **Growing Structures**: Watch trees and fractals grow through recursive generations
- **Interactive Parameters**: Adjust recursion depth, branching angles, and scaling factors
- **Multi-scale Exploration**: Zoom into fractal details and discover self-similarity
- **Step-by-step Animation**: See each recursive call as it builds the structure

### **Recursive Problem Solving**
- **Divide and Conquer**: Experience how complex problems break down
- **Call Stack Visualization**: See the recursive call stack as a 3D structure
- **Base Case Discovery**: Experiment with different stopping conditions
- **Memory Usage**: Observe stack depth and memory consumption

## 🧮 **Mathematical Recursion**

### **Fibonacci Sequence**
```gdscript
func fibonacci(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# Optimized with memoization
var fib_cache = {}
func fibonacci_memo(n: int) -> int:
    if n in fib_cache:
        return fib_cache[n]
    
    if n <= 1:
        fib_cache[n] = n
    else:
        fib_cache[n] = fibonacci_memo(n - 1) + fibonacci_memo(n - 2)
    
    return fib_cache[n]
```

### **Recursive Sequences**
- **Golden Ratio**: Emerges from Fibonacci sequence ratios
- **Catalan Numbers**: Counting recursive structures
- **Pascal's Triangle**: Recursive binomial coefficients
- **Ackermann Function**: Extreme recursion growth rates

## 🔗 **Related Categories**
- [Data Structures](../datastructures/) - Recursive data organization
- [Procedural Generation](../proceduralgeneration/) - Recursive pattern creation
- [Alternative Geometries](../alternativegeometries/) - Self-similar geometric structures
- [Chaos Theory](../chaos/) - Recursive dynamics in chaotic systems

## 🌍 **Applications**

### **Computer Graphics**
- **Fractal Landscapes**: Terrain generation using recursive subdivision
- **Procedural Trees**: Natural-looking vegetation creation
- **Texture Synthesis**: Self-similar pattern generation
- **Ray Tracing**: Recursive light bounce calculations

### **Natural Sciences**
- **Botanical Modeling**: Plant growth patterns and phyllotaxis
- **Geological Structures**: Coastline and mountain formation
- **Biological Systems**: Recursive patterns in nature (lungs, blood vessels)
- **Crystal Growth**: Iterative material formation processes

### **Computer Science**
- **Algorithm Design**: Divide-and-conquer problem solving
- **Parsing**: Recursive descent parsers for programming languages
- **File Systems**: Directory tree traversal
- **Artificial Intelligence**: Recursive search algorithms

### **Mathematics**
- **Number Theory**: Recursive sequence investigation
- **Geometry**: Self-similar shape construction
- **Calculus**: Limits and infinite series
- **Graph Theory**: Recursive graph traversal algorithms

## 🎨 **Recursive Art**

### **Generative Aesthetics**
- **Infinite Detail**: Art that reveals new patterns at every scale
- **Emergent Beauty**: Complex aesthetics from simple rules
- **Interactive Exploration**: User-driven recursive parameter adjustment
- **Temporal Recursion**: Recursive patterns that evolve over time

### **Cultural Recursion**
- **Self-Reference**: Art about art, code about code
- **Meta-Patterns**: Patterns of patterns in cultural expression
- **Recursive Narratives**: Stories within stories
- **Technological Reflection**: Computing examining itself

## ⚡ **Performance Considerations**
- **Stack Overflow**: Managing recursion depth limits
- **Memoization**: Caching results to avoid redundant calculations
- **Tail Recursion**: Converting to iterative forms for efficiency
- **Space Complexity**: Understanding memory usage in recursive algorithms

---
*"To understand recursion, you must first understand recursion." - Programming Proverb*

*Discovering infinite complexity through self-referential simplicity*