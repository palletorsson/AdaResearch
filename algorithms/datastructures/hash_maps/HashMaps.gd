extends Node3D

var time = 0.0
var bucket_count = 8
var buckets = []
var operation_timer = 0.0
var operation_interval = 2.5
var total_elements = 0
var collision_count = 0

# Hash map operations
enum HashOperation {
	INSERT,
	SEARCH,
	DELETE,
	REHASH,
	COLLISION_DEMO
}

var current_operation = HashOperation.INSERT

# Bucket class to represent hash table buckets
class HashBucket:
	var index: int
	var visual_container: CSGBox3D
	var elements: Array = []
	var chain_visuals: Array = []
	
	func _init(bucket_index: int):
		index = bucket_index

# Key-value pair class
class KeyValuePair:
	var key: String
	var value: int
	var visual_object: CSGSphere3D
	var hash_value: int
	
	func _init(k: String, v: int):
		key = k
		value = v

func _ready():
	setup_hash_buckets()
	setup_materials()
	insert_initial_data()

func setup_hash_buckets():
	var bucket_parent = $HashBuckets
	
	for i in range(bucket_count):
		var bucket = HashBucket.new(i)
		
		# Create visual container for bucket
		var container = CSGBox3D.new()
		container.size = Vector3(1.2, 0.3, 1.2)
		container.position = Vector3(
			-6 + i * 1.8,
			0,
			0
		)
		
		bucket_parent.add_child(container)
		bucket.visual_container = container
		buckets.append(bucket)

func setup_materials():
	# Bucket materials
	var bucket_material = StandardMaterial3D.new()
	bucket_material.albedo_color = Color(0.3, 0.3, 0.8, 0.7)
	bucket_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bucket_material.emission_enabled = true
	bucket_material.emission = Color(0.1, 0.1, 0.3, 1.0)
	
	for bucket in buckets:
		bucket.visual_container.material_override = bucket_material
	
	# Hash function material
	var hash_func_material = StandardMaterial3D.new()
	hash_func_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	hash_func_material.emission_enabled = true
	hash_func_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$HashFunction.material_override = hash_func_material
	
	# Load factor indicator material
	var load_material = StandardMaterial3D.new()
	load_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	load_material.emission_enabled = true
	load_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$LoadFactorIndicator.material_override = load_material
	
	# Collision indicator material
	var collision_material = StandardMaterial3D.new()
	collision_material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
	collision_material.emission_enabled = true
	collision_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$CollisionIndicator.material_override = collision_material

func insert_initial_data():
	# Insert some initial key-value pairs
	var initial_keys = ["apple", "banana", "cherry", "date", "elderberry"]
	for i in range(initial_keys.size()):
		insert_key_value(initial_keys[i], i * 10 + randi() % 50)

func _process(delta):
	time += delta
	operation_timer += delta
	
	if operation_timer >= operation_interval:
		operation_timer = 0.0
		perform_operation()
	
	animate_hash_map()
	animate_indicators()

func perform_operation():
	current_operation = (current_operation + 1) % HashOperation.size()
	
	match current_operation:
		HashOperation.INSERT:
			var keys = ["grape", "kiwi", "lemon", "mango", "orange", "peach", "plum"]
			var random_key = keys[randi() % keys.size()] + str(randi() % 100)
			var random_value = randi() % 1000
			insert_key_value(random_key, random_value)
		
		HashOperation.SEARCH:
			if total_elements > 0:
				animate_search_operation()
		
		HashOperation.DELETE:
			if total_elements > 2:
				delete_random_element()
		
		HashOperation.REHASH:
			if get_load_factor() > 0.75:
				rehash_table()
		
		HashOperation.COLLISION_DEMO:
			demonstrate_collision()

func hash_function(key: String) -> int:
	# Simple hash function (djb2 algorithm modified)
	var hash_val = 5381
	for i in range(key.length()):
		hash_val = ((hash_val << 5) + hash_val) + key.unicode_at(i)
	return abs(hash_val) % bucket_count

func insert_key_value(key: String, value: int):
	var pair = KeyValuePair.new(key, value)
	pair.hash_value = hash_function(key)
	
	var bucket = buckets[pair.hash_value]
	
	# Check for collision
	if bucket.elements.size() > 0:
		collision_count += 1
	
	bucket.elements.append(pair)
	create_visual_element(pair, bucket)
	total_elements += 1
	
	update_bucket_display(bucket)

