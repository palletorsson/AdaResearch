extends Node2D

# AlgorithmPeriodicTable.gd
# Creates a periodic table-style visualization of algorithms
# For Ada Research project

# Style constants
const CELL_WIDTH = 120
const CELL_HEIGHT = 120
const CELL_MARGIN = 10
const FONT_SIZE_SYMBOL = 24
const FONT_SIZE_NAME = 14
const FONT_SIZE_CATEGORY = 10
const FONT_SIZE_TITLE = 32

# Grid layout
const GRID_COLUMNS = 10
const GRID_ROWS = 8

# Category colors
const CATEGORY_COLORS = {
	"Sorting": Color(0.95, 0.3, 0.3),  # Red
	"Searching": Color(0.3, 0.5, 0.95),  # Blue
	"Graph": Color(0.3, 0.95, 0.5),  # Green
	"Dynamic": Color(0.95, 0.5, 0.95),  # Purple
	"Divide": Color(0.95, 0.95, 0.3),  # Yellow
	"Greedy": Color(0.95, 0.6, 0.3),  # Orange
	"Probabilistic": Color(0.7, 0.3, 0.95),  # Violet
	"String": Color(0.3, 0.95, 0.95),  # Cyan
	"Numerical": Color(0.6, 0.8, 0.6),  # Light Green
	"Hashing": Color(0.95, 0.8, 0.6),  # Light Orange
	"Cryptography": Color(0.6, 0.6, 0.6),  # Gray
	"Compression": Color(0.8, 0.6, 0.95),  # Lavender
	"Data Structure": Color(0.7, 0.7, 0.8),  # Gray Blue
	"Machine Learning": Color(0.8, 0.5, 0.7),  # Mauve
	"Optimization": Color(0.5, 0.8, 0.7)  # Teal
}

