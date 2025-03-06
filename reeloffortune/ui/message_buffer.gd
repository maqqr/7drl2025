class_name MessageBuffer
extends Control

const SHOW_MESSAGE_TIME = 8
const FADE_DELAY = 0.07

const MSG_LEARN: String = "[i]You learn that {item} breaks down into {result}![/i]"
const MSG_NO_BITE: String = "[i]Hmm. No bite.[/i]"
const MSG_NO_BAIT: String = "[i]You need to equip a bait to catch anything.[/i]"
const MSG_NO_ROD: String = "[i]You need to equip a fishing rod first.[/i]"
const MSG_CATCH: String = "[i]You catch a {fish}![/i]"
const MSG_CATCH_FAIL: String = "[i]The fish got away.[/i]"
const MSG_EAT: String = "[i]You eat the {item}. {msg}[/i]"
const MSG_EAT_FAIL: String = "[i]You can not eat that.[/i]"
const MSG_PICKUP: String = "[i]You pick up {a} {item}.[/i]"

func add_message(msg: String) -> void:
	var line = preload("res://ui/message_line.tscn").instantiate()
	line.text = msg
	$VBoxContainer.add_child(line)
	
	var tween = get_tree().create_tween()
	tween.tween_interval(SHOW_MESSAGE_TIME)
	tween.tween_property(line, "self_modulate", Color(0.7, 0.7, 0.7), 0.0)
	tween.tween_interval(FADE_DELAY)
	tween.tween_property(line, "self_modulate", Color(0.4, 0.4, 0.4), 0.0)
	tween.tween_interval(FADE_DELAY)
	tween.tween_property(line, "self_modulate", Color(0.1, 0.1, 0.1), 0.0)
	tween.tween_interval(FADE_DELAY)
	tween.tween_property(line, "self_modulate", Color(0.0, 0.0, 0.0, 0.0), 0.0)

	tween.tween_property(line, "custom_minimum_size:y", 0.0, 0.3)
	tween.tween_callback(line.queue_free)
