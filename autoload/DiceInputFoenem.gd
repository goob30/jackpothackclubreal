# Main.gd
extends Node

var serial: GdSerial

var read_timer := 0.0
const READ_INTERVAL := 1.0 / 30.0

var serial_buffer := ""

var current_face := -1
var rolling := false

func _ready():

	serial = GdSerial.new()

	print(serial.list_ports())

	serial.set_port("COM5")
	serial.set_baud_rate(115200)

	if serial.open():
		print("Serial opened")
	else:
		print("Failed to open port")


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
	print("raw: ", line)
	if line == "rol":
		if !rolling:
			rolling = true
			print("Rolling...")
		return

	if line.begins_with("df"):
		rolling = false
		var face_text := line.substr(2)
		if face_text.is_valid_int():
			var face := face_text.to_int()
			if face != current_face:
				current_face = face
				print("Dice face: ", current_face)
		return
	print("Unknown serial message: ", line)


func _exit_tree():
	if serial and serial.is_open():
		serial.close()
