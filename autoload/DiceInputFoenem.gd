extends Node
# to get if its rolling, use DiceInputFoenem.rolling
# to get the result, use
# if !DiceInputFoenem.Rolling, DiceInputFoenem.current_face
# && current_face != -1

signal roll_started
signal face_settled(face: int)

var serial: GdSerial

var read_timer := 0.0
const READ_INTERVAL := 1.0 / 30.0
var serial_buffer := ""
var current_face := -1
var rolling := false
var face_count := 0
var temp_face := 0
var port_name: String = ""
var connected: bool = false
var bt_val


func _ready():
	serial = GdSerial.new()
	print(serial.list_ports())
	port_name = _resolve_port()
	if port_name == "":
		print("[DiceInputFoenem] No port configured — keyboard fallback only.")
		return
	_open_port(port_name)


func _resolve_port() -> String:
	# Prefer the user-configured port (from the Settings screen).
	var configured: String = ""
	if Engine.has_singleton("SettingsGlobal") or has_node("/root/SettingsGlobal"):
		var sg = get_node_or_null("/root/SettingsGlobal")
		if sg and sg.settings is Dictionary:
			configured = String(sg.settings.get("use_port", "")).strip_edges()
	if configured != "":
		return configured
	# Last-resort default — Windows COM5 like the original code.
	return "COM5"


func _open_port(p: String):
	serial.set_port(p)
	serial.set_baud_rate(115200)
	if serial.open():
		connected = true
		port_name = p
		print("[DiceInputFoenem] Serial opened on ", p)
	else:
		connected = false
		print("[DiceInputFoenem] Failed to open port ", p)


func reconnect(new_port: String = ""):
	if serial and serial.is_open():
		serial.close()
		connected = false
	var target = new_port if new_port != "" else _resolve_port()
	if target == "":
		return
	_open_port(target)


func _process(delta):
	read_timer += delta
	if read_timer >= READ_INTERVAL:
		read_timer = 0.0
		read_serial()


func read_serial():
	if !serial:
		return
	if !serial.is_open():
		return
	while serial.bytes_available() > 0:
		var line = serial.readline().strip_edges()
		if line == "":
			continue
		parse_serial(line)


func parse_serial(line: String):
	if line == "rol":
		if !rolling:
			rolling = true
			print("Rolling...")
			current_face = -1
			roll_started.emit()
		face_count = 0
		temp_face = 0
		return
	if line.begins_with("df"):
		rolling = false
		var face_text := line.substr(3)
		if face_text.is_valid_int():
			var face := face_text.to_int()
			if face != temp_face:
				temp_face = face
				face_count = 1
			else:
				face_count += 1
			if face_count >= 10 and temp_face != current_face:
				current_face = temp_face
				print("Dice face: ", str(current_face))
				face_settled.emit(current_face)
		return
	if line.begins_with("bt"):
		
		if line.substr(2).is_valid_int(): bt_val = line.substr(2)
	
	print("Unknown serial message: ", line)


func _exit_tree():
	if serial and serial.is_open():
		serial.close() #haha theres 67 lines of code im so mature
