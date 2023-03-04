@tool
extends Container

# Control that mimics its own visibility and rect into another Control.


signal moved_in_parent(control)

var reference_to: Control:
	get:
		# TODO: Manually copy the code from this method.
		return get_reference_to()
	set(value):
		# TODO: Manually copy the code from this method.
		set_reference_to(value)

var _reference_to: Control = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _reference_to:
		_reference_to.visible = visible
	elif what == NOTIFICATION_SORT_CHILDREN and _reference_to:
		_reposition_reference()


func _get_minimum_size() -> Vector2:
	return _reference_to.get_combined_minimum_size() if _reference_to else Vector2.ZERO


func set_reference_to(control: Control) -> void:
	if _reference_to != control:
		if _reference_to:
			_reference_to.disconnect("renamed", Callable(self, "_on_reference_to_renamed"))
		_reference_to = control
		emit_signal("minimum_size_changed")
		if not _reference_to:
			return
		_reference_to.connect("renamed", Callable(self, "_on_reference_to_renamed"))
		_reference_to.visible = visible


func get_reference_to() -> Control:
	return _reference_to


func _reposition_reference() -> void:
	_reference_to.global_position = global_position
	_reference_to.size = size


func _on_reference_to_renamed() -> void:
	name = _reference_to.name
