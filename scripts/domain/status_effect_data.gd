class_name StatusEffectData
extends Resource

enum StackPolicy { REFRESH, STACK, IGNORE }

@export var effect_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var duration_turns := 2
@export var damage_per_turn := 0
@export var move_modifier := 0
@export var physical_defense_modifier := 0
@export var magical_defense_modifier := 0
@export var stack_policy: StackPolicy = StackPolicy.REFRESH
@export_range(1, 8) var max_stacks := 1
@export var color := Color.WHITE
