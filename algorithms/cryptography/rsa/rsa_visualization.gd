class_name RSAVisualization
extends Node3D

# RSA Encryption: Cryptographic Authority & Digital Trust
# Visualizes public-key cryptography, prime factorization security
# Explores digital sovereignty and cryptographic power structures

@export_category("RSA Configuration")
@export var key_size_bits: int = 512  # Key size in bits (128, 256, 512, 1024)
@export var auto_generate_keys: bool = true
@export var demo_message: String = "HELLO WORLD"
@export var use_text_mode: bool = true  # Text vs numeric input
@export var show_intermediate_steps: bool = true

@export_category("Prime Generation")
@export var primality_test_rounds: int = 10  # Miller-Rabin rounds
@export var prime_search_method: String = "random"  # random, sequential
@export var show_prime_generation: bool = true
@export var animate_prime_search: bool = true

@export_category("Visualization")
@export var show_key_components: bool = true
@export var show_encryption_steps: bool = true
@export var show_mathematical_operations: bool = true
@export var animate_modular_exponentiation: bool = true
@export var display_binary_representation: bool = false

@export_category("Security Analysis")
@export var show_factorization_challenge: bool = true
@export var demonstrate_key_vulnerabilities: bool = true
@export var show_timing_analysis: bool = false
@export var educational_warnings: bool = true

@export_category("Animation")
@export var auto_start_demo: bool = true
@export var step_by_step_mode: bool = true
@export var animation_speed: float = 1.0
@export var calculation_delay: float = 0.8

# Colors for visualization
@export var public_key_color: Color = Color(0.2, 0.8, 0.3, 1.0)    # Green
@export var private_key_color: Color = Color(0.8, 0.2, 0.3, 1.0)   # Red
@export var plaintext_color: Color = Color(0.3, 0.5, 0.9, 1.0)     # Blue
@export var ciphertext_color: Color = Color(0.9, 0.6, 0.2, 1.0)    # Orange
@export var prime_color: Color = Color(0.9, 0.2, 0.9, 1.0)         # Magenta
@export var calculation_color: Color = Color(0.9, 0.9, 0.2, 1.0)   # Yellow

# RSA key components
var p: int = 0  # First prime
var q: int = 0  # Second prime
var n: int = 0  # Modulus (p * q)
var phi_n: int = 0  # Euler's totient function φ(n) = (p-1)(q-1)
var e: int = 65537  # Public exponent (commonly used)
var d: int = 0  # Private exponent

# Current encryption state
var plaintext_message: String = ""
var plaintext_numbers: Array = []
var ciphertext_numbers: Array = []
var decrypted_numbers: Array = []
var decrypted_message: String = ""

# Algorithm state
var is_generating_keys: bool = false
var is_encrypting: bool = false
var is_decrypting: bool = false
var key_generation_complete: bool = false
var current_operation_step: int = 0

# Visualization elements
var key_display_meshes: Array = []
var message_display_meshes: Array = []
var calculation_display_meshes: Array = []
var ui_display: CanvasLayer
var operation_timer: Timer

# Prime generation tracking
var prime_candidates: Array = []
var current_prime_candidate: int = 0
var prime_generation_attempts: int = 0

# Performance metrics
var key_generation_time: float = 0.0
var encryption_time: float = 0.0
var decryption_time: float = 0.0

func _init():
	name = "RSA_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	
	if auto_generate_keys:
		call_deferred("start_key_generation")
	
	if auto_start_demo:
		call_deferred("start_demo_encryption")

func setup_ui():
	"""Create comprehensive UI for RSA visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(600, 1000)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for RSA information
	for i in range(40):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for step-by-step operations"""
	operation_timer = Timer.new()
	operation_timer.wait_time = calculation_delay
	operation_timer.timeout.connect(_on_operation_timer_timeout)
	add_child(operation_timer)

func start_key_generation():
	"""Start RSA key generation process"""
	if is_generating_keys:
		return
	
	print("Starting RSA key generation with ", key_size_bits, " bit keys...")
	is_generating_keys = true
	key_generation_complete = false
	var start_time = Time.get_time_dict_from_system()
	key_generation_time = Time.get_ticks_msec()
	
	if step_by_step_mode:
		current_operation_step = 0
		operation_timer.start()
	else:
		generate_keys_complete()

