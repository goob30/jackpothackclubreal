extends Control

var serial: GdSerial
var read_timer := 0.0
var serial_line := ""
var last_serial_line := ""
const READ_INTERVAL = 1.0 / 30.0  # 30Hz

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
	$Label.text = str(Engine.get_frames_per_second())
	read_timer += delta
	if read_timer >= READ_INTERVAL:
		read_timer = 0.0
		if serial and serial.is_open():
			if serial.bytes_available() > 0:
				serial_line = serial.readline().strip_edges()
				if serial_line != last_serial_line and serial_line != "":
					print("New data: ", serial_line)
					if serial_line == "act1":
						$Button.text = "Holy shit it works"
					
					if serial_line != last_serial_line:
						last_serial_line = serial_line
					$Label2.text = last_serial_line

func _on_button_pressed() -> void:
	if serial and serial.is_open():
		serial.writeline("led")

func _exit_tree():
	if serial and serial.is_open():
		serial.close()
