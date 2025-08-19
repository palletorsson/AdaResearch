# B-Tree Visualization

## 🌳 Hierarchical Data Organization & Database Democracy

A comprehensive implementation of B-Trees with interactive database indexing visualization, node splitting animation, and hierarchical data organization analysis. This implementation explores the mathematics of balanced tree structures, the politics of information access, and democratic principles in data organization.

## 🎯 Algorithm Overview

B-Trees are self-balancing tree data structures that maintain sorted data and allow searches, sequential access, insertions, and deletions in logarithmic time. They are fundamental to database systems and file systems, providing efficient indexing for large datasets stored on disk.

### Key Concepts

1. **Self-Balancing Structure**: Automatic height balance through node splitting and merging
2. **Database Optimization**: Designed for systems with large block sizes (disk pages)
3. **Sorted Organization**: All keys maintained in sorted order within and across nodes
4. **Logarithmic Performance**: O(log n) for all primary operations
5. **Degree-Based Structure**: Node capacity determined by minimum degree parameter
6. **Democratic Access**: All leaf nodes at the same level (height balance)

## 🔧 Technical Implementation

### Core Algorithm Features

- **Configurable Degree**: Support for different B-Tree orders (t = 2, 3, 4, 5)
- **Node Splitting**: Automatic splitting when nodes exceed capacity
- **Node Merging**: Efficient deletion with rebalancing operations
- **Database Simulation**: Disk access patterns and page-based storage
- **Interactive Visualization**: 3D representation of tree structure and operations
- **Performance Analysis**: Real-time metrics for database optimization
- **Democratic Balance**: All paths from root to leaves have equal length

### B-Tree Structure Properties

#### Node Constraints
```
For minimum degree t:
- Maximum keys per node: 2t - 1
- Minimum keys per node: t - 1 (except root)
- Maximum children per node: 2t
- Minimum children per node: t (except leaves and root)
```

#### Height Properties
```
For n keys and minimum degree t:
- Minimum height: ⌈log_t((n+1)/2)⌉
- Maximum height: ⌊log_t(n+1)⌋
- All leaves at same level (perfectly balanced)
```

### Insertion Algorithm

#### Step 1: Navigate to Insertion Point
```gdscript
func insert_key(key):
    if root.is_full():
        create_new_root()
        split_child(root, 0)
    
    insert_non_full(root, key)
```

#### Step 2: Handle Full Nodes
```gdscript
func insert_non_full(node, key):
    if node.is_leaf:
        insert_into_leaf(node, key)
    else:
        child_index = find_child_position(key)
        if node.children[child_index].is_full():
            split_child(node, child_index)
            if key > node.keys[child_index]:
                child_index += 1
        insert_non_full(node.children[child_index], key)
```

#### Step 3: Node Splitting Process
```gdscript
func split_child(parent, child_index):
    full_child = parent.children[child_index]
    new_child = create_new_node()
    
    # Move second half of keys to new node
    median_index = degree - 1
    for i in range(degree - 1):
        new_child.keys[i] = full_child.keys[i + degree]
    
    # Move median key up to parent
    parent.insert_key_at(child_index, full_child.keys[median_index])
    parent.insert_child_at(child_index + 1, new_child)
    
    # Truncate original child
    full_child.truncate_at(median_index)
```

### Deletion Algorithm

#### Case 1: Deletion from Leaf Node
```gdscript
func delete_from_leaf(node, key_index):
    # Simple removal from leaf
    node.remove_key_at(key_index)
    
    # Check if underflow occurred
    if node.key_count < degree - 1 and node != root:
        handle_underflow(node)
```

#### Case 2: Deletion from Internal Node
```gdscript
func delete_from_internal(node, key_index):
    key = node.keys[key_index]
    
    if left_child.key_count >= degree:
        # Replace with predecessor
        predecessor = find_predecessor(node, key_index)
        node.keys[key_index] = predecessor
        delete_key(left_child, predecessor)
    elif right_child.key_count >= degree:
        # Replace with successor
        successor = find_successor(node, key_index)
        node.keys[key_index] = successor
        delete_key(right_child, successor)
    else:
        # Merge children and delete
        merge_children(node, key_index)
        delete_key(merged_child, key)
```

