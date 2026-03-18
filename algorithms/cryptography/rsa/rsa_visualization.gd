class_name RSAVisualization
extends Node3D

# RSA Encryption — Show the Math Visually
# Prime search grid, modular exponentiation tree, live encrypt/decrypt timeline
# Color-coded public vs private key components with educational labels

# ── constants ────────────────────────────────────────────────────────
const COL_PUBLIC   := Color(0.25, 0.85, 0.4)      # green — public key
const COL_PRIVATE  := Color(0.9, 0.25, 0.35)      # red — private key
const COL_PLAIN    := Color(0.35, 0.55, 0.95)      # blue — plaintext
const COL_CIPHER   := Color(0.95, 0.6, 0.15)       # orange — ciphertext
const COL_PRIME    := Color(0.85, 0.3, 0.9)        # magenta — primes
const COL_COMPUTE  := Color(0.95, 0.9, 0.2)        # yellow — computation
const COL_GRID_BG  := Color(0.12, 0.13, 0.18, 0.7) # dark panel background
const COL_COMPOSITE := Color(0.2, 0.22, 0.28, 0.4) # dim — composite numbers
const COL_LABEL    := Color(0.92, 0.92, 0.96)
const COL_DIM      := Color(0.5, 0.5, 0.55)

const GRID_COLS    := 10
const GRID_ROWS    := 10
const CELL_SIZE    := 0.055
const CELL_GAP     := 0.005
const MSG_CHARS    := 5          # message length for demo

# ── state ────────────────────────────────────────────────────────────
var _time           := 0.0
var _phase          := 0         # 0=prime_search, 1=key_display, 2=encrypt, 3=decrypt, 4=done
var _phase_timer    := 0.0
var _is_init        := false

# prime search state
var _grid_start     := 101       # first number in sieve grid
var _search_idx     := 0         # how far the search cursor has advanced
var _grid_primes    : Array[bool] = []   # true if prime
var _prime_p        := 0
var _prime_q        := 0
var _search_speed   := 40.0      # cells per second

# RSA key components
var _n              := 0
var _phi            := 0
var _e              := 65537
var _d              := 0

# message & encryption
var _message        := "HELLO"
var _plain_nums     : Array[int] = []
var _cipher_nums    : Array[int] = []
var _decrypt_nums   : Array[int] = []
var _enc_step       := 0         # which char being encrypted
var _dec_step       := 0
var _enc_progress   := 0.0       # 0→1 animation within current char
var _dec_progress   := 0.0

# mod-exp tree state (for current step)
var _modexp_steps   : Array[Dictionary] = []  # [{base, exp, result}]

# animation speed
var _anim_speed     := 1.0

# ── meshes ───────────────────────────────────────────────────────────
var _grid_im        : ImmediateMesh    # prime search grid
var _grid_mi        : MeshInstance3D
var _tree_im        : ImmediateMesh    # mod-exp tree
var _tree_mi        : MeshInstance3D
var _timeline_im    : ImmediateMesh    # encrypt/decrypt timeline
var _timeline_mi    : MeshInstance3D
var _key_im         : ImmediateMesh    # key component display
var _key_mi         : MeshInstance3D

var _mat            : StandardMaterial3D

# labels
var _title_label    : Label3D
var _phase_label    : Label3D
var _key_label      : Label3D
var _formula_label  : Label3D
var _step_label     : Label3D

# VR controllers
var _speed_ctrl     : ParameterController3D
var _msg_ctrl       : ParameterController3D
var _prime_ctrl     : ParameterController3D

# ── known small primes for demo range ────────────────────────────────
var _known_primes : Array[int] = []

func _ready() -> void:
	_build_known_primes()
	_create_material()
	_create_meshes()
	_create_labels()
	_create_controllers()
	_init_prime_grid()
	_pick_message()
	_is_init = true