func create_visual_element(pair: KeyValuePair, bucket: HashBucket):
	var sphere = CSGSphere3D.new()
	sphere.radius = 0.15
	
	# Position in bucket with chaining offset
	var chain_position = bucket.elements.size() - 1
	sphere.position = Vector3(
		bucket.visual_container.position.x,
		bucket.visual_container.position.y + 0.5 + chain_position * 0.4,
		bucket.visual_container.position.z
	)
	
	# Material based on hash value
	var element_material = StandardMaterial3D.new()
	var color_intensity = (pair.hash_value % bucket_count) / float(bucket_count)
	element_material.albedo_color = Color(
		0.8 + color_intensity * 0.2,
		0.3 + (1.0 - color_intensity) * 0.7,
		0.3 + color_intensity * 0.4,
		1.0
	)
	element_material.emission_enabled = true
	element_material.emission = element_material.albedo_color * 0.4
	sphere.material_override = element_material
	
	$HashBuckets.add_child(sphere)
	pair.visual_object = sphere
	
	# Create chain connection if this is not the first element
	if bucket.elements.size() > 1:
		create_chain_connection(bucket, chain_position)

func create_chain_connection(bucket: HashBucket, position: int):
	if position == 0:
		return
	
	var chain_link = CSGCylinder3D.new()
	chain_link.height = 0.3
	chain_link.top_radius = 0.03
	chain_link.bottom_radius = 0.03
	
	chain_link.position = Vector3(
		bucket.visual_container.position.x,
		bucket.visual_container.position.y + 0.5 + (position - 0.5) * 0.4,
		bucket.visual_container.position.z
	)
	
	# Chain material
	var chain_material = StandardMaterial3D.new()
	chain_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	chain_material.emission_enabled = true
	chain_material.emission = Color(0.2, 0.2, 0.05, 1.0)
	chain_link.material_override = chain_material
	
	$CollisionChains.add_child(chain_link)
	bucket.chain_visuals.append(chain_link)

func update_bucket_display(bucket: HashBucket):
	# Update bucket color based on load
	var load = bucket.elements.size()
	var material = bucket.visual_container.material_override as StandardMaterial3D
	
	if material:
		if load == 0:
			material.albedo_color = Color(0.3, 0.3, 0.8, 0.5)
		elif load == 1:
			material.albedo_color = Color(0.3, 0.8, 0.3, 0.7)
		else:
			# Multiple elements (collision)
			material.albedo_color = Color(0.8, 0.3, 0.3, 0.9)
		
		material.emission = material.albedo_color * 0.3

func animate_search_operation():
	# Animate searching through a random bucket
	pass

func delete_random_element():
	# Find a non-empty bucket and remove an element
	var non_empty_buckets = []
	for bucket in buckets:
		if bucket.elements.size() > 0:
			non_empty_buckets.append(bucket)
	
	if non_empty_buckets.size() > 0:
		var bucket = non_empty_buckets[randi() % non_empty_buckets.size()]
		var element_to_remove = bucket.elements[-1]
		
		element_to_remove.visual_object.queue_free()
		bucket.elements.pop_back()
		total_elements -= 1
		
		# Remove chain connection if exists
		if bucket.chain_visuals.size() > 0:
			bucket.chain_visuals[-1].queue_free()
			bucket.chain_visuals.pop_back()
		
		update_bucket_display(bucket)

func rehash_table():
	# Simple rehashing - double the bucket count
	var old_elements = []
	
	# Collect all elements
	for bucket in buckets:
		for element in bucket.elements:
			old_elements.append(element)
		bucket.elements.clear()
		bucket.visual_container.queue_free()
		for chain in bucket.chain_visuals:
			chain.queue_free()
		bucket.chain_visuals.clear()
	
	# Clear existing buckets
	buckets.clear()
	
	# Remove all visual objects
	for child in $HashBuckets.get_children():
		child.queue_free()
	for child in $CollisionChains.get_children():
		child.queue_free()
	
	# Double bucket count
	bucket_count = min(bucket_count * 2, 16)  # Cap at 16 buckets
	
	# Recreate buckets
	setup_hash_buckets()
	var bucket_material = StandardMaterial3D.new()
	bucket_material.albedo_color = Color(0.3, 0.3, 0.8, 0.7)
	bucket_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bucket_material.emission_enabled = true
	bucket_material.emission = Color(0.1, 0.1, 0.3, 1.0)
	
	for bucket in buckets:
		bucket.visual_container.material_override = bucket_material
	
	# Reinsert all elements
	total_elements = 0
	collision_count = 0
	for element in old_elements:
		element.visual_object.queue_free()
		insert_key_value(element.key, element.value)

