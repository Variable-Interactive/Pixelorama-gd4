extends Control

const EXTENSIONS_PATH := "user://extensions"

var extensions := {}  # Extension name : Extension class
var extension_selected := -1
var damaged_extension: String

@onready var extension_list: ItemList = $InstalledExtensions
@onready var enable_button: Button = $HBoxContainer/EnableButton
@onready var uninstall_button: Button = $HBoxContainer/UninstallButton
@onready var extension_parent: Node = Global.control.get_node("Extensions")


class Extension:
	var file_name := ""
	var display_name := ""
	var description := ""
	var author := ""
	var version := ""
	var license := ""
	var nodes := []
	var enabled := false

	func serialize(dict: Dictionary) -> void:
		if dict.has("name"):
			file_name = dict["name"]
		if dict.has("display_name"):
			display_name = dict["display_name"]
		if dict.has("description"):
			description = dict["description"]
		if dict.has("author"):
			author = dict["author"]
		if dict.has("version"):
			version = dict["version"]
		if dict.has("license"):
			license = dict["license"]
		if dict.has("nodes"):
			nodes = dict["nodes"]


func _ready() -> void:
	if OS.get_name() == "HTML5":
		$HBoxContainer/AddExtensionButton.disabled = true
		$HBoxContainer/OpenFolderButton.visible = false

	var file_names := []  # Array of String(s)
	DirAccess.make_dir_absolute(EXTENSIONS_PATH)
	var dir := DirAccess.open(EXTENSIONS_PATH)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = dir.get_next()
		while file_name != "":
			var ext: String = file_name.to_lower().get_extension()
			if !dir.current_is_dir() and ext in ["pck", "zip"]:
				file_names.append(file_name)
			file_name = dir.get_next()

	if file_names.is_empty():
		return

	for file_name in file_names:
		_add_extension(file_name)


func install_extension(path: String) -> void:
	var file_name: String = path.get_file()
	DirAccess.copy_absolute(path, EXTENSIONS_PATH.path_join(file_name))
	_add_extension(file_name)


func _uninstall_extension(file_name := "", remove_file := true, item := extension_selected) -> void:
	if remove_file:
		var err = DirAccess.remove_absolute(EXTENSIONS_PATH.path_join(file_name))
		if err != OK:
			print(err)
			return

	var extension: Extension = extensions[file_name]
	extension.enabled = false
	_enable_extension(extension, false)

	extensions.erase(file_name)
	extension_list.remove_item(item)
	extension_selected = -1
	enable_button.disabled = true
	uninstall_button.disabled = true


