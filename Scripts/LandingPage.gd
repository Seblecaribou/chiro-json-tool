class_name LandingPage
extends Control

signal category_selected(category: String)

@onready var quest_button = $VBoxContainer/QuestButton
@onready var dialogue_button = $VBoxContainer/DialogueButton
@onready var object_button = $VBoxContainer/ItemButton

func _ready():
	quest_button.pressed.connect(func():
		emit_signal("category_selected", "quest")
	)

	dialogue_button.pressed.connect(func():
		emit_signal("category_selected", "dialogue")
	)

	object_button.pressed.connect(func():
		emit_signal("category_selected", "object")
	)