func demonstrate_collision():
	# Intentionally create collisions by inserting keys that hash to the same bucket
	var target_bucket = randi() % bucket_count
	
	# Create keys that will hash to the target bucket
	for i in range(3):
		var collision_key = "collision_" + str(target_bucket) + "_" + str(i)
		# Adjust the key until it hashes to target bucket
		while hash_function(collision_key) != target_bucket:
			collision_key += "x"
		
		insert_key_value(collision_key, randi() % 100)

func get_load_factor() -> float:
	return float(total_elements) / float(bucket_count)

func animate_hash_map():
	# Animate hash function
	var hash_pulse = 1.0 + sin(time * 4.0) * 0.2
	$HashFunction.scale = Vector3.ONE * hash_pulse
	
	# Animate elements based on current operation
	match current_operation:
		HashOperation.INSERT:
			animate_insertion_highlighting()
		
		HashOperation.SEARCH:
			animate_search_highlighting()
		
		HashOperation.DELETE:
			animate_deletion_highlighting()
		
		HashOperation.COLLISION_DEMO:
			animate_collision_highlighting()
	
	# General pulsing for chain connections
	for bucket in buckets:
		for i in range(bucket.chain_visuals.size()):
			var chain = bucket.chain_visuals[i]
			var pulse = 1.0 + sin(time * 3.0 + i) * 0.3
			chain.scale = Vector3(pulse, 1.0, pulse)

func animate_insertion_highlighting():
	# Pulse newly inserted elements
	for bucket in buckets:
		for element in bucket.elements:
			var pulse = 1.0 + sin(time * 6.0 + element.hash_value) * 0.3
			element.visual_object.scale = Vector3.ONE * pulse

func animate_search_highlighting():
	# Create search wave effect
	var wave_position = fmod(time * 2.0, bucket_count)
	
	for i in range(buckets.size()):
		var bucket = buckets[i]
		var distance_from_wave = abs(i - wave_position)
		var intensity = max(0.0, 1.0 - distance_from_wave)
		
		for element in bucket.elements:
			var scale = 1.0 + intensity * 0.5
			element.visual_object.scale = Vector3.ONE * scale

func animate_deletion_highlighting():
	# Red pulsing for deletion mode
	for bucket in buckets:
		for element in bucket.elements:
			var pulse = 1.0 + sin(time * 8.0 + element.hash_value) * 0.2
			element.visual_object.scale = Vector3.ONE * pulse

func animate_collision_highlighting():
	# Highlight buckets with collisions
	for bucket in buckets:
		if bucket.elements.size() > 1:
			var pulse = 1.0 + sin(time * 10.0 + bucket.index) * 0.4
			bucket.visual_container.scale = Vector3.ONE * pulse
			
			for element in bucket.elements:
				element.visual_object.scale = Vector3.ONE * pulse

func animate_indicators():
	# Load factor indicator
	var load_factor = get_load_factor()
	var load_height = load_factor * 3.0 + 0.5
	$LoadFactorIndicator.size.y = load_height
	$LoadFactorIndicator.position.y = -3 + load_height/2
	
	# Collision indicator
	var collision_ratio = min(1.0, collision_count / 5.0)
	var collision_scale = 1.0 + collision_ratio * 2.0
	$CollisionIndicator.scale = Vector3.ONE * collision_scale
	
	# Color change based on collisions
	var collision_material = $CollisionIndicator.material_override as StandardMaterial3D
	if collision_material:
		collision_material.albedo_color = Color(1.0, 1.0 - collision_ratio, 1.0 - collision_ratio, 1.0)
		collision_material.emission = collision_material.albedo_color * 0.5
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	$LoadFactorIndicator.scale.x = pulse
	
	# Hash function animation
	var hash_rotation = time * 45.0
	$HashFunction.rotation_degrees.y = hash_rotation