func generate_keys_complete():
	"""Generate complete RSA key pair"""
	# Step 1: Generate two large primes
	var prime_bit_size = key_size_bits / 2
	p = generate_large_prime(prime_bit_size)
	q = generate_large_prime(prime_bit_size)
	
	# Ensure p != q
	while q == p:
		q = generate_large_prime(prime_bit_size)
	
	# Step 2: Compute n = p * q
	n = p * q
	
	# Step 3: Compute φ(n) = (p-1)(q-1)
	phi_n = (p - 1) * (q - 1)
	
	# Step 4: Choose e (commonly 65537)
	e = 65537
	
	# Ensure gcd(e, φ(n)) = 1
	while gcd(e, phi_n) != 1:
		e += 2
	
	# Step 5: Compute d = e^(-1) mod φ(n)
	d = mod_inverse(e, phi_n)
	
	finalize_key_generation()

func generate_large_prime(bit_size: int) -> int:
	"""Generate a large prime number"""
	var min_value = pow(2, bit_size - 1)
	var max_value = pow(2, bit_size) - 1
	
	# Clamp to reasonable values for demonstration
	min_value = max(min_value, 100)
	max_value = min(max_value, 1000000)
	
	var candidate = randi_range(min_value, max_value)
	
	# Ensure odd number
	if candidate % 2 == 0:
		candidate += 1
	
	# Search for prime
	while not is_prime(candidate):
		candidate += 2
		prime_generation_attempts += 1
		
		# Prevent infinite loops with fallback
		if prime_generation_attempts > 10000:
			candidate = get_known_prime(bit_size)
			break
	
	print("Generated prime: ", candidate, " (", bit_size, " bit equivalent)")
	return candidate

func get_known_prime(bit_size: int) -> int:
	"""Get a known prime for the given bit size range"""
	var known_primes = [
		101, 103, 107, 109, 113, 127, 131, 137, 139, 149,
		151, 157, 163, 167, 173, 179, 181, 191, 193, 197,
		199, 211, 223, 227, 229, 233, 239, 241, 251, 257,
		263, 269, 271, 277, 281, 283, 293, 307, 311, 313,
		317, 331, 337, 347, 349, 353, 359, 367, 373, 379,
		383, 389, 397, 401, 409, 419, 421, 431, 433, 439,
		443, 449, 457, 461, 463, 467, 479, 487, 491, 499,
		503, 509, 521, 523, 541, 547, 557, 563, 569, 571,
		577, 587, 593, 599, 601, 607, 613, 617, 619, 631,
		641, 643, 647, 653, 659, 661, 673, 677, 683, 691,
		701, 709, 719, 727, 733, 739, 743, 751, 757, 761,
		769, 773, 787, 797, 809, 811, 821, 823, 827, 829,
		839, 853, 857, 859, 863, 877, 881, 883, 887, 907
	]
	
	return known_primes[randi() % known_primes.size()]

func is_prime(n: int) -> bool:
	"""Miller-Rabin primality test"""
	if n < 2:
		return false
	if n == 2 or n == 3:
		return true
	if n % 2 == 0:
		return false
	
	# Write n-1 as d * 2^r
	var d = n - 1
	var r = 0
	while d % 2 == 0:
		d = d / 2
		r += 1
	
	# Perform Miller-Rabin test
	for i in range(primality_test_rounds):
		var a = randi_range(2, n - 2)
		var x = mod_exp(a, d, n)
		
		if x == 1 or x == n - 1:
			continue
		
		var composite = true
		for j in range(r - 1):
			x = (x * x) % n
			if x == n - 1:
				composite = false
				break
		
		if composite:
			return false
	
	return true

func gcd(a: int, b: int) -> int:
	"""Greatest Common Divisor using Euclidean algorithm"""
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return a

func mod_inverse(a: int, m: int) -> int:
	"""Modular multiplicative inverse using Extended Euclidean Algorithm"""
	if gcd(a, m) != 1:
		return -1  # No inverse exists
	
	var m0 = m
	var x0 = 0
	var x1 = 1
	
	while a > 1:
		var q = a / m
		var t = m
		m = a % m
		a = t
		t = x0
		x0 = x1 - q * x0
		x1 = t
	
	if x1 < 0:
		x1 += m0
	
	return x1

func mod_exp(base: int, exponent: int, modulus: int) -> int:
	"""Fast modular exponentiation using binary method"""
	if modulus == 1:
		return 0
	
	var result = 1
	base = base % modulus
	
	while exponent > 0:
		if exponent % 2 == 1:
			result = (result * base) % modulus
		exponent = exponent >> 1
		base = (base * base) % modulus
	
	return result