#### Case 3: Underflow Handling
```gdscript
func handle_underflow(node):
    if can_borrow_from_left_sibling(node):
        borrow_from_left(node)
    elif can_borrow_from_right_sibling(node):
        borrow_from_right(node)
    else:
        merge_with_sibling(node)
```

### Search Algorithm

#### Efficient Key Location
```gdscript
func search_key(key, node = root):
    disk_access_count += 1  # Simulate disk read
    
    # Binary search within node
    index = binary_search_in_node(node, key)
    
    if index < node.key_count and node.keys[index] == key:
        return node, index  # Key found
    
    if node.is_leaf:
        return null  # Key not found
    
    # Search in appropriate child
    return search_key(key, node.children[index])
```

## 🎮 Interactive Controls

### Basic Operations
- **I**: Insert random key into B-Tree
- **D**: Delete random key from B-Tree
- **S**: Search for random key (highlights path)
- **R**: Reset B-Tree to empty state
- **SPACE**: Start/stop automatic demo insertion

### Degree Configuration
- **1**: Set degree t=2 (Order 3 B-Tree)
- **2**: Set degree t=3 (Order 5 B-Tree)
- **3**: Set degree t=4 (Order 7 B-Tree)
- **4**: Set degree t=5 (Order 9 B-Tree)

### Visualization Controls
- **Node Spacing**: Horizontal distance between sibling nodes
- **Level Height**: Vertical distance between tree levels
- **Animation Speed**: Rate of node splitting and operation visualization
- **Key Display Mode**: Numbers, letters, or database records

## 📊 Visualization Features

### 3D Tree Structure
- **Node Representation**: Color-coded boxes showing key capacity utilization
- **Root Node**: Red highlighting for tree root identification
- **Internal Nodes**: Blue boxes representing branch nodes
- **Leaf Nodes**: Green boxes showing data storage nodes
- **Connection Lines**: Gray cylinders showing parent-child relationships

### Database Simulation
- **Disk Access Visualization**: Simulated page reads with timing
- **Cache Behavior**: Hit/miss ratios for memory optimization
- **Page Size Mapping**: Node capacity aligned with disk page sizes
- **Index Structure**: Visual representation of database indexing patterns

### Operation Animation
- **Node Splitting**: Step-by-step visualization of overflow handling
- **Search Path Highlighting**: Magenta coloring for search traversal
- **Insertion Animation**: Progressive key placement with rebalancing
- **Deletion Sequence**: Merge operations and underflow resolution

## 🏳️‍🌈 Information Democracy Framework

### Hierarchical Data Politics
B-Trees embody fundamental questions about information organization and democratic access:

- **Who controls the hierarchy?** Tree structure determines access patterns and query efficiency
- **What constitutes balanced access?** Height balance ensures equitable retrieval times
- **How is information democratized?** All leaves at same level provide fair access
- **What gets prioritized in the index?** Key ordering reflects value hierarchies in data systems

### Algorithmic Justice Questions
1. **Data Equity**: Does balanced tree structure serve all queries equally?
2. **Access Patterns**: How do node degrees affect different usage communities?
3. **Storage Democracy**: Are database resources distributed fairly across data types?
4. **Query Justice**: Do all searches receive logarithmic time regardless of content?

## 🔬 Educational Applications

### Database Systems Fundamentals
- **Index Structures**: Understanding B+ trees in database management systems
- **Storage Optimization**: Page-based access patterns and disk I/O efficiency
- **Query Processing**: How balanced trees enable efficient database operations
- **Transaction Management**: Concurrent access patterns in multi-user systems

