class_name GrowthRate
extends Resource
## Per-character stat growth applied on level-up.
## Only the level-up system reads this resource.
## CharacterStats does not reference GrowthRate - they are separate resources.

@export var hp_growth: int = 0
@export var atk_growth: int = 0
@export var def_growth: int = 0
@export var spd_growth: float = 0.0