# Algorithm data structure
# Format: [Shorthand, Name, Category, "Row,Column", Complexity]
const ALGORITHMS = [
	# Row 1
	["BS", "Binary Search", "Searching", "1,1", "O(log n)"],
	["QS", "Quick Sort", "Sorting", "1,2", "O(n log n)"],
	["MS", "Merge Sort", "Sorting", "1,3", "O(n log n)"],
	["HS", "Heap Sort", "Sorting", "1,4", "O(n log n)"],
	["BFS", "Breadth-First Search", "Graph", "1,5", "O(V+E)"],
	["DFS", "Depth-First Search", "Graph", "1,6", "O(V+E)"],
	["DIJ", "Dijkstra", "Graph", "1,7", "O(E log V)"],
	["BM", "Boyer-Moore", "String", "1,8", "O(n+m)"],
	["KMP", "Knuth-Morris-Pratt", "String", "1,9", "O(n+m)"],
	["RK", "Rabin-Karp", "String", "1,10", "O(nm)"],
	
	# Row 2
	["FF", "Ford-Fulkerson", "Graph", "2,1", "O(VE²)"],
	["BF", "Bellman-Ford", "Graph", "2,2", "O(VE)"],
	["FW", "Floyd-Warshall", "Graph", "2,3", "O(V³)"],
	["PR", "PageRank", "Graph", "2,4", "O(V+E)"],
	["KR", "Kruskal", "Graph", "2,5", "O(E log V)"],
	["PM", "Prim", "Graph", "2,6", "O(E log V)"],
	["TSP", "Traveling Salesman", "Dynamic", "2,7", "O(n²2ⁿ)"],
	["KS", "Knapsack", "Dynamic", "2,8", "O(nW)"],
	["ED", "Edit Distance", "Dynamic", "2,9", "O(nm)"],
	["LCS", "Longest Common Subsequence", "Dynamic", "2,10", "O(nm)"],
	
	# Row 3
	["DP", "Dynamic Programming", "Dynamic", "3,1", "Varies"],
	["FB", "Fibonacci", "Dynamic", "3,2", "O(n)"],
	["DC", "Divide & Conquer", "Divide", "3,3", "Varies"],
	["BT", "Backtracking", "Divide", "3,4", "Varies"],
	["GR", "Greedy", "Greedy", "3,5", "Varies"],
	["HC", "Hill Climbing", "Greedy", "3,6", "Varies"],
	["SA", "Simulated Annealing", "Probabilistic", "3,7", "Varies"],
	["GA", "Genetic Algorithm", "Probabilistic", "3,8", "Varies"],
	["MC", "Monte Carlo", "Probabilistic", "3,9", "Varies"],
	["NN", "Neural Network", "Probabilistic", "3,10", "Varies"],
	
	# Row 4
	["FFT", "Fast Fourier Transform", "Numerical", "4,1", "O(n log n)"],
	["NR", "Newton-Raphson", "Numerical", "4,2", "O(log n)"],
	["MM", "Matrix Multiplication", "Numerical", "4,3", "O(n³)"],
	["GE", "Gaussian Elimination", "Numerical", "4,4", "O(n³)"],
	["IS", "Insertion Sort", "Sorting", "4,5", "O(n²)"],
	["SS", "Selection Sort", "Sorting", "4,6", "O(n²)"],
	["BS", "Bubble Sort", "Sorting", "4,7", "O(n²)"],
	["CS", "Counting Sort", "Sorting", "4,8", "O(n+k)"],
	["RS", "Radix Sort", "Sorting", "4,9", "O(nk)"],
	["HS", "Hash Table", "Hashing", "4,10", "O(1) avg"],
	
	# Row 5
	["BH", "Bloom Filter", "Hashing", "5,1", "O(k)"],
	["CH", "Consistent Hashing", "Hashing", "5,2", "O(1)"],
	["LC", "Linear Congruential", "Hashing", "5,3", "O(1)"],
	["MD5", "MD5", "Cryptography", "5,4", "O(n)"],
	["SHA", "SHA-256", "Cryptography", "5,5", "O(n)"],
	["RSA", "RSA", "Cryptography", "5,6", "Varies"],
	["AES", "AES", "Cryptography", "5,7", "O(n)"],
	["DES", "DES", "Cryptography", "5,8", "O(n)"],
	["HUF", "Huffman Coding", "Compression", "5,9", "O(n log n)"],
	["LZ", "Lempel-Ziv", "Compression", "5,10", "O(n)"],
	
	# Row 6
	["RLE", "Run-Length Encoding", "Compression", "6,1", "O(n)"],
	["DCT", "Discrete Cosine Transform", "Compression", "6,2", "O(n log n)"],
	["PQ", "Priority Queue", "Data Structure", "6,3", "O(log n)"],
	["ST", "Segment Tree", "Data Structure", "6,4", "O(log n)"],
	["BIT", "Binary Indexed Tree", "Data Structure", "6,5", "O(log n)"],
	["SL", "Skip List", "Data Structure", "6,6", "O(log n)"],
	["TR", "Trie", "Data Structure", "6,7", "O(key_length)"],
	["UF", "Union Find", "Data Structure", "6,8", "O(α(n))"],
	["RQ", "Range Query", "Data Structure", "6,9", "O(log n)"],
	["BT", "B-Tree", "Data Structure", "6,10", "O(log n)"],
	
	# Row 7
	["PN", "Perlin Noise", "Numerical", "7,1", "O(2ᵈ)"],
	["SP", "Simplex", "Numerical", "7,2", "Exponential"],
	["MCF", "Min-Cost Flow", "Graph", "7,3", "Polynomial"],
	["LSH", "Locality-Sensitive Hashing", "Hashing", "7,4", "Varies"],
	["SVM", "Support Vector Machine", "Machine Learning", "7,5", "O(n²)"],
	["KM", "K-Means", "Machine Learning", "7,6", "O(nkt)"],
	["DT", "Decision Tree", "Machine Learning", "7,7", "O(n²m)"],
	["RF", "Random Forest", "Machine Learning", "7,8", "O(n²m√m)"],
	["NB", "Naive Bayes", "Machine Learning", "7,9", "O(nm)"],
	["KNN", "K-Nearest Neighbors", "Machine Learning", "7,10", "O(nd)"],
	
	# Row 8
	["A*", "A* Search", "Graph", "8,1", "Exponential"],
	["IDA", "IDA* Search", "Graph", "8,2", "Exponential"],
	["PS", "Particle Swarm", "Optimization", "8,3", "Varies"],
	["ACO", "Ant Colony Optimization", "Optimization", "8,4", "Varies"],
	["PCA", "Principal Component Analysis", "Machine Learning", "8,5", "O(np²)"],
	["EM", "Expectation-Maximization", "Machine Learning", "8,6", "Varies"],
	["RNN", "Recurrent Neural Network", "Machine Learning", "8,7", "Varies"],
	["CNN", "Convolutional Neural Network", "Machine Learning", "8,8", "Varies"],
	["LSTM", "Long Short-Term Memory", "Machine Learning", "8,9", "Varies"],
	["GAN", "Generative Adversarial Network", "Machine Learning", "8,10", "Varies"]
]