### Data Structure Concepts
- **Self-Balancing**: Automatic maintenance of logarithmic height
- **Node Capacity**: Trade-offs between memory usage and disk access
- **Tree Traversal**: In-order traversal for sorted data retrieval
- **Split/Merge Operations**: Dynamic rebalancing under insertions and deletions

## 📈 Performance Characteristics

### Complexity Analysis

#### Time Complexity
| Operation | Average Case | Worst Case | Best Case |
|-----------|-------------|------------|-----------|
| Search    | O(log n)    | O(log n)   | O(1)      |
| Insert    | O(log n)    | O(log n)   | O(1)      |
| Delete    | O(log n)    | O(log n)   | O(1)      |
| Traverse  | O(n)        | O(n)       | O(n)      |

#### Space Complexity
- **Storage**: O(n) for n keys
- **Node Overhead**: O(number of nodes)
- **Tree Height**: O(log n) auxiliary space for operations

### Database Performance Metrics

#### Disk Access Optimization
```
For degree t and block size B:
- Keys per node: ≤ 2t - 1
- Pointers per node: ≤ 2t
- Optimal t: B / (key_size + pointer_size)
- Disk reads per search: ≤ log_t(n)
```

#### Cache Efficiency
- **Spatial Locality**: Keys within nodes stored contiguously
- **Temporal Locality**: Recently accessed nodes cached in memory
- **Buffer Pool Management**: LRU replacement for node caching
- **Page Fault Reduction**: Larger nodes reduce tree height

## 🎓 Learning Objectives

### Primary Goals
1. **Master self-balancing tree structures** and their maintenance algorithms
2. **Understand database indexing** principles and optimization strategies
3. **Analyze hierarchical data organization** and its social implications
4. **Explore information democracy** through balanced access structures

### Advanced Topics
- **B+ Trees**: Leaf-linked variants for range queries
- **B* Trees**: Higher space utilization through deferred splitting
- **Concurrent B-Trees**: Multi-threaded access with locking protocols
- **LSM Trees**: Log-structured merge trees for write-heavy workloads

## 🔍 Experimental Scenarios

### Recommended Explorations

1. **Degree Impact Analysis**
   - Compare performance across different tree degrees
   - Analyze space vs. time trade-offs
   - Study optimal degree for different workloads

2. **Insertion Pattern Effects**
   - Sequential vs. random insertion patterns
   - Impact of sorted data on tree structure
   - Bulk loading optimization strategies

3. **Database Simulation**
   - Model real database page sizes and access patterns
   - Analyze cache hit ratios and disk I/O optimization
   - Compare B-Tree variants for different use cases

4. **Democratic Access Analysis**
   - Study how tree structure affects query fairness
   - Analyze worst-case vs. average-case access patterns
   - Design equitable indexing strategies

## 🚀 Advanced Features

### Database Integration
- **Transaction Support**: ACID compliance with concurrent operations
- **Range Queries**: Efficient retrieval of key ranges
- **Bulk Operations**: Optimized batch insertions and deletions
- **Compression**: Node compression for storage efficiency

### Performance Enhancements
- **Lock-Free Operations**: Non-blocking concurrent algorithms
- **Adaptive Splitting**: Dynamic degree adjustment based on workload
- **Prefetching**: Predictive node loading for sequential access
- **Compression**: Key compression and delta encoding

### Visualization Extensions
- **Query Plan Visualization**: Show database query execution paths
- **Performance Profiling**: Real-time analysis of operation costs
- **Memory Layout**: Detailed view of node storage organization
- **Historical Analysis**: Tree evolution over time

## 🎯 Critical Questions for Reflection

1. **How do hierarchical data structures reflect and reinforce social hierarchies?**
2. **What are the democratic implications of balanced vs. unbalanced tree access?**
3. **When might optimization for database efficiency conflict with equitable access?**
4. **How do indexing choices affect information discoverability and representation?**

## 📚 Further Reading

