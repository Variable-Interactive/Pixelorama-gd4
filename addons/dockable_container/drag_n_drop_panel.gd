@tool
extends Control

const MARGIN_NONE = -1
enum {MARGIN_LEFT, MARGIN_RIGHT, MARGIN_TOP, MARGIN_BOTTOM}

var _hover_margin = MARGIN_NONE
var _should_split = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover_margin = MARGIN_NONE
	elif what == NOTIFICATION_DRAG_BEGIN:
		_hover_margin = MARGIN_NONE


func _gui_input(event: InputEvent) -> void:
	if _should_split and event is InputEventMouseMotion:
		_find_hover_margin(event.position)
		queue_redraw()


func _draw() -> void:
	var rect
	if _hover_margin == MARGIN_NONE:
		return
	elif _hover_margin == MARGIN_LEFT:
		rect = Rect2(0, 0, size.x * 0.5, size.y)
	elif _hover_margin == MARGIN_TOP:
		rect = Rect2(0, 0, size.x, size.y * 0.5)
	elif _hover_margin == MARGIN_RIGHT:
		var half_width = size.x * 0.5
		rect = Rect2(half_width, 0, half_width, size.y)
	elif _hover_margin == MARGIN_BOTTOM:
		var half_height = size.y * 0.5
		rect = Rect2(0, half_height, size.x, half_height)
	var stylebox = get_theme_stylebox("panel", "TooltipPanel")
	draw_style_box(stylebox, rect)


func set_enabled(enabled: bool, should_split: bool = true) -> void:
	visible = enabled
	_should_split = should_split
	if enabled:
		_hover_margin = MARGIN_NONE
		queue_redraw()


func get_hover_margin() -> int:
	return _hover_margin


func _find_hover_margin(point: Vector2):
	var half_size = size * 0.5

	var left = point.distance_squared_to(Vector2(0, half_size.y))
	var lesser = left
	var lesser_margin = MARGIN_LEFT

	var top = point.distance_squared_to(Vector2(half_size.x, 0))
	if lesser > top:
		lesser = top
		lesser_margin = MARGIN_TOP

	var right = point.distance_squared_to(Vector2(size.x, half_size.y))
	if lesser > right:
		lesser = right
		lesser_margin = MARGIN_RIGHT

	var bottom = point.distance_squared_to(Vector2(half_size.x, size.y))
	if lesser > bottom:
		#lesser = bottom  # unused result
		lesser_margin = MARGIN_BOTTOM
	_hover_margin = lesser_margin
