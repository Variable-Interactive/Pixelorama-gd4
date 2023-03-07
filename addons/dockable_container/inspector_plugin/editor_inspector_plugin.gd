extends EditorInspectorPlugin

const DockableContainer = preload("../dockable_container.gd")
const LayoutEditorProperty = preload("layout_editor_property.gd")

func _can_handle(object: Object) -> bool:
	return object is DockableContainer


func _parse_property(object: Object, type: Variant.Type, path: String, hint: PropertyHint, hint_text: String, usage: PropertyUsageFlags, wide: bool) -> bool:
	if path == "layout":
		var editor_property = LayoutEditorProperty.new()
		add_property_editor("layout", editor_property)
	return false