func _build_known_primes() -> void:
	# Sieve of Eratosthenes up to 1200
	var sieve : Array[bool] = []
	sieve.resize(1201)
	for i in range(1201):
		sieve[i] = true
	sieve[0] = false
	sieve[1] = false
	for i in range(2, 35):
		if sieve[i]:
			var j := i * i
			while j <= 1200:
				sieve[j] = false
				j += i
	_known_primes.clear()
	for i in range(2, 1201):
		if sieve[i]:
			_known_primes.append(i)

func _is_known_prime(val: int) -> bool:
	return _known_primes.has(val)

func _create_material() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _create_meshes() -> void:
	# Prime search grid
	_grid_im = ImmediateMesh.new()
	_grid_mi = MeshInstance3D.new()
	_grid_mi.mesh = _grid_im
	_grid_mi.material_override = _mat
	_grid_mi.position = Vector3(-0.35, 0.15, 0.0)
	add_child(_grid_mi)

	# Key component display
	_key_im = ImmediateMesh.new()
	_key_mi = MeshInstance3D.new()
	_key_mi.mesh = _key_im
	_key_mi.material_override = _mat
	_key_mi.position = Vector3(0.0, 0.0, 0.0)
	add_child(_key_mi)

	# Mod-exp tree
	_tree_im = ImmediateMesh.new()
	_tree_mi = MeshInstance3D.new()
	_tree_mi.mesh = _tree_im
	_tree_mi.material_override = _mat
	_tree_mi.position = Vector3(0.2, 0.15, 0.0)
	add_child(_tree_mi)

	# Encryption/decryption timeline
	_timeline_im = ImmediateMesh.new()
	_timeline_mi = MeshInstance3D.new()
	_timeline_mi.mesh = _timeline_im
	_timeline_mi.material_override = _mat
	_timeline_mi.position = Vector3(0.0, -0.15, 0.0)
	add_child(_timeline_mi)

func _create_labels() -> void:
	_title_label = _make_label(Vector3(0.0, 0.42, 0.0), 28)
	_title_label.text = "RSA Encryption"
	_title_label.modulate = COL_LABEL

	_phase_label = _make_label(Vector3(0.0, 0.37, 0.0), 20)
	_phase_label.modulate = COL_COMPUTE

	_key_label = _make_label(Vector3(0.0, 0.05, 0.0), 18)
	_key_label.modulate = COL_LABEL

	_formula_label = _make_label(Vector3(0.2, 0.32, 0.0), 16)
	_formula_label.modulate = COL_COMPUTE

	_step_label = _make_label(Vector3(0.0, -0.28, 0.0), 16)
	_step_label.modulate = COL_DIM

