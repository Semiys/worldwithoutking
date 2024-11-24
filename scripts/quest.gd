class_name Quest
extends Resource

var title: String
var description: String
var type: String  # kill, collect, talk, etc.
var objective_count: int
var current_progress: int = 0
var reward_exp: int
var completed: bool = false

func _init(p_title: String = "", p_description: String = "", p_type: String = "", 
          p_objective_count: int = 0, p_reward_exp: int = 0):
    title = p_title
    description = p_description
    type = p_type
    objective_count = p_objective_count
    reward_exp = p_reward_exp

func is_completed() -> bool:
    return current_progress >= objective_count

func get_progress_text() -> String:
    return str(current_progress) + "/" + str(objective_count) 