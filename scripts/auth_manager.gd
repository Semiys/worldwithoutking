extends Node

const USERS_FILE = "user://users.txt"
var current_user = null

func _ready():
	# Создаем файл пользователей, если его нет
	if not FileAccess.file_exists(USERS_FILE):
		var file = FileAccess.open(USERS_FILE, FileAccess.WRITE)
		file.close()

func register_user(username: String, password: String) -> bool:
	if username.length() < 3 or password.length() < 4:
		return false
		
	# Проверяем, существует ли пользователь
	if user_exists(username):
		return false
	
	# Сохраняем нового пользователя
	var file = FileAccess.open(USERS_FILE, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_line(JSON.stringify({"username": username, "password": password}))
	file.close()
	
	current_user = username
	return true

func login_user(username: String, password: String) -> bool:
	var file = FileAccess.open(USERS_FILE, FileAccess.READ)
	
	while not file.eof_reached():
		var line = file.get_line()
		if line.length() > 0:
			var user_data = JSON.parse_string(line)
			if user_data["username"] == username and user_data["password"] == password:
				current_user = username
				file.close()
				return true
	
	file.close()
	return false

func user_exists(username: String) -> bool:
	var file = FileAccess.open(USERS_FILE, FileAccess.READ)
	
	while not file.eof_reached():
		var line = file.get_line()
		if line.length() > 0:
			var user_data = JSON.parse_string(line)
			if user_data["username"] == username:
				file.close()
				return true
	
	file.close()
	return false

func logout():
	current_user = null 
