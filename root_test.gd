extends Control

var serial: Object = null
var read_timer := 0.0
const READ_INTERVAL = 1.0 / 30.0  # 30Hz

var current_face := -1
var rolling := false
var face_count := 0
var temp_face := 0

func _ready():
	if not ClassDB.class_exists("GdSerial"):
		print("GdSerial unavailable (Web build)")
		return
	serial = ClassDB.instantiate("GdSerial")
	print(serial.list_ports())
	serial.set_port("COM5")
	serial.set_baud_rate(115200)
	if serial.open():
		print("Serial opened")
	else:
		print("Failed to open port")

func _process(delta):
	$Label.text = str(Engine.get_frames_per_second())
	read_timer += delta
	if read_timer >= READ_INTERVAL:
		read_timer = 0.0
		if serial != null and serial.is_open():
			while serial.bytes_available() > 0:
				var line = serial.readline().strip_edges()
				if line != "":
					parse_serial(line)

func parse_serial(line: String):
	if line == "rol":
		if !rolling:
			rolling = true
			print("Rolling...")
			current_face = -1  # Clear the locked-in face when rolling starts
		face_count = 0  # Reset counter while rolling
		temp_face = 0
		return
	if line.begins_with("df"):
		rolling = false                 
		var face_text := line.substr(3)
		
		if face_text.is_valid_int():
			var face := face_text.to_int()
			if face != temp_face:
				# New face detected, reset counter
				temp_face = face
				face_count = 1
			else:
				# Same face as temp, increment
				face_count += 1
			
			# Check if we've reached 10
			if face_count >= 10 and temp_face != current_face:
				current_face = temp_face
				print("Dice face: ", str(current_face))
		return
	print("Unknown serial message: ", line)

func _on_button_pressed() -> void:
	if serial != null and serial.is_open():
		serial.writeline("led")

func _exit_tree():
	if serial != null and serial.is_open():
		serial.close()
