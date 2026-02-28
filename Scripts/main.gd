class_name Main
extends Control

const JSON_ROOT := "res://Json/"
const SCHEMA_DIR := JSON_ROOT + "Schemas/"
const RESULT_DIR := JSON_ROOT + "Results/"
const CONFIG_PATH := JSON_ROOT + "app_config.json"

var config : Dictionary = {}
var current_category : String = ""
var current_schema : Dictionary = {}
var current_schema_path : String = ""

@onready var landing_page = $MarginContainer/Control/LandingPage
@onready var editor_page = $MarginContainer/Control/EditorPage

func _ready():
	_load_config()
	_show_landing_page()

	landing_page.category_selected.connect(_on_category_selected)
	editor_page.export_requested.connect(_on_export_requested)
	editor_page.back_requested.connect(_show_landing_page)

	_show_landing_page()

#region functions
##Configure the app
func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		_create_default_config()
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	config = JSON.parse_string(file.get_as_text())
	
	#If no specific config, we use the default one
	if typeof(config) != TYPE_DICTIONARY:
		config = {}
		_create_default_config()

func _create_default_config() -> void:
	config = {
		"quest_last_schema": SCHEMA_DIR + "quest_default.json",
		"dialogue_last_schema": SCHEMA_DIR + "dialogue_default.json",
		"object_last_schema": SCHEMA_DIR + "object_default.json"
	}
	_save_config()

func _save_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(config, "\t"))
	file.close()


##Load the schema for the a category of JSON
##Arg: path to the schema.json file
func _load_schema(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Schema not found: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid schema format: " + path)
		return

	current_schema = parsed
	current_schema_path = path

##Retrieves the path to a schema
##Arg: category of Json
func _get_schema_path_for_category(category: String) -> String:
	var key := category + "_last_schema"
	if config.has(key):
		return config[key]
	# If no specific schema, we use the default
	return SCHEMA_DIR + category + "_default.json"

##Takes data generated with the EditorPage and saves it as Json
##Arg: data in form a Dictionary
func _save_json_to_disk(data: Dictionary) -> void:
	var save_path : String = RESULT_DIR + current_category + "/" + data.get("id", "unnamed") + ".json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


##Display the Landing Page, hiding the Editor Page
func _show_landing_page():
	landing_page.visible = true
	editor_page.visible = false

##Display the Editor Page, Hiding the Landing Page
func _show_editor():
	landing_page.visible = false
	editor_page.visible = true
#endregion


#region signal callbacks
func _on_category_selected(category: String) -> void:
	current_category = category
	var schema_path := _get_schema_path_for_category(category)
	_load_schema(schema_path)
	
	editor_page.build_from_schema(current_schema)
	_show_editor()

func _on_export_requested(data: Dictionary) -> void:
	_save_json_to_disk(data)
#endregion
