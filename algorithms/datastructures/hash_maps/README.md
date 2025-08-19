# Hash Maps

## Overview
Hash maps (also known as hash tables or dictionaries) are data structures that provide efficient key-value storage and retrieval. They use hash functions to map keys to array indices, enabling average-case O(1) time complexity for insertions, deletions, and lookups.

## What are Hash Maps?
A hash map is a data structure that stores key-value pairs using a hash function to compute an index into an array of buckets or slots. This design allows for fast access to data based on a key, making hash maps one of the most efficient data structures for associative arrays.

## Core Concepts

### Hash Function
- **Purpose**: Maps keys to array indices
- **Properties**: Deterministic, uniform distribution, fast computation
- **Requirements**: Same key always produces same hash, different keys ideally produce different hashes
- **Examples**: Division method, multiplication method, cryptographic hashes

### Bucket Array
- **Structure**: Array of linked lists or other collision resolution structures
- **Size**: Should be prime number to reduce clustering
- **Load Factor**: Ratio of elements to array size
- **Resizing**: Dynamic expansion when load factor exceeds threshold

### Collision Resolution
- **Separate Chaining**: Each bucket contains a linked list of entries
- **Open Addressing**: Probing for next available slot
- **Linear Probing**: Check next consecutive slot
- **Quadratic Probing**: Check slots with quadratic spacing

## Implementation Details

### Basic Structure
```gdscript
class HashMap:
    var buckets: Array
    var size: int
    var load_factor: float
    
    func _init(initial_size: int = 16):
        buckets = []
        buckets.resize(initial_size)
        size = 0
        load_factor = 0.75
```

### Key Operations
- **Insert**: Hash key, resolve collisions, store value
- **Get**: Hash key, search bucket, return value
- **Delete**: Hash key, remove from bucket
- **Contains**: Hash key, check if key exists

## Performance Characteristics

### Time Complexity
- **Average Case**: O(1) for insert, get, delete
- **Worst Case**: O(n) when all keys hash to same bucket
- **Best Case**: O(1) with perfect hash function
- **Amortized**: O(1) including resizing operations

### Space Complexity
- **Storage**: O(n) for n key-value pairs
- **Overhead**: Array space + collision resolution structures
- **Load Factor**: Typically 0.7-0.8 for optimal performance
- **Memory Efficiency**: Better than binary search trees

## Hash Function Design

### Good Hash Functions
- **Uniformity**: Distribute keys evenly across buckets
- **Speed**: Fast computation for good performance
- **Determinism**: Same input always produces same output
- **Avalanche Effect**: Small input changes cause large output changes

### Common Hash Functions
- **Division Method**: h(k) = k mod m
- **Multiplication Method**: h(k) = floor(m * (k * A mod 1))
- **Universal Hashing**: Random hash function family
- **Cryptographic Hashes**: SHA, MD5 (overkill for most applications)

## Collision Resolution Strategies

### Separate Chaining
- **Implementation**: Linked list at each bucket
- **Advantages**: Simple, handles arbitrary number of collisions
- **Disadvantages**: Extra memory for list overhead
- **Best For**: Variable collision rates, memory not critical

### Open Addressing
- **Implementation**: Store directly in bucket array
- **Advantages**: Better memory locality, no extra structures
- **Disadvantages**: More complex deletion, clustering issues
- **Best For**: Fixed size, memory critical applications

### Probing Methods
- **Linear**: h(k, i) = (h(k) + i) mod m
- **Quadratic**: h(k, i) = (h(k) + c₁i + c₂i²) mod m
- **Double Hashing**: h(k, i) = (h₁(k) + i * h₂(k)) mod m

## Advanced Features

### Dynamic Resizing
- **Trigger**: When load factor exceeds threshold
- **Process**: Create new larger array, rehash all entries
- **Strategy**: Double size, rehash incrementally
- **Performance**: Amortized O(1) cost per operation

### Load Factor Management
- **Optimal Range**: 0.7 to 0.8 for most applications
- **Too Low**: Wasted memory, poor cache performance
- **Too High**: Increased collision rate, degraded performance
- **Adaptive**: Adjust based on collision patterns

## Applications

### General Purpose
- **Dictionaries**: Word definitions, language translation
- **Caching**: Store computed results for reuse
- **Database Indexing**: Fast record lookup by key
- **Symbol Tables**: Compiler and interpreter implementations

### Specialized Uses
- **Set Implementation**: Store unique elements
- **Frequency Counting**: Count occurrences of items
- **Graph Representation**: Adjacency lists and matrices
- **Object Storage**: Property-value mappings

## VR Visualization Benefits

### Interactive Learning
- **Hash Function Visualization**: See how keys map to buckets
- **Collision Demonstration**: Observe collision resolution in action
- **Performance Analysis**: Visualize time complexity differences
- **Load Factor Effects**: Understand impact of array sizing

### Educational Value
- **Concept Understanding**: Grasp hash function principles
- **Algorithm Behavior**: See how operations affect structure
- **Optimization**: Understand trade-offs between strategies
- **Debugging**: Identify and fix collision issues

## Common Pitfalls

### Implementation Issues
- **Poor Hash Functions**: Uneven distribution causing clustering
- **Incorrect Collision Handling**: Infinite loops or data loss
- **Memory Leaks**: Not cleaning up collision structures
- **Race Conditions**: Concurrent access without synchronization

### Design Considerations
- **Over-optimization**: Premature optimization of hash functions
- **Memory Waste**: Choosing wrong collision resolution strategy
- **Scalability Issues**: Not considering resizing requirements
- **Security**: Using predictable hash functions for sensitive data

## Performance Optimization

### Hash Function Tuning
- **Custom Functions**: Domain-specific hash functions
- **Perfect Hashing**: No collisions for known key sets
- **Universal Hashing**: Randomized hash functions
- **Cryptographic**: High-quality but slower hash functions

### Memory Optimization
- **Compact Storage**: Minimize per-entry overhead
- **Cache Locality**: Optimize memory access patterns
- **Lazy Allocation**: Only allocate collision structures when needed
- **Compression**: Reduce memory footprint for large datasets

## Future Extensions

### Advanced Techniques
- **Cuckoo Hashing**: Constant worst-case lookup time
- **Hopscotch Hashing**: Cache-friendly open addressing
- **Robin Hood Hashing**: Reduce variance in probe lengths
- **Swiss Tables**: High-performance open addressing

### Machine Learning Integration
- **Learned Hash Functions**: AI-optimized hash functions
- **Adaptive Resizing**: ML-based load factor management
- **Collision Prediction**: Learning collision patterns
- **Performance Optimization**: Automated parameter tuning

## References
- "Introduction to Algorithms" by Cormen, Leiserson, Rivest, and Stein
- "The Art of Computer Programming" by Donald Knuth
- "Hash Tables" by Robert Sedgewick

---

*Hash maps provide one of the most efficient ways to store and retrieve data by key, making them essential for high-performance applications requiring fast associative access.*
