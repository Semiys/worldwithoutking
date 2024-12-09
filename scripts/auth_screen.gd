extends Control

@onready var login_container = $LoginContainer
@onready var register_container = $RegisterContainer
@onready var error_label = $ErrorLabel
@onready var auth_manager = get_node("/root/AuthManager")

var current_mode = "login"

func _ready():
	await get_tree().create_timer(0.1).timeout
	show_login()
	error_label.hide()

func show_login():
	current_mode = "login"
	login_container.show()
	register_container.hide()
	error_label.hide()

func show_register():
	current_mode = "register"
	login_container.hide()
	register_container.show()
	error_label.hide()

func _on_login_button_pressed():
	var username = $LoginContainer/UsernameEdit.text
	var password = $LoginContainer/PasswordEdit.text
	
	if auth_manager.login_user(username, password):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	else:
		error_label.text = "Неверный логин или пароль"
		error_label.show()

func _on_register_button_pressed():
	var username = $RegisterContainer/UsernameEdit.text
	var password = $RegisterContainer/PasswordEdit.text
	var confirm_password = $RegisterContainer/ConfirmPasswordEdit.text
	
	if password != confirm_password:
		error_label.text = "Пароли не совпадают"
		error_label.show()
		return
	
	if auth_manager.register_user(username, password):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	else:
		error_label.text = "Ошибка регистрации. Возможно, пользователь уже существует"
		error_label.show()

func _on_switch_mode_button_pressed():
	if current_mode == "login":
		show_register()
	else:
		show_login() 
