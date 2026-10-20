extends Node
## One physical-source seed, on demand. Never substitutes a local random value.
## https://www.random.org/clients/http/api/ and /clients/ describe this interface.
signal received(seed_number: int, receipt: Dictionary)
signal status_changed(message: String)

const SEED_MAX := 999
const QUOTA_URL := "https://www.random.org/quota/?format=plain"
const NUMBER_URL := "https://www.random.org/integers/?num=1&min=0&max=999&col=1&base=10&format=plain&rnd=new"
# Shared across benches and room unloads within this application session.
static var _active_id: int = 0
static var _retry_after_msec: int = 0
var _http: HTTPRequest
var _phase: String = ""

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 120.0
	_http.body_size_limit = 4096
	_http.use_threads = true
	add_child(_http)
	_http.request_completed.connect(_completed)

func is_busy() -> bool:
	return not _phase.is_empty()

func request_seed() -> bool:
	if _active_id != 0:
		status_changed.emit("Already asking RANDOM.ORG — please wait")
		return false
	var wait_ms := _retry_after_msec - Time.get_ticks_msec()
	if wait_ms > 0:
		status_changed.emit("Try again in %d s — current seed kept" % ceili(wait_ms / 1000.0))
		return false
	_active_id = get_instance_id()
	_phase = "quota"
	status_changed.emit("Asking RANDOM.ORG — current seed kept until it arrives")
	_send(QUOTA_URL)
	return true

func _send(url: String) -> void:
	var agent := "AdaResearch/1.0 (Endless Museum seed exhibit)"
	# A project owner can supply a public maintenance contact; no account data is read.
	var contact := str(ProjectSettings.get_setting("ada/random_org/contact", ""))
	if not contact.is_empty() and not contact.contains("\n") and not contact.contains("\r"):
		agent += " " + contact
	var error := _http.request(url, PackedStringArray(["Accept: text/plain", "User-Agent: " + agent]))
	if error != OK:
		_fail("Could not start request — current seed kept")

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _phase.is_empty(): return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("RANDOM.ORG unavailable — current seed kept")
		return
	var value := body.get_string_from_utf8().strip_edges()
	if value.length() > 12 or not value.is_valid_int():
		_fail("Unexpected reply — current seed kept")
		return
	var number := int(value)
	if _phase == "quota":
		if number < 0:
			_fail("RANDOM.ORG quota empty — try again in 10 minutes", 600)
			return
		_phase = "number"
		_send(NUMBER_URL)
		return
	if number < 0 or number > SEED_MAX:
		_fail("Number outside 0–999 — current seed kept")
		return
	_finish(5)
	received.emit(number, {
		"provider": "RANDOM.ORG", "source": "atmospheric noise",
		"seed": number, "minimum": 0, "maximum": SEED_MAX,
		"received_utc": Time.get_datetime_string_from_system(true) + "Z",
		"url": NUMBER_URL,
	})

func _fail(message: String, delay_seconds: int = 60) -> void:
	_finish(delay_seconds)
	status_changed.emit(message)

func _finish(delay_seconds: int) -> void:
	_phase = ""
	if _active_id == get_instance_id(): _active_id = 0
	_retry_after_msec = Time.get_ticks_msec() + delay_seconds * 1000

func _exit_tree() -> void:
	if _active_id == get_instance_id():
		_http.cancel_request()
		_finish(5)
