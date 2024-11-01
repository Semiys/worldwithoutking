extends Node2D

@export var noise_height_text:NoiseTexture2D
@export var noise_tree_text:NoiseTexture2D
var noise:Noise
var tree_noise:Noise
var width:int=256
var height:int=256
var water_atlas=Vector2i(0,2)
var grass_tiles_arr=[]
var terrain_grass_int=0
var grass_atlas_arr=[Vector2i(1,1),Vector2i(5,1),Vector2i(5,2),Vector2i(5,0)]
var thread: Thread

func _ready() -> void:
	thread=Thread.new()
	
	noise=noise_height_text.noise
	tree_noise=noise_tree_text.noise
	generate_world()

func generate_world():
	for x in width:
		for y in height:
			var noise_val:float=noise.get_noise_2d(x,y)
			var tree_noise_val:float=tree_noise.get_noise_2d(x,y)
			if noise_val<0.0:
				$water.set_cell(Vector2i(x,y),0,water_atlas)
				
			if noise_val>=0.0:
				if noise_val>0.10 and noise_val<0.35 and tree_noise_val>0.4:
					$plants.set_cell(Vector2i(x,y),1,Vector2i(0,2),1)
				if noise_val>0.0:
					$grass.set_cell(Vector2i(x,y),0,grass_atlas_arr.pick_random())
				grass_tiles_arr.append(Vector2i(x,y))
			
	$terrain.set_cells_terrain_connect(grass_tiles_arr,terrain_grass_int,0)



func _process(delta:float)->void:
	pass
