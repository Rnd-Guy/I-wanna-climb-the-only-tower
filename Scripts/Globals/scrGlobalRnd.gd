extends Node

enum ITEMS {
	JUMP,
	DOUBLE_JUMP,
	TRIPLE_JUMP,
	INFINITE_JUMP,
	
	GUN,
	GUN_RECOIL,
	GUN_INFINITE_AMMO,
	
	SWORD,
	SWORD_BOUNCE,
	
	WALL_JUMP,
	DASH,
	
	KEY,
	FILLER,
}

enum DIR {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var world_name: String = "World 1"

signal item_pickup;