# Algorithm card class to represent each element
class AlgorithmCard:
	var shorthand: String
	var name: String
	var category: String
	var row: int
	var column: int
	var complexity: String
	var position: Vector2
	var size: Vector2
	var color: Color
	
	func _init(data: Array):
		shorthand = data[0]
		name = data[1]
		category = data[2]
		
		var grid_pos = data[3].split(",")
		row = int(grid_pos[0])
		column = int(grid_pos[1])
		
		complexity = data[4]
		size = Vector2(CELL_WIDTH, CELL_HEIGHT)
		color = CATEGORY_COLORS.get(category, Color(0.8, 0.8, 0.8))
		
		# Calculate position based on grid coordinates
		position = Vector2(
			(column - 1) * (CELL_WIDTH + CELL_MARGIN) + CELL_MARGIN,
			(row - 1) * (CELL_HEIGHT + CELL_MARGIN) + CELL_MARGIN + 100  # Top margin for title and key
		)

# Store algorithm cards
var algorithm_cards = []

# Current selected algorithm
var selected_algorithm = null

# Font for drawing text
var font: Font
var font_bold: Font

# Called when the node enters the scene tree for the first time
func _ready():
	# Create fonts
	font = SystemFont.new()
	font_bold = SystemFont.new()
	#font_bold.font_weight = SystemFont.WEIGHT_BOLD
	
	# Create algorithm cards
	for algorithm_data in ALGORITHMS:
		algorithm_cards.append(AlgorithmCard.new(algorithm_data))
	
	# Create UI elements
	create_ui()
	
	# Set up window size
	var window_width = GRID_COLUMNS * (CELL_WIDTH + CELL_MARGIN) + CELL_MARGIN
	var window_height = GRID_ROWS * (CELL_HEIGHT + CELL_MARGIN) + CELL_MARGIN + 350  # Extra space for info panel
	get_viewport().size = Vector2(window_width, window_height)
	
	# Make the canvas semi-responsive
	get_tree().root.size_changed.connect(_on_window_resize)

func _on_window_resize():
	queue_redraw()

# Create user interface elements
func create_ui():
	# Create main title
	var title_label = Label.new()
	title_label.text = "The Periodic Table of Algorithms"
	title_label.add_theme_font_override("font", font_bold)
	title_label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	title_label.position = Vector2(20, 20)
	add_child(title_label)
	
	# Create category legend
	var legend_container = HBoxContainer.new()
	legend_container.position = Vector2(20, 60)
	add_child(legend_container)
	
	var category_x = 0
	var row_count = 1
	var legend_vbox = VBoxContainer.new()
	legend_vbox.name = "Row1"
	legend_container.add_child(legend_vbox)
	
	for category in CATEGORY_COLORS:
		# Create a new row after 4 categories
		if category_x >= 4:
			category_x = 0
			row_count += 1
			legend_vbox = VBoxContainer.new()
			legend_vbox.name = "Row" + str(row_count)
			legend_container.add_child(legend_vbox)
		
		var legend_item = HBoxContainer.new()
		
		var color_rect = ColorRect.new()
		color_rect.color = CATEGORY_COLORS[category]
		color_rect.custom_minimum_size = Vector2(20, 20)
		legend_item.add_child(color_rect)
		
		var category_label = Label.new()
		category_label.text = " " + category
		legend_item.add_child(category_label)
		
		legend_vbox.add_child(legend_item)
		category_x += 1
	
	# Create search bar
	var search_container = HBoxContainer.new()
	search_container.position = Vector2(GRID_COLUMNS * (CELL_WIDTH + CELL_MARGIN) - 300, 30)
	add_child(search_container)
	
	var search_label = Label.new()
	search_label.text = "Search: "
	search_container.add_child(search_label)
	
	var search_edit = LineEdit.new()
	search_edit.placeholder_text = "Enter algorithm name"
	search_edit.custom_minimum_size = Vector2(200, 30)
	search_edit.text_changed.connect(_on_search_text_changed)
	search_container.add_child(search_edit)

