extends Control

var serial: GdSerial

var lastScene = ""
var settingsDict = {}

func _ready() -> void:
	serial = GdSerial.new()
	$musicVolumeSlider.value = SettingsGlobal.settings.get("music_vol")
	$sfxVolSlider.value = SettingsGlobal.settings.get("sfx_vol")

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


func _on_back_button_pressed() -> void:
	pass


func _on_music_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		SettingsGlobal.settings.set("music_vol", $musicVolumeSlider.value)
		print(SettingsGlobal.settings.get("music_vol"))


func _on_sfx_vol_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		SettingsGlobal.settings.set("sfx_vol", $sfxVolSlider.value)
		print(SettingsGlobal.settings.get("sfx_vol"))
