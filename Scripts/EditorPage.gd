class_name EditorPage
extends Control

signal export_requested(data: Dictionary)
signal load_requested(schema_path: Dictionary)
signal back_requested()
@onready var back_button = $VBoxContainer/Header/BackButton
@onready var category_label = $VBoxContainer/Header/Label
@onready var load_button = $VBoxContainer/Header/LoadButton
@onready var save_button = $VBoxContainer/Header/SaveButton
@onready var export_button = $VBoxContainer/Header/ExportButton
@onready var form_root = $VBoxContainer/ScrollContainer/VBoxContainer
var current_schema : Dictionary = {}

func _ready():
	back_button.pressed.connect(func(): emit_signal("back_requested"))
	load_button.pressed.connect(_on_load_pressed)
	export_button.pressed.connect(_on_export_button_pressed)


#region Functions
func build_from_schema(schema: Dictionary) -> void:
	current_schema = schema
	_clear_form()
	_build_node(schema, form_root)
	
func _clear_form():
	for child in form_root.get_children():
		child.queue_free()

func _extract_object(container: Control) -> Dictionary:
	var result := {}

	for child in container.get_children():
		if not child.has_meta("json_type"):
			continue

		var type = child.get_meta("json_type")

		match type:
			"string":
				var child_name = child.get_meta("json_name")
				var input = child.get_meta("json_input")
				result[child_name] = input.text

			"number":
				var child_name = child.get_meta("json_name")
				var input = child.get_meta("json_input")
				result[child_name] = input.value

			"bool":
				var child_name = child.get_meta("json_name")
				var input = child.get_meta("json_input")
				result[child_name] = input.button_pressed

			"array":
				var child_name = child.get_meta("json_name")
				result[child_name] = _extract_array(child)

			"object":
				var nested_name = child.get_meta("json_name")
				var nested_data = _extract_object(child)

				# If object has a name, assign it
				if nested_name != null and nested_name != "":
					result[nested_name] = nested_data
				else:
					result.merge(nested_data)
	return result

func _extract_array(wrapper: VBoxContainer) -> Array:
	var result := []
	var items_container = wrapper.get_meta("json_items_container")

	for item in items_container.get_children():
		var value = _extract_object(item)
		result.append(value)

	return result

#region Schema Parser
func _build_node(schema: Dictionary, parent: Control) -> void:
	match schema.get("type"):
		"object":
			_build_object(schema, parent)
		"array":
			_build_array(schema, parent)
		"string":
			_build_string(schema, parent)
		"bool":
			_build_bool(schema, parent)
		"number":
			_build_number(schema, parent)
		
func _build_object(schema: Dictionary, parent: Control) -> void:
	var container : VBoxContainer = VBoxContainer.new()
	parent.add_child(container)
	container.set_meta("json_type", "object")
	container.set_meta("json_schema", schema)

	for field in schema.get("fields", []):
		_build_node(field, container)
			
func _build_array(schema: Dictionary, parent: Control) -> void:
	var wrapper: VBoxContainer = VBoxContainer.new()
	parent.add_child(wrapper)

	wrapper.set_meta("json_type", "array")
	wrapper.set_meta("json_schema", schema)

	var label : Label = Label.new()
	label.text = schema.get("label", schema.get("name", "Array"))
	wrapper.add_child(label)

	var items_container : VBoxContainer = VBoxContainer.new()
	wrapper.add_child(items_container)

	wrapper.set_meta("json_items_container", items_container)

	var add_button : Button = Button.new()
	add_button.text = "Add"
	wrapper.add_child(add_button)

	add_button.pressed.connect(func():
		_add_array_item(wrapper)
	)

func _add_array_item(array_wrapper: VBoxContainer):
	var schema : Dictionary = array_wrapper.get_meta("json_schema")
	var item_schema : Dictionary= schema.get("item")
	var items_container = array_wrapper.get_meta("json_items_container")

	var item_container := VBoxContainer.new()
	items_container.add_child(item_container)

	_build_node(item_schema, item_container)
 

func _build_string(schema: Dictionary, parent: Control) -> void:
	var container := VBoxContainer.new()
	parent.add_child(container)

	container.set_meta("json_type", "string")
	container.set_meta("json_name", schema.get("name"))

	var label := Label.new()
	label.text = schema.get("label", schema.get("name", "String"))
	container.add_child(label)

	var input

	if schema.get("multiline", false):
		input = TextEdit.new()
		input.custom_minimum_size.y = 100
	else:
		input = LineEdit.new()

	container.add_child(input)
	container.set_meta("json_input", input)
	
func _build_bool(schema: Dictionary, parent: Control) -> void:
	var container := HBoxContainer.new()
	parent.add_child(container)

	container.set_meta("json_type", "bool")
	container.set_meta("json_name", schema.get("name"))

	var checkbox := CheckBox.new()
	checkbox.text = schema.get("label", schema.get("name", "Bool"))
	container.add_child(checkbox)

	container.set_meta("json_input", checkbox)
	
func _build_number(schema: Dictionary, parent: Control) -> void:
	var container := VBoxContainer.new()
	parent.add_child(container)

	container.set_meta("json_type", "number")
	container.set_meta("json_name", schema.get("name"))

	var label := Label.new()
	label.text = schema.get("label", schema.get("name", "Number"))
	container.add_child(label)

	var spin := SpinBox.new()
	spin.step = 1
	spin.min_value = -999999
	spin.max_value = 999999

	container.add_child(spin)
	container.set_meta("json_input", spin)
#endregion Schema Parser

#endregion Functions

#region Signal callback functions
func _on_load_pressed():
	#TODO : make a path picker
	var schema_path = "res://Json/Schemas/quest_schema.json"
	emit_signal("load_requested", schema_path)

func _on_export_button_pressed():
	var data := _extract_object(form_root)
	export_requested.emit(data)

func _on_back_button_pressed():
	back_requested.emit()
#endregion