func finalize_key_generation():
	"""Finalize key generation and update visualization"""
	is_generating_keys = false
	key_generation_complete = true
	key_generation_time = Time.get_ticks_msec() - key_generation_time
	operation_timer.stop()
	
	print("RSA Key Generation Complete!")
	print("Public Key (e, n): (", e, ", ", n, ")")
	print("Private Key (d, n): (", d, ", ", n, ")")
	print("Primes: p =", p, ", q =", q)
	print("φ(n) =", phi_n)
	print("Generation time: ", key_generation_time, " ms")
	
	create_key_visualization()
	update_ui()

func start_demo_encryption():
	"""Start demonstration encryption"""
	if not key_generation_complete:
		print("Keys not generated yet, waiting...")
		return
	
	plaintext_message = demo_message
	start_encryption(plaintext_message)

func start_encryption(message: String):
	"""Start encryption process"""
	if is_encrypting or not key_generation_complete:
		return
	
	is_encrypting = true
	plaintext_message = message
	ciphertext_numbers.clear()
	var start_time = Time.get_ticks_msec()
	
	# Convert message to numbers
	if use_text_mode:
		plaintext_numbers = message_to_numbers(message)
	else:
		# Parse numeric input
		plaintext_numbers = [int(message)]
	
	print("Starting encryption of: '", message, "'")
	print("Plaintext numbers: ", plaintext_numbers)
	
	if step_by_step_mode:
		current_operation_step = 0
		operation_timer.start()
	else:
		encrypt_complete()

func message_to_numbers(message: String) -> Array:
	"""Convert text message to array of numbers"""
	var numbers = []
	for i in range(message.length()):
		var char_code = message.unicode_at(i)
		# Ensure number is smaller than n for encryption
		if char_code >= n:
			char_code = char_code % (n - 1) + 1
		numbers.append(char_code)
	return numbers

func encrypt_complete():
	"""Perform complete encryption"""
	ciphertext_numbers.clear()
	
	for plaintext_num in plaintext_numbers:
		# C = M^e mod n
		var ciphertext_num = mod_exp(plaintext_num, e, n)
		ciphertext_numbers.append(ciphertext_num)
	
	finalize_encryption()

func finalize_encryption():
	"""Finalize encryption process"""
	is_encrypting = false
	encryption_time = Time.get_ticks_msec() - encryption_time
	operation_timer.stop()
	
	print("Encryption complete!")
	print("Ciphertext numbers: ", ciphertext_numbers)
	print("Encryption time: ", encryption_time, " ms")
	
	create_encryption_visualization()
	update_ui()

func start_decryption():
	"""Start decryption process"""
	if is_decrypting or ciphertext_numbers.is_empty():
		return
	
	is_decrypting = true
	decrypted_numbers.clear()
	var start_time = Time.get_ticks_msec()
	
	print("Starting decryption...")
	
	if step_by_step_mode:
		current_operation_step = 0
		operation_timer.start()
	else:
		decrypt_complete()

func decrypt_complete():
	"""Perform complete decryption"""
	decrypted_numbers.clear()
	
	for ciphertext_num in ciphertext_numbers:
		# M = C^d mod n
		var decrypted_num = mod_exp(ciphertext_num, d, n)
		decrypted_numbers.append(decrypted_num)
	
	# Convert back to text
	if use_text_mode:
		decrypted_message = numbers_to_message(decrypted_numbers)
	else:
		decrypted_message = str(decrypted_numbers[0])
	
	finalize_decryption()

func numbers_to_message(numbers: Array) -> String:
	"""Convert array of numbers back to text message"""
	var message = ""
	for num in numbers:
		message += char(num)
	return message

func finalize_decryption():
	"""Finalize decryption process"""
	is_decrypting = false
	decryption_time = Time.get_ticks_msec() - decryption_time
	operation_timer.stop()
	
	print("Decryption complete!")
	print("Decrypted numbers: ", decrypted_numbers)
	print("Decrypted message: '", decrypted_message, "'")
	print("Decryption time: ", decryption_time, " ms")
	
	# Verify correctness
	var is_correct = (decrypted_message == plaintext_message)
	print("Decryption correct: ", is_correct)
	
	create_decryption_visualization()
	update_ui()

