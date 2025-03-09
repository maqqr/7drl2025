extends PanelContainer

@onready var game_manager: GameManager = $"/root/Game"

var journal_control: JournalControl

func _ready() -> void:
	journal_control = $"/root/Game/GUI/JournalControl"
	assert(journal_control)
	gui_input.connect(on_gui_input)

func on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if game_manager.allow_input_mode != GameManager.InputMode.NONE:
			if event.pressed and event.button_index == 1:
				journal_control.set_open(!journal_control.visible)
