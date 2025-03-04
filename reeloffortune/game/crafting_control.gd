class_name CraftingControl
extends Control

var x_open: float
var x_close: float

func _ready() -> void:
	x_close = global_position.x
	x_open = x_close - $PanelContainer.get_rect().size.x
	print(x_open, " - close ", x_close)

func set_open(is_open: bool) -> void:
	var target_pos = Vector2(x_open, 0.0) if is_open else Vector2(x_close, 0.0)
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT)