func _on_operation_timer_timeout():
	"""Handle step-by-step operation timer"""
	if is_generating_keys:
		step_key_generation()
	elif is_encrypting:
		step_encryption()
	elif is_decrypting:
		step_decryption()

func step_key_generation():
	"""Perform one step of key generation"""
	match current_operation_step:
		0:
			print("Step 1: Generating prime p...")
			var prime_bit_size = key_size_bits / 2
			p = generate_large_prime(prime_bit_size)
			current_operation_step += 1
		1:
			print("Step 2: Generating prime q...")
			var prime_bit_size = key_size_bits / 2
			q = generate_large_prime(prime_bit_size)
			while q == p:
				q = generate_large_prime(prime_bit_size)
			current_operation_step += 1
		2:
			print("Step 3: Computing n = p * q...")
			n = p * q
			current_operation_step += 1
		3:
			print("Step 4: Computing φ(n) = (p-1)(q-1)...")
			phi_n = (p - 1) * (q - 1)
			current_operation_step += 1
		4:
			print("Step 5: Computing private exponent d...")
			d = mod_inverse(e, phi_n)
			finalize_key_generation()

func step_encryption():
	"""Perform one step of encryption"""
	if current_operation_step < plaintext_numbers.size():
		var plaintext_num = plaintext_numbers[current_operation_step]
		var ciphertext_num = mod_exp(plaintext_num, e, n)
		ciphertext_numbers.append(ciphertext_num)
		
		print("Encrypting ", plaintext_num, " -> ", ciphertext_num)
		current_operation_step += 1
	else:
		finalize_encryption()

func step_decryption():
	"""Perform one step of decryption"""
	if current_operation_step < ciphertext_numbers.size():
		var ciphertext_num = ciphertext_numbers[current_operation_step]
		var decrypted_num = mod_exp(ciphertext_num, d, n)
		decrypted_numbers.append(decrypted_num)
		
		print("Decrypting ", ciphertext_num, " -> ", decrypted_num)
		current_operation_step += 1
	else:
		if use_text_mode:
			decrypted_message = numbers_to_message(decrypted_numbers)
		else:
			decrypted_message = str(decrypted_numbers[0])
		finalize_decryption()

func create_key_visualization():
	"""Create 3D visualization of RSA keys"""
	clear_key_visualization()
	
	# Public key visualization (green)
	var public_key_mesh = create_key_display("PUBLIC KEY", Vector3(-3, 2, 0), public_key_color)
	add_child(public_key_mesh)
	key_display_meshes.append(public_key_mesh)
	
	# Private key visualization (red)
	var private_key_mesh = create_key_display("PRIVATE KEY", Vector3(3, 2, 0), private_key_color)
	add_child(private_key_mesh)
	key_display_meshes.append(private_key_mesh)
	
	# Prime factors visualization (magenta)
	var prime_p_mesh = create_number_display("p=" + str(p), Vector3(-2, -1, 0), prime_color)
	add_child(prime_p_mesh)
	key_display_meshes.append(prime_p_mesh)
	
	var prime_q_mesh = create_number_display("q=" + str(q), Vector3(2, -1, 0), prime_color)
	add_child(prime_q_mesh)
	key_display_meshes.append(prime_q_mesh)

func create_encryption_visualization():
	"""Create visualization of encryption process"""
	clear_message_visualization()
	
	# Plaintext visualization
	var plaintext_mesh = create_message_display("PLAINTEXT", Vector3(-4, 0, 2), plaintext_color)
	add_child(plaintext_mesh)
	message_display_meshes.append(plaintext_mesh)
	
	# Ciphertext visualization
	var ciphertext_mesh = create_message_display("CIPHERTEXT", Vector3(4, 0, 2), ciphertext_color)
	add_child(ciphertext_mesh)
	message_display_meshes.append(ciphertext_mesh)
	
	# Arrow showing encryption direction
	var arrow_mesh = create_arrow_display(Vector3(-2, 0, 2), Vector3(2, 0, 2), calculation_color)
	add_child(arrow_mesh)
	message_display_meshes.append(arrow_mesh)

func create_decryption_visualization():
	"""Create visualization of decryption process"""
	# Add decrypted text display
	var decrypted_mesh = create_message_display("DECRYPTED", Vector3(0, 0, -2), plaintext_color)
	add_child(decrypted_mesh)
	message_display_meshes.append(decrypted_mesh)

