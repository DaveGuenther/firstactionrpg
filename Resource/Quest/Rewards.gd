# Rewards.gd

extends Resource

class_name Rewards

enum Type { COINS }

@export var reward_type: Type = Type.COINS
@export var reward_amount: int = 1
