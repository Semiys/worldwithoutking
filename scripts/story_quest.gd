extends Resource
class_name StoryQuest

var title: String
var description: String
var type: String
var objective_count: int
var current_progress: int = 0
var reward_exp: int
var reward_items: Array
var next_quest_id: String = ""

func _init(p_title: String, p_description: String, p_type: String, 
          p_objective_count: int, p_reward_exp: int, p_reward_items: Array, 
          p_next_quest_id: String = ""):
    title = p_title
    description = p_description
    type = p_type
    objective_count = p_objective_count
    reward_exp = p_reward_exp
    reward_items = p_reward_items
    next_quest_id = p_next_quest_id

func check_completed() -> bool:
    return current_progress >= objective_count

func get_progress_text() -> String:
    return str(current_progress) + "/" + str(objective_count) 