func create_key_display(text: String, position: Vector3, color: Color) -> MeshInstance3D:
	"""Create visual display for cryptographic keys"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(2, 1, 0.2)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	mesh_instance.material_override = material
	
	mesh_instance.position = position
	
	# Add text label
	var label = Label3D.new()
	label.text = text
	label.position = Vector3(0, 0.8, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_instance.add_child(label)
	
	return mesh_instance

func create_number_display(text: String, position: Vector3, color: Color) -> MeshInstance3D:
	"""Create visual display for numbers"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	mesh_instance.position = position
	
	# Add number label
	var label = Label3D.new()
	label.text = text
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_instance.add_child(label)
	
	return mesh_instance

func create_message_display(text: String, position: Vector3, color: Color) -> MeshInstance3D:
	"""Create visual display for messages"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.8
	mesh.bottom_radius = 0.8
	mesh.height = 0.5
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	mesh_instance.position = position
	
	# Add message label
	var label = Label3D.new()
	label.text = text
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_instance.add_child(label)
	
	return mesh_instance

func create_arrow_display(from_pos: Vector3, to_pos: Vector3, color: Color) -> MeshInstance3D:
	"""Create arrow visualization"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.1
	mesh.bottom_radius = 0.1
	mesh.height = from_pos.distance_to(to_pos)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	mesh_instance.material_override = material
	
	var mid_pos = (from_pos + to_pos) / 2.0
	mesh_instance.position = mid_pos
	mesh_instance.look_at_from_position(mesh_instance.position, to_pos, Vector3.UP)
	
	return mesh_instance

func clear_key_visualization():
	"""Clear key visualization elements"""
	for mesh in key_display_meshes:
		if mesh:
			mesh.queue_free()
	key_display_meshes.clear()

func clear_message_visualization():
	"""Clear message visualization elements"""
	for mesh in message_display_meshes:
		if mesh:
			mesh.queue_free()
	message_display_meshes.clear()

