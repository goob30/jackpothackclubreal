extends Control

var serial: Object = null  # GdSerial on native; null on Web (extension unavailable).

var lastScene = ""
var settingsDict = {}

func _ready() -> void:

	if ClassDB.class_exists("GdSerial"):
		serial = ClassDB.instantiate("GdSerial")
	$Control/musicVolumeSlider.value = SettingsGlobal.settings.get("music_vol")
	$Control/sfxVolSlider.value = SettingsGlobal.settings.get("sfx_vol")
	# Restore saved port and wire submit -> save + reconnect
	$Control/comPortSelect.text = String(SettingsGlobal.settings.get("use_port", ""))
	if not $Control/comPortSelect.text_submitted.is_connected(_on_com_port_submitted):
		$Control/comPortSelect.text_submitted.connect(_on_com_port_submitted)
	# Show currently-connected port if dice autoload is up
	if has_node("/root/DiceInputFoenem"):
		var dpn = DiceInputFoenem.port_name
		var dcon = DiceInputFoenem.connected
		$Control/availabelComPortsLabel.text = "Active: %s %s" % [dpn, "(connected)" if dcon else "(not connected)"]


func _on_com_port_submitted(new_port: String) -> void:
	var clean := new_port.strip_edges()
	SettingsGlobal.settings.set("use_port", clean)
	print("[Settings] Saved port: ", clean)
	if has_node("/root/DiceInputFoenem"):
		DiceInputFoenem.reconnect(clean)
		var dcon = DiceInputFoenem.connected
		$Control/availabelComPortsLabel.text = "Active: %s %s" % [clean, "(connected)" if dcon else "(failed)"]

func _process(delta: float) -> void:
	pass

func _on_scan_serial_button_pressed() -> void:
	if serial == null:
		$Control/availabelComPortsLabel.text = "Serial not available in this build"
		return
	var ports = serial.list_ports()
	var com_ports: Array = []
	var auto_pick: String = ""
	for key in ports.keys():
		var port_info = ports[key]
		var pname = String(port_info.get("port_name", ""))
		if pname == "":
			continue
		com_ports.append(pname)
		if auto_pick == "" and (pname.begins_with("/dev/ttyUSB") or pname.begins_with("/dev/ttyACM")):
			auto_pick = pname
	if com_ports.is_empty():
		$Control/availabelComPortsLabel.text = "No ports found"
		return
	var listing = "Ports: " + ", ".join(com_ports)
	# Auto-pick the first USB-serial device, save it, and reconnect.
	if auto_pick != "":
		$Control/comPortSelect.text = auto_pick
		SettingsGlobal.settings.set("use_port", auto_pick)
		if has_node("/root/DiceInputFoenem"):
			DiceInputFoenem.reconnect(auto_pick)
			var status = "(connected)" if DiceInputFoenem.connected else "(failed)"
			listing += "\nActive: %s %s" % [auto_pick, status]
		print("[Settings] Auto-picked port: ", auto_pick)
	$Control/availabelComPortsLabel.text = listing


func _on_back_button_pressed() -> void:
	self.visible = false


func _on_music_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		SettingsGlobal.settings.set("music_vol", $Control/musicVolumeSlider.value)
		print(SettingsGlobal.settings.get("music_vol"))


func _on_sfx_vol_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		SettingsGlobal.settings.set("sfx_vol", $Control/sfxVolSlider.value)
		print(SettingsGlobal.settings.get("sfx_vol"))
