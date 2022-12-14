tool
extends "../../terminal.gd"

signal exited(exit_code, signum)

var editor_settings: EditorSettings

onready var pty = $PTY


# Sets terminal colors according to a dictionary that maps terminal color names
# to TextEditor theme color names.
func _set_terminal_colors(color_map: Dictionary) -> void:
	for key in color_map.keys():
		var val: String = color_map[key]
		var color: Color = editor_settings.get_setting("text_editor/highlighting/%s" % val)
		theme.set_color(key, "Terminal", color)


func _ready():
	if not editor_settings:
		return

	theme = Theme.new()

	# Get colors from TextEdit theme. Created using the default (Adaptive) theme
	# for reference, but will probably cause strange results if using another theme
	# better to use a dedicated terminal theme, rather than relying on this.
	_set_terminal_colors(
		{
			"black": "caret_background_color",
			"red": "keyword_color",
			"green": "gdscript/node_path_color",
			"yellow": "string_color",
			"blue": "function_color",
			"magenta": "symbol_color",
			"cyan": "gdscript/function_definition_color",
			"white": "text_color",
			"bright_black": "comment_color",
			"bright_red": "breakpoint_color",
			"bright_green": "base_type_color",
			"bright_yellow": "search_result_color",
			"bright_blue": "member_variable_color",
			"bright_magenta": "code_folding_color",
			"bright_cyan": "user_type_color",
			"bright_white": "text_selected_color",
			"background": "background_color",
			"foreground": "caret_color",
		}
	)
	_native_terminal._update_theme()


func _input(event):
	if has_focus() and event is InputEventKey and event.is_pressed():
		if event.control and event.scancode in [KEY_PAGEUP, KEY_PAGEDOWN]:
			# Handled by switch tabs shortcut.
			return

		if event.control and event.shift:
			# Not handled by terminal.
			return

		# Handle all other InputEventKey events to prevent triggering of editor
		# shortcuts when using the terminal.
		#
		# Currently the only way to get shortcuts is by calling editor_settings.get_setting("shortcuts")
		# and it returns an array that *only* contains shortcuts that have been modified from the original.
		# Once https://github.com/godotengine/godot-proposals/issues/4112 is resolved it should be possible
		# to get all shortcuts by their editor setting string as documented here:
		# https://docs.godotengine.org/en/stable/tutorials/editor/default_key_mapping.html.
		# In this case we could simply add a setting called something like "allowed shortcuts" or
		# "propagated shortcuts" consisting of an array of shortcut editor setting strings.
		# For example "editor/save_scene" which saves the scene and by default maps to 'Ctrl + S'.
		# Then any shortcut events listed here can be handled by the terminal *and* the editor.
		get_tree().set_input_as_handled()
		_gui_input(event)


func _on_PTY_exited(exit_code: int, signum: int):
	emit_signal("exited", exit_code, signum)