func update_ui():
	"""Update UI with current RSA state"""
	if not ui_display:
		return
	
	# Check if the UI structure exists
	var panel = ui_display.get_node("Panel")
	if not panel:
		return
	var vbox = panel.get_node("VBoxContainer")
	if not vbox:
		return
	
	var labels = []
	for i in range(40):
		var label = vbox.get_node("info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 40:
		labels[0].text = "🔐 RSA Encryption - Cryptographic Authority"
		labels[1].text = "Key Size: " + str(key_size_bits) + " bits"
		labels[2].text = "Primality Tests: " + str(primality_test_rounds) + " rounds"
		labels[3].text = ""
		labels[4].text = "Status: " + get_current_status()
		labels[5].text = "Key Generation: " + ("Complete" if key_generation_complete else "Pending")
		labels[6].text = "Generation Time: " + str(key_generation_time) + " ms"
		labels[7].text = ""
		labels[8].text = "RSA Key Components:"
		labels[9].text = "Prime p: " + str(p) if p > 0 else "Prime p: Not generated"
		labels[10].text = "Prime q: " + str(q) if q > 0 else "Prime q: Not generated"
		labels[11].text = "Modulus n: " + str(n) if n > 0 else "Modulus n: Not computed"
		labels[12].text = "φ(n): " + str(phi_n) if phi_n > 0 else "φ(n): Not computed"
		labels[13].text = "Public exp e: " + str(e) if e > 0 else "Public exp e: Not set"
		labels[14].text = "Private exp d: " + str(d) if d > 0 else "Private exp d: Not computed"
		labels[15].text = ""
		labels[16].text = "Current Operation:"
		labels[17].text = "Message: '" + plaintext_message + "'"
		labels[18].text = "Plaintext nums: " + str(plaintext_numbers)
		labels[19].text = "Ciphertext nums: " + str(ciphertext_numbers)
		labels[20].text = "Decrypted nums: " + str(decrypted_numbers)
		labels[21].text = "Decrypted msg: '" + decrypted_message + "'"
		labels[22].text = ""
		labels[23].text = "Cryptographic Properties:"
		labels[24].text = "Security Level: " + get_security_level()
		labels[25].text = "Factorization Difficulty: " + get_factorization_difficulty()
		labels[26].text = "Public Key (e,n): (" + str(e) + "," + str(n) + ")"
		labels[27].text = "Private Key (d,n): (" + str(d) + "," + str(n) + ")"
		labels[28].text = ""
		labels[29].text = "Performance Metrics:"
		labels[30].text = "Key Gen Time: " + str(key_generation_time) + " ms"
		labels[31].text = "Encryption Time: " + str(encryption_time) + " ms"
		labels[32].text = "Decryption Time: " + str(decryption_time) + " ms"
		labels[33].text = "Prime Gen Attempts: " + str(prime_generation_attempts)
		labels[34].text = ""
		labels[35].text = "Controls:"
		labels[36].text = "SPACE - Encrypt, D - Decrypt, G - Generate Keys"
		labels[37].text = "R - Reset, M - Change Message, 1-4 - Key Sizes"
		labels[38].text = ""
		labels[39].text = "🏳️‍🌈 Explores cryptographic power & digital sovereignty"

func get_current_status() -> String:
	"""Get current operation status"""
	if is_generating_keys:
		return "Generating Keys..."
	elif is_encrypting:
		return "Encrypting..."
	elif is_decrypting:
		return "Decrypting..."
	elif key_generation_complete:
		return "Ready"
	else:
		return "Idle"

func get_security_level() -> String:
	"""Assess security level based on key size"""
	match key_size_bits:
		128:
			return "DEMO ONLY - Easily breakable"
		256:
			return "WEAK - Educational purposes"
		512:
			return "MODERATE - Short-term security"
		1024:
			return "GOOD - Legacy standard"
		_:
			return "UNKNOWN"

func get_factorization_difficulty() -> String:
	"""Estimate factorization difficulty"""
	var num_digits = str(n).length()
	if num_digits < 10:
		return "TRIVIAL (" + str(num_digits) + " digits)"
	elif num_digits < 20:
		return "EASY (" + str(num_digits) + " digits)"
	elif num_digits < 50:
		return "MODERATE (" + str(num_digits) + " digits)"
	else:
		return "HARD (" + str(num_digits) + " digits)"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if key_generation_complete and not is_encrypting:
					start_encryption(demo_message)
			KEY_D:
				if not ciphertext_numbers.is_empty() and not is_decrypting:
					start_decryption()
			KEY_G:
				start_key_generation()
			KEY_R:
				reset_rsa()
			KEY_M:
				change_demo_message()
			KEY_1:
				change_key_size(128)
			KEY_2:
				change_key_size(256)
			KEY_3:
				change_key_size(512)
			KEY_4:
				change_key_size(1024)
			KEY_S:
				step_by_step_mode = not step_by_step_mode
				print("Step-by-step mode: ", step_by_step_mode)

func reset_rsa():
	"""Reset RSA system"""
	is_generating_keys = false
	is_encrypting = false
	is_decrypting = false
	key_generation_complete = false
	operation_timer.stop()
	
	# Clear key components
	p = 0
	q = 0
	n = 0
	phi_n = 0
	d = 0
	
	# Clear messages
	plaintext_numbers.clear()
	ciphertext_numbers.clear()
	decrypted_numbers.clear()
	decrypted_message = ""
	
	# Clear visualizations
	clear_key_visualization()
	clear_message_visualization()
	
	print("RSA system reset")
	update_ui()

func change_demo_message():
	"""Change demonstration message"""
	var messages = ["HELLO", "SECRET", "CRYPTO", "SECURE", "PRIVACY"]
	demo_message = messages[randi() % messages.size()]
	plaintext_message = demo_message
	print("Changed demo message to: ", demo_message)

func change_key_size(new_size: int):
	"""Change RSA key size"""
	key_size_bits = new_size
	reset_rsa()
	print("Changed key size to ", new_size, " bits")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive RSA algorithm information"""
	return {
		"name": "RSA Encryption",
		"description": "Public-key cryptography with prime factorization security",
		"key_properties": {
			"key_size_bits": key_size_bits,
			"prime_p": p,
			"prime_q": q,
			"modulus_n": n,
			"euler_totient": phi_n,
			"public_exponent": e,
			"private_exponent": d
		},
		"security_analysis": {
			"security_level": get_security_level(),
			"factorization_difficulty": get_factorization_difficulty(),
			"prime_generation_attempts": prime_generation_attempts
		},
		"performance": {
			"key_generation_time_ms": key_generation_time,
			"encryption_time_ms": encryption_time,
			"decryption_time_ms": decryption_time
		},
		"current_state": {
			"is_generating_keys": is_generating_keys,
			"is_encrypting": is_encrypting,
			"is_decrypting": is_decrypting,
			"key_generation_complete": key_generation_complete,
			"plaintext_message": plaintext_message,
			"decrypted_message": decrypted_message
		}
	} 