### Foundational Papers
- Bayer, R., & McCreight, E. (1972). Organization and Maintenance of Large Ordered Indices
- Comer, D. (1979). The Ubiquitous B-Tree
- Knuth, D. E. (1998). The Art of Computer Programming, Volume 3: Sorting and Searching

### Database Literature
- Garcia-Molina, H., Ullman, J. D., & Widom, J. (2008). Database Systems: The Complete Book
- Ramakrishnan, R., & Gehrke, J. (2003). Database Management Systems
- Elmasri, R., & Navathe, S. B. (2015). Fundamentals of Database Systems

### Critical Data Studies
- Gitelman, L. (2013). "Raw Data" Is an Oxymoron
- Bowker, G. C., & Star, S. L. (2000). Sorting Things Out: Classification and Its Consequences
- Noble, S. U. (2018). Algorithms of Oppression: How Search Engines Reinforce Racism

## 🔧 Technical Implementation Details

### Node Structure Design
```gdscript
class BTreeNode:
    var keys: Array          # Sorted array of keys
    var children: Array      # Array of child node references
    var is_leaf: bool        # Leaf node indicator
    var parent: BTreeNode    # Parent node reference
    var key_count: int       # Current number of keys
    var child_count: int     # Current number of children
    
    func is_full(degree: int) -> bool:
        return key_count >= (2 * degree - 1)
    
    func is_minimal(degree: int) -> bool:
        return key_count < (degree - 1)
```

### Splitting Algorithm
```gdscript
func split_child(parent: BTreeNode, child_index: int):
    var full_child = parent.children[child_index]
    var new_node = BTreeNode.new(tree_degree)
    var median_index = tree_degree - 1
    
    # Copy second half of keys to new node
    for i in range(tree_degree - 1):
        new_node.keys[i] = full_child.keys[i + tree_degree]
        full_child.keys[i + tree_degree] = null
    
    # Copy children if internal node
    if not full_child.is_leaf:
        for i in range(tree_degree):
            new_node.children[i] = full_child.children[i + tree_degree]
            full_child.children[i + tree_degree] = null
    
    # Promote median key to parent
    parent.insert_key_and_child(child_index, 
                               full_child.keys[median_index], 
                               new_node)
    
    # Update counts
    full_child.key_count = tree_degree - 1
    new_node.key_count = tree_degree - 1
```

### Search Optimization
```gdscript
func search_in_node(node: BTreeNode, key: int) -> int:
    # Binary search within node for efficiency
    var left = 0
    var right = node.key_count - 1
    
    while left <= right:
        var mid = (left + right) / 2
        if node.keys[mid] == key:
            return mid
        elif node.keys[mid] < key:
            left = mid + 1
        else:
            right = mid - 1
    
    return left  # Insertion position
```

## 📊 Performance Metrics

### Database Efficiency Analysis
- **Disk Access Count**: Total page reads during operations
- **Cache Hit Ratio**: Percentage of operations served from memory
- **Tree Height**: Current and optimal height comparison
- **Node Utilization**: Average percentage of node capacity used
- **Split Frequency**: Rate of node splitting operations

### Scalability Characteristics
- **Linear Growth**: Storage requirements scale linearly with data size
- **Logarithmic Access**: Search time grows logarithmically
- **Degree Impact**: Higher degrees reduce height but increase node search time
- **Memory Trade-offs**: Larger nodes vs. more frequent disk access

### Real-World Application Metrics
- **MySQL InnoDB**: Uses B+ Trees with degree typically 100-200
- **PostgreSQL**: B-Tree indexes with optimized node sizes
- **SQLite**: B+ Trees optimized for embedded systems
- **MongoDB**: B-Tree indexes with document-oriented optimization

---

**Status**: ✅ Complete - Production Ready  
**Complexity**: Advanced Data Structures  
**Prerequisites**: Tree Structures, Database Concepts, Complexity Analysis  
**Estimated Learning Time**: 4-6 hours for basic concepts, 15+ hours for database mastery 