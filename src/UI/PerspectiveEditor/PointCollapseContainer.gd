extends Button

# This is NOT related to the CollapsibleContainer class (though it behaves similarly)
# i did it like this because the "Content" is part of a different node
@export var point_text := "" : set = _set_text
@export var visible_content := false : set = _set_visible_content
@onready var content = $"%Content"


func _ready() -> void:
	_set_visible(button_pressed)
	content.connect("visibility_changed",Callable(self,"_child_visibility_changed"))


func _set_text(value: String) -> void:
	$Label.text = value
	custom_minimum_size = $Label.size


func _set_visible_content(value: bool) -> void:
	visible_content = value
	button_pressed = value


func _on_Button_toggled(press_state: bool) -> void:
	_set_visible(press_state)


func _set_visible(press_state: bool) -> void:
	if press_state:
		$TextureRect.rotation = 0
	else:
		$TextureRect.rotation = -90
	content.visible = press_state


# Checks if a child becomes visible from another source and ensures
# it remains invisible if the button is not pressed
func _child_visibility_changed() -> void:
	if not button_pressed:
		content.visible = false
