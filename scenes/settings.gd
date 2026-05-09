extends Control

var serial: GdSerial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	serial = GdSerial.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_scan_serial_button_pressed() -> void:
	if serial:
		var ports = serial.list_ports()
		var com_ports = []

		for key in ports.keys():
			var port_info = ports[key]
			com_ports.append(port_info["port_name"])
	
		if com_ports.size() > 0:
			$availabelComPortsLabel.text = "Ports: " + ", ".join(com_ports)
		else:
			$availabelComPortsLabel.text = "No COM ports found"
