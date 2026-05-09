extends Control

var serial: GdSerial
var timer := 0.0

func _ready():
	serial = GdSerial.new()
	print(serial.list_ports())
	serial.set_port("COM5")
	serial.set_baud_rate(115200)
	if !serial.open():
		print("Failed to open port")

func _process(delta):
	timer += delta
	if timer >= 1.0:
		timer = 0.0
		if serial.is_open():
			serial.writeline("Ping")
	var response = serial.readline()
	if response != "":
		print(response)

func _exit_tree():
	if serial and serial.is_open():
		serial.close()