# Handle search text changes
func _on_search_text_changed(new_text: String):
	queue_redraw()
	if new_text.strip_edges() == "":
		# Show all algorithms
		for card in algorithm_cards:
			card.visible = true
		return
	
	# Filter algorithms by search text
	new_text = new_text.to_lower()
	for card in algorithm_cards:
		card.visible = (card.name.to_lower().contains(new_text) or 
						card.shorthand.to_lower().contains(new_text) or
						card.category.to_lower().contains(new_text))

# Handle mouse input
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_pos = event.position
		
		# Check if an algorithm card was clicked
		selected_algorithm = null
		for card in algorithm_cards:
			var rect = Rect2(card.position, card.size)
			if rect.has_point(clicked_pos):
				selected_algorithm = card
				break
		
		# Redraw the scene
		queue_redraw()

# Draw the periodic table
func _draw():
	# Draw each algorithm card
	for card in algorithm_cards:
		# Draw card background
		draw_rect(Rect2(card.position, card.size), card.color)
		
		# Highlight selected card
		if selected_algorithm == card:
			draw_rect(Rect2(card.position, card.size), Color(1, 1, 1, 0.3), false, 4.0)
		else:
			draw_rect(Rect2(card.position, card.size), Color(0, 0, 0, 0.3), false, 1.0)
		
		# Draw shorthand (symbol)
		var symbol_size = FONT_SIZE_SYMBOL
		var shorthand_width = font_bold.get_string_size(card.shorthand, HORIZONTAL_ALIGNMENT_CENTER, -1, symbol_size).x
		draw_string(font_bold, 
			card.position + Vector2(card.size.x/2 - shorthand_width/2, card.size.y/2), 
			card.shorthand, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			symbol_size)
		
		# Draw algorithm name
		var name_size = FONT_SIZE_NAME
		var name_width = font.get_string_size(card.name, HORIZONTAL_ALIGNMENT_CENTER, -1, name_size).x
		draw_string(font, 
			card.position + Vector2(card.size.x/2 - name_width/2, card.size.y/2 + 30), 
			card.name, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			name_size)
		
		# Draw complexity
		var complexity_size = FONT_SIZE_CATEGORY
		var complexity_width = font.get_string_size(card.complexity, HORIZONTAL_ALIGNMENT_CENTER, -1, complexity_size).x
		draw_string(font, 
			card.position + Vector2(card.size.x/2 - complexity_width/2, card.size.y - 15), 
			card.complexity, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			-1, 
			complexity_size)
	
	# Draw detailed information for selected algorithm
	if selected_algorithm:
		var info_panel = $InfoContainer/ColorRect
		
		# Clear previous info
		for child in info_panel.get_children():
			if child.name != "Label":
				child.queue_free()
		
		# Update info title
		$InfoContainer/ColorRect/Label.text = selected_algorithm.name + " (" + selected_algorithm.shorthand + ")"
		
		# Create info text
		var info_text = Label.new()
		info_text.text = "Category: " + selected_algorithm.category + "\n" + \
						"Time Complexity: " + selected_algorithm.complexity + "\n\n" + \
						get_algorithm_description(selected_algorithm.shorthand)
		info_text.position = Vector2(20, 60)
		info_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_text.size.x = info_panel.size.x - 40
		info_panel.add_child(info_text)