func _add_extension(file_name: String) -> void:
	var tester_file: FileAccess  # For testing and deleting damaged extensions
	# Remove any extension that was proven guilty before this extension is loaded
	if FileAccess.file_exists(EXTENSIONS_PATH.path_join("Faulty.txt")):
		# This code will only run if pixelorama crashed
		var faulty_path = EXTENSIONS_PATH.path_join("Faulty.txt")
		tester_file = FileAccess.open(faulty_path, FileAccess.READ)
		damaged_extension = tester_file.get_as_text()
		tester_file.close()
		DirAccess.remove_absolute(EXTENSIONS_PATH.path_join(damaged_extension))
		DirAccess.remove_absolute(EXTENSIONS_PATH.path_join("Faulty.txt"))

	# Don't load a deleted extension
	if damaged_extension == file_name:
		# This code will only run if pixelorama crashed
		damaged_extension = ""
		return

	# The new (about to load) extension will be considered guilty till it's proven innocent
	tester_file = FileAccess.open(EXTENSIONS_PATH.path_join("Faulty.txt"), FileAccess.WRITE)
	tester_file.store_string(file_name)  # Guilty till proven innocent ;)
	tester_file.close()

	if extensions.has(file_name):
		var item := -1
		for i in extension_list.get_item_count():
			if extension_list.get_item_metadata(i) == file_name:
				item = i
				break
		if item == -1:
			print("Failed to find %s" % file_name)
			return
		_uninstall_extension(file_name, false, item)
		# Wait two frames so the previous nodes can get freed
		await get_tree().process_frame
		await get_tree().process_frame

	var file_name_no_ext: String = file_name.get_basename()
	var file_path: String = EXTENSIONS_PATH.path_join(file_name)
	var success := ProjectSettings.load_resource_pack(file_path)
	if !success:
		print("Failed loading resource pack.")
		DirAccess.remove_absolute(file_path)
		return

	var extension_path: String = "res://src/Extensions/%s/" % file_name_no_ext
	var extension_config_file_path: String = extension_path.path_join("extension.json")
	var extension_config_file := FileAccess.open(extension_config_file_path, FileAccess.READ)
	var err = FileAccess.get_open_error()
	if err != OK:
		print("Error loading config file: ", err)
		extension_config_file.close()
		return

	var test_json_conv = JSON.new()
	test_json_conv.parse(extension_config_file.get_as_text())
	var extension_json = test_json_conv.get_data()
	extension_config_file.close()

	if !extension_json:
		print("No JSON data found.")
		return

	if extension_json.has("supported_api_versions"):
		var supported_api_versions = extension_json["supported_api_versions"]
		if typeof(supported_api_versions) == TYPE_ARRAY:
			if !ExtensionsApi.get_api_version() in supported_api_versions:
				var err_text = (
					"The extension %s will not work on this version of Pixelorama \n"
					% file_name_no_ext
				)
				var required_text = "Requires Api : %s" % str(supported_api_versions)
				Global.error_dialog.set_text(str(err_text, required_text))
				Global.error_dialog.popup_centered()
				Global.dialog_open(true)
				print("Incompatible API")
				# Don't put it in faulty, (it's merely incompatible)
				DirAccess.remove_absolute(EXTENSIONS_PATH.path_join("Faulty.txt"))
				return

	var extension := Extension.new()
	extension.serialize(extension_json)
	extensions[file_name] = extension
	extension_list.add_item(extension.display_name)
	var item_count: int = extension_list.get_item_count() - 1
	extension_list.set_item_tooltip(item_count, extension.description)
	extension_list.set_item_metadata(item_count, file_name)
	extension.enabled = Global.config_cache.get_value("extensions", extension.file_name, false)
	if extension.enabled:
		_enable_extension(extension)

	# If an extension doesn't crash pixelorama then it is proven innocent
	# And we should now delete it's "Faulty.txt" file
	DirAccess.remove_absolute(EXTENSIONS_PATH.path_join("Faulty.txt"))


func _enable_extension(extension: Extension, save_to_config := true) -> void:
	var extension_path: String = "res://src/Extensions/%s/" % extension.file_name

	# A unique id for the extension (currently set to file_name). More parameters (version etc.)
	# can be easily added using the str() function. for example
	# var id: String = str(extension.file_name, extension.version)
	var id: String = extension.file_name

	if extension.enabled:
		ExtensionsApi.clear_history(extension.file_name)
		for node in extension.nodes:
			var scene_path: String = extension_path.path_join(node)
			var extension_scene: PackedScene = load(scene_path)
			if extension_scene:
				var extension_node: Node = extension_scene.instantiate()
				extension_parent.add_child(extension_node)
				extension_node.add_to_group(id)  # Keep track of what to remove later
			else:
				print("Failed to load extension %s" % id)
	else:
		for ext_node in extension_parent.get_children():
			if ext_node.is_in_group(id):  # Node for extension found
				extension_parent.remove_child(ext_node)
				ext_node.queue_free()
		ExtensionsApi.check_sanity(extension.file_name)

	if save_to_config:
		Global.config_cache.set_value("extensions", extension.file_name, extension.enabled)
		Global.config_cache.save("user://cache.ini")


func _on_InstalledExtensions_item_selected(index: int) -> void:
	extension_selected = index
	var file_name: String = extension_list.get_item_metadata(extension_selected)
	var extension: Extension = extensions[file_name]
	if extension.enabled:
		enable_button.text = "Disable"
	else:
		enable_button.text = "Enable"
	enable_button.disabled = false
	uninstall_button.disabled = false


func _on_InstalledExtensions_empty_clicked(_at_position: Vector2, _mouse_button_index: int) -> void:
	enable_button.disabled = true
	uninstall_button.disabled = true


func _on_AddExtensionButton_pressed() -> void:
	Global.preferences_dialog.get_node("Popups/AddExtensionFileDialog").popup_centered()


func _on_EnableButton_pressed() -> void:
	var file_name: String = extension_list.get_item_metadata(extension_selected)
	var extension: Extension = extensions[file_name]
	extension.enabled = !extension.enabled
	_enable_extension(extension)
	if extension.enabled:
		enable_button.text = "Disable"
	else:
		enable_button.text = "Enable"


func _on_UninstallButton_pressed() -> void:
	_uninstall_extension(extension_list.get_item_metadata(extension_selected))


func _on_OpenFolderButton_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(EXTENSIONS_PATH))


func _on_AddExtensionFileDialog_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		install_extension(path)