func _make_label(pos: Vector3, size: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = size
	lbl.outline_size = 4
	lbl.position = pos
	add_child(lbl)
	return lbl

func _create_controllers() -> void:
	var y_base := -0.38

	_speed_ctrl = ParameterController3D.new()
	_speed_ctrl.parameter_name = "Speed"
	_speed_ctrl.min_value = 0.2
	_speed_ctrl.max_value = 3.0
	_speed_ctrl.default_value = 1.0
	_speed_ctrl.step_size = 0.1
	_speed_ctrl.position = Vector3(-0.25, y_base, 0.0)
	_speed_ctrl.value_changed.connect(func(v: float) -> void: _anim_speed = v)
	add_child(_speed_ctrl)

	_msg_ctrl = ParameterController3D.new()
	_msg_ctrl.parameter_name = "Message"
	_msg_ctrl.min_value = 0.0
	_msg_ctrl.max_value = 4.0
	_msg_ctrl.default_value = 0.0
	_msg_ctrl.step_size = 1.0
	_msg_ctrl.position = Vector3(0.0, y_base, 0.0)
	_msg_ctrl.value_changed.connect(func(v: float) -> void: _pick_message_by_index(int(v)); _restart())
	add_child(_msg_ctrl)

	_prime_ctrl = ParameterController3D.new()
	_prime_ctrl.parameter_name = "Prime Range"
	_prime_ctrl.min_value = 0.0
	_prime_ctrl.max_value = 3.0
	_prime_ctrl.default_value = 0.0
	_prime_ctrl.step_size = 1.0
	_prime_ctrl.position = Vector3(0.25, y_base, 0.0)
	_prime_ctrl.value_changed.connect(func(v: float) -> void: _set_prime_range(int(v)); _restart())
	add_child(_prime_ctrl)

# ── initialization helpers ───────────────────────────────────────────
func _init_prime_grid() -> void:
	_grid_primes.clear()
	_grid_primes.resize(GRID_COLS * GRID_ROWS)
	for i in range(GRID_COLS * GRID_ROWS):
		var val := _grid_start + i
		_grid_primes[i] = _is_known_prime(val)
	_search_idx = 0
	_prime_p = 0
	_prime_q = 0

func _pick_message() -> void:
	_pick_message_by_index(0)

func _pick_message_by_index(idx: int) -> void:
	var msgs := ["HELLO", "CRYPT", "QUEER", "TRUST", "POWER"]
	idx = clampi(idx, 0, msgs.size() - 1)
	_message = msgs[idx]

func _set_prime_range(idx: int) -> void:
	var ranges := [101, 211, 401, 701]
	idx = clampi(idx, 0, ranges.size() - 1)
	_grid_start = ranges[idx]
	_init_prime_grid()

func _restart() -> void:
	_phase = 0
	_phase_timer = 0.0
	_search_idx = 0
	_prime_p = 0
	_prime_q = 0
	_n = 0
	_phi = 0
	_d = 0
	_enc_step = 0
	_dec_step = 0
	_enc_progress = 0.0
	_dec_progress = 0.0
	_plain_nums.clear()
	_cipher_nums.clear()
	_decrypt_nums.clear()
	_modexp_steps.clear()
	_init_prime_grid()

# ── process ──────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _is_init:
		return
	_time += delta
	var dt := delta * _anim_speed

	match _phase:
		0: _update_prime_search(dt)
		1: _update_key_display(dt)
		2: _update_encryption(dt)
		3: _update_decryption(dt)
		4: _update_done(dt)

	_rebuild_grid()
	_rebuild_key_display()
	_rebuild_tree()
	_rebuild_timeline()
	_update_labels()

# ── phase logic ──────────────────────────────────────────────────────
func _update_prime_search(dt: float) -> void:
	_phase_timer += dt
	var advance := dt * _search_speed
	_search_idx = mini(_search_idx + int(advance) + 1, GRID_COLS * GRID_ROWS)

	# Find first two primes in scanned region
	if _prime_p == 0 or _prime_q == 0:
		for i in range(_search_idx):
			var val := _grid_start + i
			if _grid_primes[i]:
				if _prime_p == 0:
					_prime_p = val
				elif _prime_q == 0 and val != _prime_p:
					_prime_q = val
					break

	# Transition when grid fully scanned
	if _search_idx >= GRID_COLS * GRID_ROWS:
		# Ensure we have two primes
		if _prime_p == 0 or _prime_q == 0:
			_pick_fallback_primes()
		_compute_keys()
		_phase = 1
		_phase_timer = 0.0

func _pick_fallback_primes() -> void:
	# Find two primes near our grid range
	for pr in _known_primes:
		if pr >= _grid_start:
			if _prime_p == 0:
				_prime_p = pr
			elif pr != _prime_p:
				_prime_q = pr
				return

func _compute_keys() -> void:
	_n = _prime_p * _prime_q
	_phi = (_prime_p - 1) * (_prime_q - 1)
	_e = 65537
	# Need e < phi and gcd(e, phi) == 1
	if _e >= _phi:
		_e = 3
	while _gcd(_e, _phi) != 1:
		_e += 2
	_d = _mod_inverse(_e, _phi)
	# Prepare message numbers
	_plain_nums.clear()
	for i in range(_message.length()):
		var c := _message.unicode_at(i)
		if c >= _n:
			c = c % (_n - 1) + 1
		_plain_nums.append(c)
	_cipher_nums.clear()
	_cipher_nums.resize(_plain_nums.size())
	for i in range(_cipher_nums.size()):
		_cipher_nums[i] = 0
	_decrypt_nums.clear()
	_decrypt_nums.resize(_plain_nums.size())
	for i in range(_decrypt_nums.size()):
		_decrypt_nums[i] = 0
	_enc_step = 0
	_dec_step = 0
	_enc_progress = 0.0
	_dec_progress = 0.0

func _update_key_display(dt: float) -> void:
	_phase_timer += dt
	if _phase_timer > 3.0:
		_phase = 2
		_phase_timer = 0.0
		_compute_modexp_steps(_plain_nums[0], _e, _n)

func _update_encryption(dt: float) -> void:
	_enc_progress += dt * 0.8
	if _enc_progress >= 1.0:
		_enc_progress = 0.0
		# Complete this character encryption
		var pn := _plain_nums[_enc_step]
		_cipher_nums[_enc_step] = _mod_exp(pn, _e, _n)
		_enc_step += 1
		if _enc_step >= _plain_nums.size():
			_phase = 3
			_phase_timer = 0.0
			_dec_step = 0
			_dec_progress = 0.0
			if _cipher_nums.size() > 0:
				_compute_modexp_steps(_cipher_nums[0], _d, _n)
		else:
			_compute_modexp_steps(_plain_nums[_enc_step], _e, _n)

func _update_decryption(dt: float) -> void:
	_dec_progress += dt * 0.8
	if _dec_progress >= 1.0:
		_dec_progress = 0.0
		var cn := _cipher_nums[_dec_step]
		_decrypt_nums[_dec_step] = _mod_exp(cn, _d, _n)
		_dec_step += 1
		if _dec_step >= _cipher_nums.size():
			_phase = 4
			_phase_timer = 0.0
			_modexp_steps.clear()
		else:
			_compute_modexp_steps(_cipher_nums[_dec_step], _d, _n)

func _update_done(dt: float) -> void:
	_phase_timer += dt
	if _phase_timer > 5.0:
		_restart()

# ── modular exponentiation steps ─────────────────────────────────────
func _compute_modexp_steps(base_val: int, exp_val: int, mod_val: int) -> void:
	_modexp_steps.clear()
	if mod_val <= 1:
		return
	var b := base_val % mod_val
	var bits : Array[int] = []
	var tmp := exp_val
	while tmp > 0:
		bits.append(tmp & 1)
		tmp >>= 1
	# Repeated squaring: track each step
	var current := 1
	for i in range(bits.size()):
		# Square step
		var squared := (current * current) % mod_val if i > 0 else current
		if i > 0:
			_modexp_steps.append({"op": "sq", "val": squared, "bit": bits[i], "exp_so_far": i})
			current = squared
		# Multiply if bit is 1
		if bits[i] == 1:
			var multiplied := (current * b) % mod_val
			_modexp_steps.append({"op": "mul", "val": multiplied, "bit": 1, "exp_so_far": i})
			current = multiplied
	# Limit display
	if _modexp_steps.size() > 12:
		_modexp_steps.resize(12)

# ── rebuild: prime search grid ───────────────────────────────────────
func _rebuild_grid() -> void:
	_grid_im.clear_surfaces()
	if _phase > 1 and _phase_timer > 1.0:
		return  # Hide grid after key generation done

	_grid_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var total := CELL_SIZE + CELL_GAP
	var grid_w := GRID_COLS * total
	var grid_h := GRID_ROWS * total

	# Background panel
	_add_quad_local(_grid_im, Vector3(-0.01, -0.01, -0.001),
		Vector3(grid_w + 0.02, 0, 0), Vector3(0, grid_h + 0.02, 0), COL_GRID_BG)

	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var idx := row * GRID_COLS + col
			var val := _grid_start + idx
			var x := col * total
			var y := (GRID_ROWS - 1 - row) * total

			var scanned := idx < _search_idx
			var is_p := _grid_primes[idx] if idx < _grid_primes.size() else false
			var is_selected_p := (val == _prime_p)
			var is_selected_q := (val == _prime_q)

			var col_cell : Color
			if not scanned:
				col_cell = Color(0.25, 0.27, 0.32, 0.3)
			elif is_selected_p or is_selected_q:
				var pulse := 0.7 + 0.3 * sin(_time * 5.0)
				col_cell = COL_PRIME.lerp(Color.WHITE, pulse * 0.3)
			elif is_p:
				col_cell = COL_PRIME.lerp(COL_COMPUTE, 0.3)
				col_cell.a = 0.85
			else:
				col_cell = COL_COMPOSITE

			_add_quad_local(_grid_im, Vector3(x, y, 0),
				Vector3(CELL_SIZE, 0, 0), Vector3(0, CELL_SIZE, 0), col_cell)

	# Search cursor line
	if _phase == 0 and _search_idx < GRID_COLS * GRID_ROWS:
		var cursor_row := _search_idx / GRID_COLS
		var cursor_col := _search_idx % GRID_COLS
		var cx := cursor_col * total
		var cy := (GRID_ROWS - 1 - cursor_row) * total
		var scan_col := COL_COMPUTE
		scan_col.a = 0.6 + 0.4 * sin(_time * 8.0)
		# Highlight cursor cell
		_add_quad_local(_grid_im, Vector3(cx - 0.003, cy - 0.003, 0.001),
			Vector3(CELL_SIZE + 0.006, 0, 0), Vector3(0, CELL_SIZE + 0.006, 0), scan_col)

	_grid_im.surface_end()

# ── rebuild: key component display ───────────────────────────────────
func _rebuild_key_display() -> void:
	_key_im.clear_surfaces()
	if _phase < 1:
		return

	_key_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Layout: two panels side by side — public key (left), private key (right)
	var panel_w := 0.28
	var panel_h := 0.18
	var gap := 0.04

	# Public key panel (green)
	var pub_x := -panel_w - gap * 0.5
	var pub_col := COL_PUBLIC
	pub_col.a = 0.15
	_add_quad_local(_key_im, Vector3(pub_x, -panel_h * 0.5, -0.001),
		Vector3(panel_w, 0, 0), Vector3(0, panel_h, 0), pub_col)
	# Public key border
	var border_pub := COL_PUBLIC
	border_pub.a = 0.6
	_add_border(_key_im, Vector3(pub_x, -panel_h * 0.5, 0.0), panel_w, panel_h, 0.003, border_pub)

	# Private key panel (red)
	var priv_x := gap * 0.5
	var priv_col := COL_PRIVATE
	priv_col.a = 0.15
	_add_quad_local(_key_im, Vector3(priv_x, -panel_h * 0.5, -0.001),
		Vector3(panel_w, 0, 0), Vector3(0, panel_h, 0), priv_col)
	var border_priv := COL_PRIVATE
	border_priv.a = 0.6
	_add_border(_key_im, Vector3(priv_x, -panel_h * 0.5, 0.0), panel_w, panel_h, 0.003, border_priv)

	# Shared n bar (center, spanning both)
	var n_bar_col := COL_COMPUTE
	n_bar_col.a = 0.25
	var n_bar_w := panel_w * 2.0 + gap
	_add_quad_local(_key_im, Vector3(-panel_w - gap * 0.5, -panel_h * 0.5 - 0.04, -0.001),
		Vector3(n_bar_w, 0, 0), Vector3(0, 0.03, 0), n_bar_col)

	_key_im.surface_end()

# ── rebuild: modular exponentiation tree ─────────────────────────────
func _rebuild_tree() -> void:
	_tree_im.clear_surfaces()
	if _modexp_steps.is_empty():
		return

	_tree_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var step_count := _modexp_steps.size()
	var node_r := 0.012
	var spacing_y := 0.035
	var tree_h := step_count * spacing_y

	# Background
	var bg_col := COL_GRID_BG
	_add_quad_local(_tree_im, Vector3(-0.08, -tree_h * 0.5 - 0.02, -0.001),
		Vector3(0.16, 0, 0), Vector3(0, tree_h + 0.04, 0), bg_col)

	for i in range(step_count):
		var step : Dictionary = _modexp_steps[i]
		var y_pos := tree_h * 0.5 - i * spacing_y
		var is_sq := step["op"] == "sq"
		var x_off := -0.03 if is_sq else 0.03

		# Color by operation type
		var node_col : Color
		if is_sq:
			node_col = COL_COMPUTE  # yellow for squaring
		else:
			node_col = COL_PUBLIC   # green for multiply

		# Animate: fade in based on progress
		var active_step := _enc_step if _phase == 2 else _dec_step
		var progress := _enc_progress if _phase == 2 else _dec_progress
		var reveal := clampf(float(i) / maxf(step_count, 1) - (1.0 - progress), -0.5, 1.0)
		node_col.a = clampf(reveal * 3.0 + 0.4, 0.2, 1.0)

		# Draw node circle (approximated with small quad)
		_add_quad_local(_tree_im, Vector3(x_off - node_r, y_pos - node_r, 0),
			Vector3(node_r * 2, 0, 0), Vector3(0, node_r * 2, 0), node_col)

		# Connection line to previous
		if i > 0:
			var prev_is_sq := _modexp_steps[i - 1]["op"] == "sq"
			var prev_x := -0.03 if prev_is_sq else 0.03
			var prev_y := tree_h * 0.5 - (i - 1) * spacing_y
			var line_col := COL_DIM
			line_col.a = node_col.a * 0.5
			_add_line_quad(_tree_im, Vector3(prev_x, prev_y, 0),
				Vector3(x_off, y_pos, 0), 0.002, line_col)

	_tree_im.surface_end()

# ── rebuild: encryption/decryption timeline ──────────────────────────
func _rebuild_timeline() -> void:
	_timeline_im.clear_surfaces()
	if _phase < 2:
		return

	_timeline_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var char_count := _plain_nums.size()
	var slot_w := 0.09
	var slot_h := 0.06
	var gap := 0.015
	var total_w := char_count * (slot_w + gap) - gap
	var start_x := -total_w * 0.5
	var row_spacing := 0.085

	# Three rows: plaintext (top), ciphertext (mid), decrypted (bottom)
	# Row labels
	# Plaintext row — blue
	for i in range(char_count):
		var x := start_x + i * (slot_w + gap)
		var y_top := row_spacing

		# Plaintext cell
		var p_col := COL_PLAIN
		p_col.a = 0.75
		_add_quad_local(_timeline_im, Vector3(x, y_top, 0),
			Vector3(slot_w, 0, 0), Vector3(0, slot_h, 0), p_col)

		# Ciphertext cell
		var c_col := COL_CIPHER
		var encrypted := (_phase >= 2 and i < _enc_step) or (_phase >= 3)
		if not encrypted and _phase == 2 and i == _enc_step:
			# Currently encrypting — pulse
			var pulse := _enc_progress
			c_col = COL_PLAIN.lerp(COL_CIPHER, pulse)
			c_col.a = 0.5 + pulse * 0.4
		elif encrypted:
			c_col.a = 0.75
		else:
			c_col.a = 0.2
		_add_quad_local(_timeline_im, Vector3(x, 0.0, 0),
			Vector3(slot_w, 0, 0), Vector3(0, slot_h, 0), c_col)

		# Arrow between plain and cipher
		if encrypted or (_phase == 2 and i == _enc_step):
			var arrow_col := COL_COMPUTE
			arrow_col.a = 0.5
			_add_line_quad(_timeline_im,
				Vector3(x + slot_w * 0.5, y_top, 0),
				Vector3(x + slot_w * 0.5, slot_h, 0),
				0.003, arrow_col)

		# Decrypted cell
		var d_col := COL_PLAIN
		var decrypted := (_phase >= 3 and i < _dec_step) or _phase >= 4
		if not decrypted and _phase == 3 and i == _dec_step:
			var pulse := _dec_progress
			d_col = COL_CIPHER.lerp(COL_PLAIN, pulse)
			d_col.a = 0.5 + pulse * 0.4
		elif decrypted:
			d_col.a = 0.75
			# Flash green if matches original
			if i < _decrypt_nums.size() and i < _plain_nums.size():
				if _decrypt_nums[i] == _plain_nums[i]:
					d_col = COL_PUBLIC
					d_col.a = 0.8
		else:
			d_col.a = 0.2
		_add_quad_local(_timeline_im, Vector3(x, -row_spacing, 0),
			Vector3(slot_w, 0, 0), Vector3(0, slot_h, 0), d_col)

		# Arrow between cipher and decrypted
		if decrypted or (_phase == 3 and i == _dec_step):
			var arrow_col2 := COL_COMPUTE
			arrow_col2.a = 0.5
			_add_line_quad(_timeline_im,
				Vector3(x + slot_w * 0.5, 0.0, 0),
				Vector3(x + slot_w * 0.5, -row_spacing + slot_h, 0),
				0.003, arrow_col2)

	_timeline_im.surface_end()

# ── label updates ────────────────────────────────────────────────────
func _update_labels() -> void:
	match _phase:
		0:
			_phase_label.text = "Searching for primes..."
			var found := ""
			if _prime_p > 0:
				found = "p = %d" % _prime_p
			if _prime_q > 0:
				found += "  q = %d" % _prime_q
			_key_label.text = found if found != "" else "Scanning %d..." % (_grid_start + _search_idx)
			_formula_label.text = "Testing primality"
			_step_label.text = "Grid: %d – %d | Scanned: %d/%d" % [
				_grid_start, _grid_start + GRID_COLS * GRID_ROWS - 1,
				_search_idx, GRID_COLS * GRID_ROWS]
		1:
			_phase_label.text = "Key Generation Complete"
			_key_label.text = "Public (e,n) = (%d, %d)  |  Private (d,n) = (%d, %d)" % [_e, _n, _d, _n]
			_formula_label.text = "n = p*q = %d*%d = %d   phi = %d" % [_prime_p, _prime_q, _n, _phi]
			_step_label.text = "p = %d (prime)  q = %d (prime)  e = %d  d = e^-1 mod phi = %d" % [_prime_p, _prime_q, _e, _d]
		2:
			var ch := _message[_enc_step] if _enc_step < _message.length() else "?"
			_phase_label.text = "Encrypting: '%s'  [%d/%d]" % [_message, _enc_step + 1, _plain_nums.size()]
			_key_label.text = "C = M^e mod n  |  '%s' (%d) ^ %d mod %d" % [ch, _plain_nums[_enc_step] if _enc_step < _plain_nums.size() else 0, _e, _n]
			_formula_label.text = "Repeated squaring"
			_step_label.text = "Using PUBLIC key (e=%d)" % _e
			_step_label.modulate = COL_PUBLIC
		3:
			var idx := mini(_dec_step, _cipher_nums.size() - 1)
			_phase_label.text = "Decrypting  [%d/%d]" % [_dec_step + 1, _cipher_nums.size()]
			_key_label.text = "M = C^d mod n  |  %d ^ %d mod %d" % [_cipher_nums[idx] if idx >= 0 else 0, _d, _n]
			_formula_label.text = "Repeated squaring"
			_step_label.text = "Using PRIVATE key (d=%d)" % _d
			_step_label.modulate = COL_PRIVATE
		4:
			_phase_label.text = "Decryption Complete!"
			var decrypted_msg := ""
			for dn in _decrypt_nums:
				decrypted_msg += char(dn)
			_key_label.text = "'%s' -> encrypt -> decrypt -> '%s'" % [_message, decrypted_msg]
			var match_ok := (decrypted_msg == _message)
			_formula_label.text = "Match: %s" % ("YES" if match_ok else "NO")
			_formula_label.modulate = COL_PUBLIC if match_ok else COL_PRIVATE
			_step_label.text = "Restarting in %.0fs..." % maxf(5.0 - _phase_timer, 0.0)
			_step_label.modulate = COL_DIM

# ── geometry helpers ─────────────────────────────────────────────────
func _add_quad_local(im: ImmediateMesh, origin: Vector3, right: Vector3, up: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_add_vertex(origin)
	im.surface_add_vertex(origin + right)
	im.surface_add_vertex(origin + right + up)
	im.surface_add_vertex(origin)
	im.surface_add_vertex(origin + right + up)
	im.surface_add_vertex(origin + up)

func _add_line_quad(im: ImmediateMesh, a: Vector3, b: Vector3, width: float, col: Color) -> void:
	var dir := (b - a).normalized()
	var perp := Vector3(-dir.y, dir.x, 0).normalized() * width * 0.5
	if perp.length() < 0.0001:
		perp = Vector3(width * 0.5, 0, 0)
	im.surface_set_color(col)
	im.surface_add_vertex(a - perp)
	im.surface_add_vertex(b - perp)
	im.surface_add_vertex(b + perp)
	im.surface_add_vertex(a - perp)
	im.surface_add_vertex(b + perp)
	im.surface_add_vertex(a + perp)

func _add_border(im: ImmediateMesh, origin: Vector3, w: float, h: float, thickness: float, col: Color) -> void:
	# Bottom
	_add_quad_local(im, origin, Vector3(w, 0, 0), Vector3(0, thickness, 0), col)
	# Top
	_add_quad_local(im, origin + Vector3(0, h - thickness, 0), Vector3(w, 0, 0), Vector3(0, thickness, 0), col)
	# Left
	_add_quad_local(im, origin, Vector3(thickness, 0, 0), Vector3(0, h, 0), col)
	# Right
	_add_quad_local(im, origin + Vector3(w - thickness, 0, 0), Vector3(thickness, 0, 0), Vector3(0, h, 0), col)

# ── math utilities ───────────────────────────────────────────────────
func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a

func _mod_inverse(a: int, m: int) -> int:
	var m0 := m
	var x0 := 0
	var x1 := 1
	if m == 1:
		return 0
	while a > 1:
		var q := a / m
		var t := m
		m = a % m
		a = t
		t = x0
		x0 = x1 - q * x0
		x1 = t
	if x1 < 0:
		x1 += m0
	return x1

func _mod_exp(base_val: int, exp_val: int, mod_val: int) -> int:
	if mod_val <= 1:
		return 0
	var result := 1
	var b := base_val % mod_val
	var ex := exp_val
	while ex > 0:
		if ex % 2 == 1:
			result = (result * b) % mod_val
		ex >>= 1
		b = (b * b) % mod_val
	return result

# ── apply_grid_config ────────────────────────────────────────────────
func apply_grid_config(config: Dictionary) -> void:
	if config.has("message_index"):
		var idx := clampi(int(config.message_index), 0, 4)
		_pick_message_by_index(idx)
		if _msg_ctrl:
			_msg_ctrl.set_value(float(idx))
	if config.has("prime_range"):
		var idx := clampi(int(config.prime_range), 0, 3)
		_set_prime_range(idx)
		if _prime_ctrl:
			_prime_ctrl.set_value(float(idx))
	if config.has("animation_speed"):
		_anim_speed = clampf(float(config.animation_speed), 0.2, 3.0)
		if _speed_ctrl:
			_speed_ctrl.set_value(_anim_speed)
	_restart()