# Get algorithm description (simplified for brevity)
func get_algorithm_description(shorthand: String) -> String:
	match shorthand:
		"BS":
			return "Binary Search: A divide and conquer search algorithm that works on sorted arrays by repeatedly dividing the search interval in half."
		"QS":
			return "Quick Sort: A divide and conquer sorting algorithm that picks an element as pivot and partitions the array around the pivot."
		"MS":
			return "Merge Sort: A divide and conquer sorting algorithm that divides the input array into two halves, sorts them, and then merges the sorted halves."
		"BFS":
			return "Breadth-First Search: A graph traversal algorithm that explores all neighbors at the present depth before moving to nodes at the next depth level."
		"DFS":
			return "Depth-First Search: A graph traversal algorithm that explores as far as possible along each branch before backtracking."
		"DIJ":
			return "Dijkstra's Algorithm: An algorithm for finding the shortest paths between nodes in a graph with non-negative edge weights."
		"DP":
			return "Dynamic Programming: A method for solving complex problems by breaking them down into simpler subproblems and storing their solutions to avoid redundant calculations."
		"A*":
			return "A* Search: A best-first search algorithm that finds the least-cost path from a start node to a goal node using a heuristic function."
		"NN":
			return "Neural Network: A computational model inspired by the structure and functions of biological neural networks, used for pattern recognition and machine learning."
		"FFT":
			return "Fast Fourier Transform: An algorithm to compute the discrete Fourier transform (DFT) and its inverse, converting time to frequency domain and vice versa."
		"GAN":
			return "Generative Adversarial Network: A class of machine learning frameworks where two neural networks contest with each other in a game, one generating candidates and the other evaluating them."
		"PN":
			return "Perlin Noise: A gradient noise algorithm used in computer graphics to generate procedural textures, natural-looking terrain, and other visual elements."
		"SHA":
			return "SHA-256: A cryptographic hash function that generates a fixed-size 256-bit (32-byte) hash. It's one of the successor hash functions to SHA-1 and is part of the SHA-2 family."
		"RSA":
			return "RSA (Rivest–Shamir–Adleman): A public-key cryptosystem widely used for secure data transmission. The security of RSA relies on the practical difficulty of factoring the product of two large prime numbers."
		"KM":
			return "K-Means: A clustering algorithm that partitions n observations into k clusters, with each observation belonging to the cluster with the nearest mean."
		"HUF":
			return "Huffman Coding: A lossless data compression algorithm that uses a variable-length code table for encoding source symbols, where the variable-length code table is derived from the estimated probability of occurrence for each source symbol."
		"LZ":
			return "Lempel-Ziv: A universal lossless data compression algorithm that forms the basis for many compression formats including ZIP, GIF, and PNG. It identifies and eliminates statistical redundancy."
		"CNN":
			return "Convolutional Neural Network: A class of deep neural networks most commonly applied to analyzing visual imagery. CNNs use a mathematical operation called convolution specialized for processing grid-like data."
		"RNN":
			return "Recurrent Neural Network: A class of neural networks where connections between nodes form a directed graph along a temporal sequence, allowing it to exhibit temporal dynamic behavior for time sequence data."
		"LSTM":
			return "Long Short-Term Memory: A special kind of RNN capable of learning long-term dependencies, particularly useful for classification, processing, and prediction based on time series data."
		_:
			return "A fundamental algorithm in computer science and mathematics with applications in various fields."

# Add UI for algorithm explanations
func add_explanation_ui():
	var explanation_panel = PanelContainer.new()
	explanation_panel.name = "ExplanationPanel"
	explanation_panel.visible = false
	add_child(explanation_panel)
	
	var vbox = VBoxContainer.new()
	explanation_panel.add_child(vbox)
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_bold)
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var description = RichTextLabel.new()
	description.name = "DescriptionLabel"
	description.fit_content = true
	description.custom_minimum_size = Vector2(600, 300)
	vbox.add_child(description)
	
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): explanation_panel.visible = false)
	vbox.add_child(close_button)

# Export as PNG function
func _on_export_button_pressed():
	# Get the viewport texture
	var viewport_texture = get_viewport().get_texture()
	
	# Create an image from the viewport texture
	var image = viewport_texture.get_image()
	
	# Save the image to a file
	var date_time = Time.get_datetime_string_from_system().replace(":", "-")
	var filepath = "user://algorithm_table_" + date_time + ".png"
	image.save_png(filepath)
	
	# Create a notification
	var notification = Label.new()
	notification.text = "Exported to " + filepath
	notification.position = Vector2(600, 30)
	notification.modulate = Color(1, 1, 1, 1)
	add_child(notification)
	
	# Fade out and remove notification
	var tween = create_tween()
	tween.tween_property(notification, "modulate", Color(1, 1, 1, 0), 2.0)
	tween.tween_callback(notification.queue_free)
