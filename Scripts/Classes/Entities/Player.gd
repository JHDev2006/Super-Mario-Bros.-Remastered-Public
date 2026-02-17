class_name Player
extends CharacterBody2D

#region Intended modifiable properties, can be changed in a character's CharacterInfo.json
# SkyanUltra: Moved physics/death parameters into their own nested dictionaries.
# This makes it possible to modify character physics to a much greater extent,
# allowing for power-state specific parameters while still limiting the player's
# modifications to a specific degree to prevent cheating.
## Determines various important values of the player character.
@export_group("Player Parameters")
## Determines the physics properties of the player character, such as general movement values, hitboxes, and other typical behavior.
@export var PHYSICS_PARAMETERS: Dictionary = {
	"Default": { # Fallback parameters. Additional entries can be added through CharacterInfo.json.
		"COLLISION_SIZE": [8, 28],
		"CROUCH_COLLISION_SIZE": [8, 14],            # The player's hitbox scale when crouched.
		"CAN_AIR_TURN": false,             # Determines if the player can turn in mid-air.
		"CAN_BREAK_BRICKS": true,          # Determines if the player can break bricks in their current form.
		"CAN_BE_WALL_EJECTED": true,       # Determines if the player gets pushed out of blocks if inside of them.
		"ROUNDED_FLOOR_COLLISION": false,
		"JUMP_WALK_THRESHOLD": 60.0,       # The minimum velocity the player must move at to perform a walking jump.
		"JUMP_RUN_THRESHOLD": 135.0,       # The minimum velocity the player must move at to perform a running jump.
		
		"JUMP_GRAVITY_IDLE": 11.0,         # The player's gravity while jumping from an idle state, measured in px/frame.
		"JUMP_GRAVITY_WALK": 11.0,         # The player's gravity while jumping from a walking state, measured in px/frame.
		"JUMP_GRAVITY_RUN": 11.0,          # The player's gravity while jumping from a running state, measured in px/frame.
		"JUMP_SPEED_IDLE": 300.0,          # The strength of the player's idle jump, measured in px/sec.
		"JUMP_SPEED_WALK": 300.0,          # The strength of the player's walking jump, measured in px/sec.
		"JUMP_SPEED_RUN": 300.0,           # The strength of the player's running jump, measured in px/sec.
		"JUMP_INCR": 8.0,                  # How much the player's X velocity affects their jump speed.
		"JUMP_CANCEL_DIVIDE": 1.5,         # When the player cancels their jump, their Y velocity gets divided by this value.
		"JUMP_HOLD_SPEED_THRESHOLD": 0.0,  # When the player's Y velocity goes past this value while jumping, their gravity switches to FALL_GRAVITY.
		"JUMP_BUFFER": 10,
		"CLASSIC_BOUNCE_BEHAVIOR": false,  # Determines if the player can only get extra height from a bounce with upward velocity, as opposed to holding jump.
		"BOUNCE_SPEED": 200.0,             # The strength at which the player bounces off enemies without any extra input, measured in px/sec.
		"BOUNCE_JUMP_SPEED": 300.0,        # The strength at which the player bounces off enemies while holding jump, measured in px/sec.
		
		"FALL_GRAVITY_PREDETERMINED": false,         # Determines if the player's gravity is determined by their last X velocity from leaving the ground rather than their current X velocity.
		"FALL_GRAVITY_IDLE": 25.0,         # The player's gravity while falling from an idle state, measured in px/frame.
		"FALL_GRAVITY_WALK": 25.0,         # The player's gravity while falling from a walking state, measured in px/frame.
		"FALL_GRAVITY_RUN": 25.0,          # The player's gravity while falling from a running state, measured in px/frame.
		"MAX_FALL_SPEED": 280.0,           # The player's maximum fall speed, measured in px/sec.
		"CEILING_BUMP_SPEED": 45.0,        # The speed at which the player falls after hitting a ceiling, measured in px/sec.
		
		"CLAMP_GROUND_SPEED": false,       # Determines if the player's speed will get clamped while moving on the ground, emulating snappier movement.
		"MINIMUM_SPEED": 0.0,              # The player's minimum speed while actively moving.
		
		"WALK_SPEED": 96.0,                # The player's speed while walking, measured in px/sec.
		"GROUND_WALK_ACCEL": 4.0,          # The player's acceleration while walking, measured in px/frame.
		"WALK_SKID": 8.0,                  # The player's turning deceleration while running, measured in px/frame.
		"CAN_RUN_ACCEL_EARLY": false,      # Determines if the player can hold run before reaching walk speed to begin running.
		"RUN_STOP_BUFFER": 0.0,            # Determines the amount of time in seconds before running will stop once its initiated.
		"RUN_SPEED": 160.0,                # The player's speed while running, measured in px/sec.
		"GROUND_RUN_ACCEL": 1.25,          # The player's acceleration while running, measured in px/frame.
		"RUN_SKID": 8.0,     
		"ICE_ACCEL_MOD": 0.25,
		"ICE_DECEL_MOD": 0.25,
		"ICE_SKID_MOD": 0.25,             # The player's turning deceleration while running, measured in px/frame.
		
		"CLASSIC_SKID_CONDITIONS": false,  # Determines if the player's speed must be over SKID_THRESHOLD to begin skidding.
		"CAN_INSTANT_STOP_SKID": false,    # Determines if the player will instantly stop upon reaching the skid threshold.
		"SKID_THRESHOLD": 100.0,           # The horizontal speed required, to be able to start skidding.
		"SKID_STOP_THRESHOLD": 10.0,       # The maximum velocity required before the player will stop skidding.
		
		"GROUND_WALK_DECEL": 3.0,          # The player's grounded deceleration while no buttons are pressed, measured in px/frame.
		"GROUND_RUN_DECEL": 3.0,
		"DECEL_THRESHOLD": 0, 
		"AIR_DECEL": 0.0,                 # The player's airborne deceleration while no buttons are pressed, measured in px/frame.
					  
		"AIR_WALK_ACCEL": 3.0,             # The player's usual acceleration while in midair, measured in px/frame.
		"AIR_WALK_SKID_ACCEL": 4.5,        # The player's usual skid acceleration while in midair, measured in px/frame.
		"AIR_RUN_ACCEL": 3.0,              # The player's running acceleration while in midair, measured in px/frame.
		"AIR_RUN_SKID_ACCEL": 4.5,         # The player's running skid acceleration while in midair, measured in px/frame.
		"AIR_BACKWARDS_ACCEL": 3.0,        # The player's backwards acceleration while in midair, measured in px/frame.
		"AIR_BACKWARDS_SKID_ACCEL": 4.5,   # The player's backwards skid acceleration while in midair, measured in px/frame.
		"AIR_SKID_JUMP_SPEED_MINIMUM": 0.0,          # The minimum jump speed required to use 'skid' params instead of 'accel' params for air control.

		"LOCK_AIR_SPEED": false,           # Determines if the player can surpass their walk speed while in the air, aside from on trampolines.
		"USE_BACKWARDS_ACCEL": false,      # Determines if the player will use backwards acceleration while travelling backwards.
		"CAN_AIR_RUN_WITHOUT_RUN_BUTTON": false,     # Determines if the player must be holding the run button to allow for running speed in the air.
		"CAN_AIR_SKID_ALWAYS": true,       # Determines if the player uses 'skid' params instead of 'accel' params if jump started below a certain speed.
		"CAN_AIR_RUN_EARLY": false,        # Determines a multiplier to the player's acceleration when moving backwards in the air.
		
		"CLIMB_OFFSET": 5.0,               # The X position offset applied to the player when climbing.
		"CLIMB_UP_SPEED": 50.0,            # The player's speed while climbing upwards, measured in px/sec.
		"CLIMB_DOWN_SPEED": 120.0,         # The player's speed while climbing downwards, measured in px/sec.

		"TRAMPOLINE_SPEED": 500.0,         # The strength of a jump on a trampoline, measured in px/sec.
		"SUPER_TRAMPOLINE_SPEED": 1200.0,  # The strength of a jump on a super trampoline, measured in px/sec.
		
		"SWIM_SPEED": 95.0,                # The player's horizontal speed while swimming, measured in px/sec.
		"SWIM_GROUND_SPEED": 45.0,         # The player's horizontal speed while grounded underwater, measured in px/sec.
		"SWIM_DECEL": 3.0,                 # The player's deceleration in water while no buttons are pressed, measured in px/frame.
		"SWIM_HEIGHT": 100.0,              # The strength of the player's swim, measured in px/sec.
		"SWIM_EXIT_SPEED": 250.0,          # The strength of the player's jump out of water, measured in px/sec.
		"SWIM_GRAVITY": 2.5,               # The player's gravity while swimming, measured in px/frame.
		"MAX_SWIM_FALL_SPEED": 200.0,      # The player's maximum fall speed while swimming, measured in px/sec.
	},
	"Small": {
		"COLLISION_SIZE": [8, 14],
		"CROUCH_COLLISION_SIZE": [8, 12],
		"CAN_BREAK_BRICKS": false,
		"CAN_BE_WALL_EJECTED": false,
	},
	"Big": {},
	"Fire": {},
	"Superball": {}
}
## Determines the physics properties of the character while "Classic Physics" are enabled.
@export var CLASSIC_PARAMETERS: Dictionary = {
	"Default": { # This uses the same parameters as PHYSICS_PARAMETERS and should be updated whenever new parameters are added.
		"COLLISION_SIZE": [8, 28],        # The player's hitbox scale.
		"CROUCH_COLLISION_SIZE": [8, 14],             # The player's hitbox scale when crouched.
		"CAN_AIR_TURN": false,             # Determines if the player can turn in mid-air.
		"CAN_BREAK_BRICKS": true,          # Determines if the player can break bricks in their current form.
		"CAN_BE_WALL_EJECTED": true,       # Determines if the player gets pushed out of blocks if inside of them.
		"ROUNDED_FLOOR_COLLISION": true,
		"JUMP_WALK_THRESHOLD": 60.0,       # The minimum velocity the player must move at to perform a walking jump.
		"JUMP_RUN_THRESHOLD": 93.75,       # The minimum velocity the player must move at to perform a running jump.
		"JUMP_BUFFER": 2,
		"JUMP_GRAVITY_IDLE": 7.5,          # The player's gravity while jumping from an idle state, measured in px/frame.
		"JUMP_GRAVITY_WALK": 7.03,         # The player's gravity while jumping from a walking state, measured in px/frame.
		"JUMP_GRAVITY_RUN": 9.375,         # The player's gravity while jumping from a running state, measured in px/frame.
		"JUMP_SPEED_IDLE": 248.0,          # The strength of the player's idle jump, measured in px/sec.
		"JUMP_SPEED_WALK": 248.0,          # The strength of the player's walking jump, measured in px/sec.
		"JUMP_SPEED_RUN": 310.0,           # The strength of the player's running jump, measured in px/sec.
		"JUMP_INCR": 0.0,                  # How much the player's X velocity affects their jump speed.
		"JUMP_CANCEL_DIVIDE": 1.0,         # When the player cancels their jump, their Y velocity gets divided by this value.
		"JUMP_HOLD_SPEED_THRESHOLD": 0.0,  # When the player's Y velocity goes past this value while jumping, their gravity switches to FALL_GRAVITY.
		
		"CLASSIC_BOUNCE_BEHAVIOR": true,   # Determines if the player can only get extra height from a bounce with upward velocity, as opposed to holding jump.
		
		"BOUNCE_SPEED": {
			"SMB1": {"value": 248.0},
			"SMBLL": {"value": 370.0}
		},
		"BOUNCE_JUMP_SPEED": {
			"SMB1": {"value": 310.0},
			"SMBLL": {"value": 370.0}
		},                                 # The strength at which the player bounces off enemies without any extra input, measured in px/sec.   # The strength at which the player bounces off enemies while holding jump, measured in px/sec.
		
		"FALL_GRAVITY_PREDETERMINED": true,          # Determines if the player's gravity is determined by their last X velocity from leaving the ground rather than their current X velocity.
		"FALL_GRAVITY_IDLE": 26.25,        # The player's gravity while falling from an idle state, measured in px/frame.
		"FALL_GRAVITY_WALK": 22.5,         # The player's gravity while falling from a walking state, measured in px/frame.
		"FALL_GRAVITY_RUN": 33.75,         # The player's gravity while falling from a running state, measured in px/frame.
		"MAX_FALL_SPEED": 255.0,           # The player's maximum fall speed, measured in px/sec.
		"CEILING_BUMP_SPEED": 45.0,        # The speed at which the player falls after hitting a ceiling, measured in px/sec.
		
		"CLAMP_GROUND_SPEED": true,        # Determines if the player's speed will get clamped while moving on the ground, emulating snappier movement.
		"MINIMUM_SPEED": 4.46,             # The player's minimum speed while actively moving.
		
		"WALK_SPEED": 90.0,                # The player's speed while walking, measured in px/sec.
		"GROUND_WALK_ACCEL": 2.23,         # The player's acceleration while walking, measured in px/frame.
		"WALK_SKID": 6.1,                  # The player's turning deceleration while running, measured in px/frame.
		
		"CAN_RUN_ACCEL_EARLY": true,       # Determines if the player can hold run before reaching walk speed to begin running.
		"RUN_STOP_BUFFER": 0.167,          # Determines the amount of time in seconds before running will stop once its initiated.
		"RUN_SPEED": 150.0,                # The player's speed while running, measured in px/sec.
		"GROUND_RUN_ACCEL": 3.34,          # The player's acceleration while running, measured in px/frame.
		"RUN_SKID": 6.1,                   # The player's turning deceleration while running, measured in px/frame.
		
		"CLASSIC_SKID_CONDITIONS": true,   # Determines if the player's speed must be over SKID_THRESHOLD to begin skidding.
		"CAN_INSTANT_STOP_SKID": true,     # Determines if the player will instantly stop upon reaching the skid threshold.
		"SKID_THRESHOLD": 100.0,           # The horizontal speed required, to be able to start skidding.
		"SKID_STOP_THRESHOLD": 33.75,      # The maximum velocity required before the player will stop skidding.
		
		"GROUND_WALK_DECEL": 3.05,   
		"GROUND_RUN_DECEL": 3.05,
		"DECEL_THRESHOLD": 33.75,           # The player's grounded deceleration while no buttons are pressed, measured in px/frame.
		
		"AIR_DECEL": 0.0,                  # The player's airborne deceleration while no buttons are pressed, measured in px/frame.
		"AIR_WALK_ACCEL": 2.23,            # The player's usual acceleration while in midair, measured in px/frame.
		"AIR_WALK_SKID_ACCEL": 3.04,       # The player's usual skid acceleration while in midair, measured in px/frame.
		"AIR_RUN_ACCEL": 3.34,             # The player's running acceleration while in midair, measured in px/frame.
		"AIR_RUN_SKID_ACCEL": 3.34,        # The player's running skid acceleration while in midair, measured in px/frame.
		"AIR_BACKWARDS_ACCEL": 4.46,       # The player's backwards acceleration while in midair, measured in px/frame.
		"AIR_BACKWARDS_SKID_ACCEL": 4.46,  # The player's backwards skid acceleration while in midair, measured in px/frame.
		"AIR_SKID_JUMP_SPEED_MINIMUM": 105.0,        # The minimum jump speed required to use 'skid' params instead of 'accel' params for air control.

		"LOCK_AIR_SPEED": true,            # Determines if the player can surpass their walk speed while in the air, aside from on trampolines.
		"USE_BACKWARDS_ACCEL": true,       # Determines if the player will use backwards acceleration while travelling backwards.
		"CAN_AIR_RUN_WITHOUT_RUN_BUTTON": true,      # Determines if the player must be holding the run button to allow for running speed in the air.
		"CAN_AIR_SKID_ALWAYS": false,      # Determines if the player uses 'skid' params instead of 'accel' params if jump started below a certain speed.
		"CAN_AIR_RUN_EARLY": false,        # Determines a multiplier to the player's acceleration when moving backwards in the air.
		
		"CLIMB_OFFSET": 5.0,               # The X position offset applied to the player when climbing.
		"CLIMB_UP_SPEED": 50.0,            # The player's speed while climbing upwards, measured in px/sec.
		"CLIMB_DOWN_SPEED": 120.0,         # The player's speed while climbing downwards, measured in px/sec.

		"TRAMPOLINE_SPEED": 500.0,         # The strength of a jump on a trampoline, measured in px/sec.
		"SUPER_TRAMPOLINE_SPEED": 1200.0,  # The strength of a jump on a super trampoline, measured in px/sec.
		
		"SWIM_SPEED": 95.0,                # The player's horizontal speed while swimming, measured in px/sec.
		"SWIM_GROUND_SPEED": 45.0,         # The player's horizontal speed while grounded underwater, measured in px/sec.
		"SWIM_DECEL": 0.0,                 # The player's deceleration in water while no buttons are pressed, measured in px/frame.
		"SWIM_HEIGHT": 100.0,              # The strength of the player's swim, measured in px/sec.
		"SWIM_EXIT_SPEED": 250.0,          # The strength of the player's jump out of water, measured in px/sec.
		"SWIM_GRAVITY": 2.5,               # The player's gravity while swimming, measured in px/frame.
		"MAX_SWIM_FALL_SPEED": 200.0,      # The player's maximum fall speed while swimming, measured in px/sec.
	},
	"Small": {
		"COLLISION_SIZE": [8, 14],        # The player's hitbox scale.
		"CROUCH_COLLISION_SIZE": [8, 12],  
		"CROUCH_SCALE": 1.0,
		"CAN_BREAK_BRICKS": false,
		"CAN_BE_WALL_EJECTED": false,
	},
	"Big": {},
	"Fire": {},
	"Superball": {}
}
## Determines parameters typically involved with power-up behavior, mainly projectiles fired by the player.
@export var POWER_PARAMETERS: Dictionary = {
	"Default": {
		"STARTING_POWER_STATE": "Small",   # Determines the default starting power state.
		"STAR_TIME": 12.0,                 # Determines how long a Star will last for.
		"WING_TIME": 10.0,                 # Determines how long Wings will last for.
		"HAMMER_TIME": 10.0,               # Determines how long a Hammer will last for.
		
		"PROJ_TYPE": "",
		"PROJ_PARTICLE": "",
		# Determines what projectile/particle scene is used. Leaving
		# this blank disables firing projectiles and displaying
		# particles respectively.
		"PROJ_PARTICLE_ON_CONTACT": false, # Defines if the particle will play when making contact without being destroyed.
		"PROJ_SFX_THROW": "fireball",      # Defines the sound effect that plays when this projectile is fired.
		"PROJ_SFX_COLLIDE": "bump",        # Defines the sound effect that plays when this projectile collides.
		#"PROJ_SFX_HIT": "kick",           # Defines the sound effect that plays when this projectile damages an enemy.
		"PROJ_COLLECT_COINS": false,
		"MAX_PROJ_COUNT": 2,               # How many projectiles can be fired at once. -1 and below count as infinite.
		"PROJ_COLLISION": true,            # Determines if the projectile can interact with collidable surfaces.
		"PROJ_PIERCE_COUNT": 0,            # Determines how many additional enemies this projectile can hit before being destroyed. -1 and below count as infinite.
		"PROJ_PIERCE_HITRATE": -1,         # Determines how much time must pass in seconds before this projectile can hit the same enemy it is on top of currently. -1 and below count as infinite. 
		"PROJ_BOUNCE_COUNT": -1,           # Determines how many additional enemies this projectile can hit before being destroyed. -1 and below count as infinite.
		"PROJ_GROUND_BOUNCE": true,        # Determines if the projectile can bounce off the ground.
		"PROJ_WALL_BOUNCE": false,         # Determines if the projectile can bounce off of wals.
		"PROJ_CEIL_BOUNCE": false,         # Determines if the projectile can bounce off of ceilings.
		
		"PROJ_LIFETIME": -1,               # Determines how long the projectile will last for. -1 and below count as infinite.
		"PROJ_OFFSET": [-4.0, 16.0],       # Determines the offset for where the projectile will spawn.
		"PROJ_SPEED": [220.0, -100.0],     # Determines the initial velocity of the projectile.
		"PROJ_SPEED_CAP": [-220.0, 220.0], # Determines the minimum and maximum X velocity of the projectile.
		"PROJ_SPEED_SCALING": false,       # Determines if the projectile will have its initial speed scale with the player's movement.
		
		"PROJ_GROUND_DECEL": 0.0,          # The projectile's deceleration on the ground, measured in px/frame
		"PROJ_AIR_DECEL": 0.0,             # The projectile's deceleration in the air, measured in px/frame
		"PROJ_GRAVITY": 15.0,              # The projectile's gravity, measured in px/frame
		"PROJ_BOUNCE_HEIGHT": 125.0,       # The projectile's bounce velocity upon landing on the ground.
		"PROJ_MAX_FALL_SPEED": 150.0,      # The projectile's maximum fall speed, measured in px/sec
	},
	"Small": {
		"PROJ_OFFSET": [-4.0, 8.0],
	},
	"Big": {},
	"Fire": {
		"PROJ_TYPE": "res://Scenes/Prefabs/Entities/Items/Fireball",
		"PROJ_PARTICLE": "res://Scenes/Prefabs/Particles/FireballExplosion",
	},
	"Superball": {
		"PROJ_TYPE": "res://Scenes/Prefabs/Entities/Items/SuperballProjectile",
		"PROJ_PARTICLE": "res://Scenes/Prefabs/Particles/SmokeParticle",
		"PROJ_SFX_THROW": "superball",
		"PROJ_GRAVITY": 0.0, 
		"PROJ_LIFETIME": 10.0,
		"PROJ_WALL_BOUNCE": true,
		"PROJ_CEIL_BOUNCE": true,
		"PROJ_FLOOR_BOUNCE": true,
		"PROJ_COLLECT_COINS": true,
		"PROJ_SPEED": [150.0, -150.0],
	}
}
## Determines values involving various ending sequences, such as grabbing the flagpole and walking to an NPC at the end of a level.
@export var ENDING_PARAMETERS: Dictionary = {
	"Default": {
		"FLAG_SKIP_GRAB": false,           # Determines if the player skips grabbing the flag entirely.
		"FLAG_HANG_TIMER": 1.5,            # How long the player will stick on the flagpole.
		"FLAG_SLIDE_SPEED": 125.0,         # How fast the player slides down the flagpole.
		
		"FLAG_INITIAL_X_VELOCITY": 0.0,    # Determines the player's initial X velocity after letting go of the flagpole.
		"FLAG_JUMP_SPEED": 0.0,            # How high the player will initially jump after letting go of the flagpole.
		"FLAG_JUMP_INCR": 8.0,             # How much the player's X velocity will influence the player's jump height.
		
		"FLAG_SPEED_MULT": 1.0,            # The multiplier applied onto the player's max speed when walking to the flag.
		"FLAG_ACCEL_MULT": 1.0,            # The multiplier applied onto the player's max acceleration when walking to the flag.
		"TOAD_SPEED_MULT": 1.0,            # The multiplier applied onto the player's max speed when walking to a Toad.
		"TOAD_ACCEL_MULT": 1.0,            # The multiplier applied onto the player's max acceleration when walking to a Toad.
		"PEACH_SPEED_MULT": 1.0,           # The multiplier applied onto the player's max speed when walking to Peach.
		"PEACH_ACCEL_MULT": 1.0,           # The multiplier applied onto the player's max acceleration when walking to Peach.
		
		"DOOR_POSE_OFFSET": 0.0,           # The offset of where the player performs their PoseDoor animation, if applicable.
		"TOAD_POSE_OFFSET": -12.0,         # The offset of where the player performs their PoseToad animation, if applicable.
		"PEACH_POSE_OFFSET": -12.0,        # The offset of where the player performs their PosePeach animation, if applicable.
	}
}
## Determines values involving death, unique separated by damage types rather than power states.
@export var DEATH_PARAMETERS: Dictionary = {
	"Default": {
		"DEATH_COLLISION": false,          # Determines whether the player will still collide with the level.
		"DEATH_HANG_TIMER": 0.5,           # The amount of time the player will freeze in the air for during the death animation in seconds
		"DEATH_X_VELOCITY": 0,             # The horizontal velocity the player gets sent at when dying, measured in px/sec
		"DEATH_DECEL": 3.0,                # The player's deceleration during death, measured in px/frame
		"DEATH_JUMP_SPEED": 300.0,         # The strength of the player's "jump" during the death animation, measured in px/sec
		"DEATH_FALL_GRAVITY": 11.0,        # The player's gravity while falling during death, measured in px/frame
		"DEATH_MAX_FALL_SPEED": 280.0,     # The player's maximum fall speed during death, measured in px/sec
	}
}
## Determines values involving purely cosmetic changes, including offsets for the wing and hammer sprites and configuration for various visual and audio effects.
@export var COSMETIC_PARAMETERS: Dictionary = {
	"Default": { # Fallback parameters. Additional entries can be added through CharacterInfo.json.
		"WING_OFFSET": [0.0, 0.0],         # The visual offset of the wings which appear with the Wing power-up.
		"HAMMER_OFFSET": [0.0, -8.0],      # The visual offset of the hammer which appears with the Hammer power-up.
		
		"MOVE_ANIM_SPEED_DIV": 32,         # Determines the value used for division in the animation speed formula for walk/run animations. Lower is faster.
		"CHECKPOINT_ICON_HEIGHT": -40,
		"RAINBOW_STAR_FX_SPEED": 15.0,     # Determines the speed of the rainbow effect under the effects of a star, measured in cycles/sec
		"RAINBOW_STAR_SLOW_FX_SPEED": 7.5, # Determines the speed of the rainbow effect nearing the end of a star's duration, measured in cycles/sec
		"RAINBOW_POWERUP_FX": true,        # Determines whether or not the player will play the rainbow effect when powering up.
		"RAINBOW_FX_SPEED": 15.0,          # Determines the speed of the rainbow effect in other scenarios, measured in cycles/sec
		"ICE_SPEED_MOD": 1.5,
		"WALK_SFX": "walk",                # Determines which sound effect to play when walking.
		"RUN_SFX": "run",                  # Determines which sound effect to play when running.
		"SKID_SFX": "skid",            # Determines which sound effect to play when skidding.
		"JUMP_SFX": "big_jump",            # Determines which sound effect to play when jumping.
		"TRAMPOLINE_SFX": "big_trampoline",          # Determines which sound effect to play when bouncing on a trampoline.
		"TRAMPOLINE_USED_SFX": "big_used_trampoline", # Determines which sound effect to play when actively using a trampoline.
		"GROUNDED_WALK_SFX": true,         # Forces walk sounds to only play when on the ground.
		"GROUNDED_RUN_SFX": true,          # Forces run sounds to only play when on the ground.
	},
	"Small": {
		"WING_OFFSET": [0.0, 10.0],
		"RAINBOW_POWERUP_FX": false,
		"JUMP_SFX": "small_jump",
		"TRAMPOLINE_SFX": "small_trampoline",
		"TRAMPOLINE_USED_SFX": "small_used_trampoline",
		"CHECKPOINT_ICON_HEIGHT": -24,
	},
	"Big": {
		"RAINBOW_POWERUP_FX": false,
	}
} 
#endregion
@export_group("")

@export var physics_dict = PHYSICS_PARAMETERS

@onready var camera_center_joint: Node2D = $CameraCenterJoint

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var camera: Camera2D = $Camera
@onready var score_note_spawner: ScoreNoteSpawner = $ScoreNoteSpawner

var has_jumped := false
var has_spring_jumped := false

var direction := 1
var input_direction := 0

var star_meter := 0.0
var flight_meter := 0.0
var hammer_meter := 0.0

var velocity_direction := 1
var velocity_x_jump_stored := 0
var speed_mult := 1.0
var accel_mult := 1.0

var total_keys := 0

@export var power_state: PowerUpState = null:
	set(value):
		power_state = value
		set_power_state_frame()
var character := "Mario"

var crouching := false:
	get(): # You can't crouch if the animation somehow doesn't exist.
		if not sprite.sprite_frames.has_animation("Crouch"): return false
		return crouching
	set(value):
		if not crouching and value:
			crouch_started.emit()
		crouching = value
var looking_up := false:
	get(): # Same deal, can't look up if the animation doesn't exist.
		if not sprite.sprite_frames.has_animation("LookUp"): return false
		return looking_up
var skidding := false

var bumping := false
var can_bump_sfx := true
var just_landed := false
var can_land_sfx := false

var kicking = false

@export var player_id := 0
const ONE_UP_NOTE = preload("uid://dopxwjj37gu0l")
var gravity: float = calculate_speed_param("FALL_GRAVITY", velocity_x_jump_stored)

var attacking := false
var pipe_enter_direction := Vector2.ZERO#
var pipe_move_direction := 1
var stomp_combo := 0

var is_invincible := false
var in_cutscene := false

var can_pose_anim := false
var can_pose_castle_anim := false
var is_posing := false

var can_big_grow_anim = false
var can_bump_jump_anim = false
var can_bump_crouch_anim = false
var can_bump_swim_anim = false
var can_bump_fly_anim = false
var can_kick_anim = false
var can_push_anim = false
var can_spring_land_anim = false
var can_spring_fall_anim = false

const COMBO_VALS := [100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000, null]

@export_enum("Small", "Big", "Fire", "Superball") var starting_power_state := 0
@onready var state_machine: StateMachine = $States
@onready var normal_state: Node = $States/Normal
@export var auto_death_pit := true

var can_hurt := true:
	set(value):
		can_hurt = value

var in_water := false

var has_star := false
var has_wings := false
var has_hammer := false

var spring_bouncing := false

var low_gravity := false

var gravity_vector := Vector2.DOWN

var jump_cancelled := false

var camera_pan_amount := 24

var animating_camera := false

var can_uncrouch := false

static var CHARACTERS := ["Mario", "Luigi", "Toad", "Toadette"]
const POWER_STATES := ["Small", "Big", "Fire", "Superball"]

signal moved
signal dead
signal jumped
signal crouch_started
signal damaged
signal attacked
signal powered_up

var is_dead := false
var last_damage_source := ""

static var CHARACTER_NAMES := ["CHAR_MARIO", "CHAR_LUIGI", "CHAR_TOAD", "CHAR_TOADETTE"]

static var CHARACTER_COLOURS := [preload("res://Assets/Sprites/Players/Mario/CharacterColour.json"), preload("res://Assets/Sprites/Players/Luigi/CharacterColour.json"), preload("res://Assets/Sprites/Players/Toad/CharacterColour.json"), preload("res://Assets/Sprites/Players/Toadette/CharacterColour.json")]

var can_timer_warn := true

var colour_palette_texture: Texture = null

static var CHARACTER_PALETTES := [
	preload("res://Assets/Sprites/Players/Mario/ColourPalette.json"),
	preload("res://Assets/Sprites/Players/Luigi/ColourPalette.json"),
	preload("res://Assets/Sprites/Players/Toad/ColourPalette.json"),
	preload("res://Assets/Sprites/Players/Toadette/ColourPalette.json")
]

#region Animation Fallbacks, these determine what animations will use as a back-up if they aren't present.
const ANIMATION_FALLBACKS := {
	# --- Idle States ---
	"LookUp": "Idle",
	"WaterLookUp": "LookUp",
	"WingLookUp": "WaterLookUp",
	"Crouch": "Idle",
	"WaterCrouch": "Crouch",
	"WingCrouch": "WaterCrouch",
	"Stunned": "Idle",
	
	# --- Cutscene States ---
	"PosePeach": "PoseToad",

	# --- Jump & Fall States ---
	"Fall": "Move",
	"JumpFall": "Jump",
	"JumpBump": "Bump",
	"CrouchFall": "Crouch",
	"CrouchJump": "Crouch",
	"CrouchBump": "Bump",
	"JogJump": "Jump",
	"JogJumpFall": "JumpFall",
	"JogJumpBump": "JumpBump",
	"RunJump": "Jump",
	"RunJumpFall": "JumpFall",
	"RunJumpBump": "JumpBump",
	"SpringJump": "Jump",
	"SpringJumpBump": "JumpBump",
	
	# --- Star Jump & Fall States ---
	"StarJump": "Jump",
	"StarFall": "JumpFall",
	"StarJumpFall": "StarFall", # SkyanUltra: Legacy fallback for >1.0.2.
	"StarJumpBump": "JumpBump",
	
	"StarRunJump": "StarJump",
	"StarRunJumpFall": "StarJumpFall",
	"StarRunJumpBump": "StarJumpBump",
	
	"StarSpringJump": "StarJump",
	"StarSpringFall": "StarJumpFall",
	"StarSpringBump": "StarJumpBump",

	# --- Movement/Interaction States ---
	"Walk": "Move",
	"Run": "Move",
	"CrouchMove": "Crouch",
	"Pipe": "Idle",
	"PipeWalk": "Walk",
	"FlagSlide": "Climb",

	# --- Size Transformations ---
	"Shrink": "Grow",
	# SkyanUltra: Future power-ups will need to be added here.
	"SmallShrink": "SmallGrow",
	"NormalShrink": "NormalGrow",
	"FireShrink": "FireGrow",
	"SuperballShrink": "SuperballGrow",

	# --- Attack States ---
	"IdleAttack": "MoveAttack",
	"CrouchAttack": "IdleAttack",
	"MoveAttack": "Attack",
	"WalkAttack": "MoveAttack",
	"RunAttack": "MoveAttack",
	"SkidAttack": "MoveAttack",

	# --- Water & Flying States ---
	"WaterIdle": "Idle",
	"WaterMove": "Move",
	"WaterWalk": "WaterMove",
	"WaterJog": "WaterMove",
	"WaterRun": "WaterMove",
	"WaterCrouchMove": "CrouchMove",
	"WaterCrouchFall": "CrouchFall",
	"WaterIdleAttack": "IdleAttack",
	"WaterWalkAttack": "WalkAttack",
	"WaterRunAttack": "RunAttack",
	"SwimBump": "Bump",
	"WingIdle": "WaterIdle",
	"WingMove": "WaterMove",
	"WingWalk": "WaterWalk",
	"WingJog": "WaterJog",
	"WingRun": "WaterRun",
	"WingCrouchMove": "WaterCrouchMove",
	"WingCrouchFall": "WaterCrouchFall",
	"WingIdleAttack": "WaterIdleAttack",
	"WingWalkAttack": "WaterWalkAttack",
	"WingRunAttack": "WaterRunAttack",
	"FlyIdle": "SwimIdle",
	"FlyUp": "SwimUp",
	"FlyAttack": "SwimAttack",
	"FlyBump": "SwimBump",

	# --- Death States ---
	"DieFreeze": "DieFall",
	"DieIdle": "DieFall",
	"DieMove": "DieIdle",
	"DieRise": "DieFall",
	"DieFall": "Die", # SkyanUltra: Legacy fallback for death animations in 1.0.2.
	"FireDieFreeze": "DieFreeze",
	"FireDieIdle": "DieIdle",
	"FireDieMove": "DieMove",
	"FireDieRise": "DieRise",
	"FireDieFall": "DieFall",
}
#endregion

var palette_transform := true
var transforming := false

static var camera_right_limit := 999999

static var times_hit := 0


var can_run := true

var air_frames := 0

var swim_stroke := false

var skid_frames := 0

var on_ice := false

var simulated_velocity := Vector2.ZERO

func _ready() -> void:
	get_viewport().size_changed.connect(recenter_camera)
	show()
	$Checkpoint/Label.text = str(player_id + 1)
	$Checkpoint/Label.modulate = [Color("5050FF"), Color("F73910"), Color("1A912E"), Color("FFB762")][player_id]
	$Checkpoint/Label.visible = Global.connected_players > 1
	character = CHARACTERS[int(Global.player_characters[player_id])]
	apply_character_physics()
	apply_character_sfx_map()
	Global.can_pause = true
	Global.can_time_tick = true
	Global.level_theme_changed.connect(apply_character_physics)
	Global.level_theme_changed.connect(apply_character_sfx_map)
	Global.level_theme_changed.connect(set_power_state_frame)
	if Global.current_level.first_load and Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		Global.player_power_states[player_id] = "0"
	var cur_power_state = int(Global.player_power_states[player_id])
	power_state = get_node("PowerStates/" + physics_params("STARTING_POWER_STATE", POWER_PARAMETERS))
	power_state = $PowerStates.get_node(POWER_STATES[cur_power_state])
	if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
		camera.enabled = false
	handle_power_up_states(0)
	set_power_state_frame()
	handle_invincible_palette()
	if Global.level_editor == null:
		recenter_camera()

# SkyanUltra: Helper function for getting physics params.
func physics_params(type: String, params_dict: Dictionary = {}, key: String = "") -> Variant:
	var mult_applied = 1.0
	var is_movement = false
	# SkyanUltra: This is a stupid workaround for a stupid issue with this stupid
	# engine. I can't just set params_dict to physics_dict... So I have to do this
	# work around. I hate it. If anyone can fix it, then please. Do it.
	if params_dict == {}: params_dict = physics_dict
	for tag in ["WALK", "RUN", "AIR", "SWIM"]:
		if tag in type:
			is_movement = true
			break
	if "MULT" not in type and is_movement:
		if "ACCEL" in type or "SKID" in type:
			mult_applied = accel_mult
		elif "SPEED" in type:
			mult_applied = speed_mult
	if power_state != null:
		if key == "": key = power_state.state_name
		if key in params_dict:
			var state_dict = params_dict[key]
			if type in state_dict:
				var value = state_dict[type]
				if (value is int or value is float) and not (value is bool):
					return value * mult_applied
				return value
	if "Default" in params_dict:
		var default_dict = params_dict["Default"]
		if type in default_dict:
			var value = default_dict[type]
			if value is Dictionary:
				value = $ResourceSetterNew.get_variation_json(value).value
			if (value is int or value is float) and not (value is bool):
				return value * mult_applied
			return value
	print("NULL PARAMETER! Looking up: type='%s', key='%s'\nparams_dict='%s'" % [type, key, params_dict["Default"]])
	return null

func apply_character_physics() -> void:
	var apply_gameplay_changes = true
	var path = "res://Assets/Sprites/Players/" + character + "/CharacterInfo.json"
	if int(Global.player_characters[player_id]) > 3:
		path = path.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
	path = ResourceSetter.get_pure_resource_path(path)
	var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	
	# SkyanUltra: This section controls all CHARACTER PHYSICS values. This should be
	# preventing physics changes to stop potential cheating in modes like You VS. Boo
	# and Marathon mode.
	if apply_gameplay_changes:
		physics_dict = PHYSICS_PARAMETERS if Settings.file.difficulty.physics_style else CLASSIC_PARAMETERS
	for key in json.physics:
		if key in ["PHYSICS_PARAMETERS", "CLASSIC_PARAMETERS", "POWER_PARAMETERS", "ENDING_PARAMETERS"]:
			if apply_gameplay_changes:
				if get(key) is Dictionary and json.physics[key] is Dictionary:
					Global.merge_dict(get(key), json.physics[key])
				else:
					set(key, json.physics[key])
		else:
			if get(key) is Dictionary and json.physics[key] is Dictionary:
				Global.merge_dict(get(key), json.physics[key])
			else:
				set(key, json.physics[key])

func apply_classic_physics() -> void:
	var json = JSON.parse_string(FileAccess.open("res://Resources/ClassicPhysics.json", FileAccess.READ).get_as_text())
	for i in json:
		set(i, json[i])

func recenter_camera() -> void:
	%CameraHandler.recenter_camera()
	%CameraHandler.update_camera_barriers()

func reparent_camera() -> void:
	return

func actual_velocity_y():
	if gravity_vector.y >= 0:
		return velocity.y
	else:
		return -velocity.y

func editor_level_start() -> void:
	if PipeArea.exiting_pipe_id == -1:
		power_state = get_node("PowerStates").get_child(starting_power_state)
	handle_power_up_states(0)
	set_power_state_frame()
	camera_make_current()
	recenter_camera()
	state_machine.transition_to("Normal")
	if camera_right_limit <= global_position.x:
		camera_right_limit = 99999999
	await get_tree().create_timer(0.1, false).timeout
	if camera_right_limit <= global_position.x:
		camera_right_limit = 99999999


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_reload"):
		set_power_state_frame()

	# guzlad: noclip without dev only works while playtesting.
	if (Input.is_action_just_pressed("debug_noclip") or Input.is_action_just_pressed("jump_0")) and ((Global.debug_mode) or (Global.level_editor_is_playtesting())):
		if state_machine.is_state("NoClip"):
			state_machine.transition_to("Normal")
			Global.log_comment("NOCLIP Disabled")
		elif !Input.is_action_just_pressed("jump_0") and !state_machine.is_state("NoClip"):
			state_machine.transition_to("NoClip")
			Global.log_comment("NOCLIP Enabled")

	up_direction = -gravity_vector
	handle_collision_shapes()
	handle_step_collision()
	handle_directions()
	handle_projectile_firing(delta)
	handle_block_collision_detection()
	handle_star(delta)
	handle_hammer(delta)
	handle_wing_flight(delta)
	on_ice = %IceCheck.is_colliding() and is_on_floor()
	air_frames = (air_frames + 1 if is_on_floor() == false else 0)
	if is_actually_on_ceiling() and can_bump_sfx:
		bump_ceiling()
	elif is_actually_on_floor() and not is_invincible:
		land_on_ground()
		stomp_combo = 0
	elif actual_velocity_y() > 15:
		can_bump_sfx = true
	if not is_actually_on_floor() and not just_landed:
		can_land_sfx = true
	handle_water_detection()

const BUBBLE_PARTICLE = preload("uid://bwjae1h1airtr")

func handle_water_detection() -> void:
	var old_water = in_water
	if $Hitbox.monitoring:
		in_water = $Hitbox.get_overlapping_areas().any(func(area: Area2D): return area is WaterArea) or $WaterDetect.get_overlapping_bodies().is_empty() == false
	if old_water != in_water and in_water == false and flight_meter <= 0:
		water_exited()
	if in_water and old_water == false and flight_meter <= 0:
		water_entered()

func summon_bubble() -> void:
	var bubble = BUBBLE_PARTICLE.instantiate()
	bubble.global_position = global_position + Vector2(0, -16 if power_state.hitbox_size == "Small" else -32)
	add_sibling(bubble)

func _process(delta: float) -> void:
	handle_power_up_states(delta)
	handle_invincible_palette()
	if is_invincible:
		DiscoLevel.combo_meter = 100

func apply_gravity(delta: float) -> void:
	if in_water or flight_meter > 0:
		gravity = physics_params("SWIM_GRAVITY")
	else:
		if sign(gravity_vector.y) * velocity.y + physics_params("JUMP_HOLD_SPEED_THRESHOLD") > 0.0:
			gravity = calculate_speed_param("FALL_GRAVITY", velocity_x_jump_stored)
	velocity += (gravity_vector * ((gravity / (1.5 if low_gravity else 1.0)) / delta)) * delta
	var target_fall: float = physics_params("MAX_FALL_SPEED")
	if in_water:
		target_fall = physics_params("MAX_SWIM_FALL_SPEED")
	if gravity_vector.y >= 0:
		velocity.y = clamp(velocity.y, -INF, (target_fall / (1.2 if low_gravity else 1.0)))
	else:
		velocity.y = clamp(velocity.y, -(target_fall / (1.2 if low_gravity else 1.0)), INF)

func camera_make_current() -> void:
	camera.enabled = true
	camera.make_current()

func play_animation(animation_name := "", force := false) -> void:
	if sprite.sprite_frames == null: return
	animation_name = get_fallback_animation(animation_name)
	if sprite.scale.x == -1 and sprite.sprite_frames.has_animation("Left" + animation_name):
		animation_name = "Left" + animation_name
	if sprite.animation != animation_name or force:
		sprite.play(animation_name)

func get_fallback_animation(animation_name := "") -> String:
	if sprite.sprite_frames.has_animation(animation_name) == false and ANIMATION_FALLBACKS.has(animation_name):
		return get_fallback_animation(ANIMATION_FALLBACKS.get(animation_name))
	else:
		return animation_name

func apply_character_sfx_map() -> void:
	var path = "res://Assets/Sprites/Players/" + character + "/SFX.json"
	var custom_character := false
	if int(Global.player_characters[player_id]) > 3:
		custom_character = true
		path = path.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
	path = ResourceSetter.get_pure_resource_path(path)
	if FileAccess.file_exists(path) == false:
		AudioManager.load_sfx_map({})
		return
	var json = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	
	for i in json:
		var res_path = "res://Assets/Audio/SFX/" + json[i]
		res_path = ResourceSetter.get_pure_resource_path(res_path)
		if FileAccess.file_exists(res_path) == false or custom_character:
			var directory = "res://Assets/Sprites/Players/" + character + "/" + json[i]
			if int(Global.player_characters[player_id]) > 3:
				directory = directory.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
			directory = ResourceSetter.get_pure_resource_path(directory)
			if FileAccess.file_exists(directory):
				json[i] = directory
			else:
				json[i] = res_path
		else:
			json[i] = res_path
	
	AudioManager.load_sfx_map(json)

func refresh_hitbox() -> void:
	for i in $Hitbox.get_overlapping_areas():
		i.area_entered.emit($Hitbox)

func is_actually_on_floor() -> bool:
	if is_on_floor():
		return true
	else:
		for i in get_tree().get_nodes_in_group("CollisionRays"):
			if i.is_on_floor():
				return true
	return false

func is_actually_on_wall() -> bool:
	if is_on_wall():
		return true
	else:
		for i in get_tree().get_nodes_in_group("CollisionRays"):
			if i.is_on_wall():
				return true
	return false

func is_actually_on_ceiling() -> bool:
	if is_on_ceiling():
		return true
	else:
		for i in get_tree().get_nodes_in_group("CollisionRays"):
			if i.is_on_ceiling():
				return true
	return false

func enemy_bounce_off(add_combo := true, award_score := true) -> void:
	if add_combo:
		add_stomp_combo(award_score)
	jump_cancelled = sign(velocity.y * gravity_vector.y) >= 0.0 if physics_params("CLASSIC_BOUNCE_BEHAVIOR") else not Global.player_action_pressed("jump", player_id)
	await get_tree().physics_frame
	if Global.player_action_pressed("jump", player_id):
		velocity.y = sign(gravity_vector.y) * -physics_params("BOUNCE_JUMP_SPEED")
		if physics_params("CLASSIC_BOUNCE_BEHAVIOR"):
			if jump_cancelled:
				gravity = calculate_speed_param("FALL_GRAVITY", velocity_x_jump_stored)
		else:
			gravity = calculate_speed_param("JUMP_GRAVITY")
		has_jumped = true
	else:
		velocity.y = sign(gravity_vector.y) * -physics_params("BOUNCE_SPEED")

func add_stomp_combo(award_score := true) -> void:
	if stomp_combo >= 10:
		if award_score:
			if [Global.GameMode.CHALLENGE, Global.GameMode.BOO_RACE].has(Global.current_game_mode) or Settings.file.difficulty.inf_lives:
				Global.score += 10000
				score_note_spawner.spawn_note(10000)
			else:
				AudioManager.play_global_sfx("1_up")
				Global.lives += 1
				score_note_spawner.spawn_one_up_note()
	else:
		if award_score:
			Global.score += COMBO_VALS[stomp_combo]
			score_note_spawner.spawn_note(COMBO_VALS[stomp_combo])
		stomp_combo += 1

func land_on_ground() -> void:
	if can_land_sfx:
		AudioManager.play_sfx("land", global_position)
		just_landed = true
		can_land_sfx = false
		await get_tree().create_timer(0.1).timeout
		just_landed = false

func bump_ceiling() -> void:
	AudioManager.play_sfx("bump", global_position)
	velocity.y = sign(gravity_vector.y) * physics_params("CEILING_BUMP_SPEED")
	can_bump_sfx = false
	bumping = true
	await get_tree().create_timer(0.1).timeout
	AudioManager.kill_sfx(physics_params("JUMP_SFX", COSMETIC_PARAMETERS))
	await get_tree().create_timer(0.1).timeout
	bumping = false

func kick_anim() -> void:
	kicking = true
	await get_tree().create_timer(0.2).timeout
	kicking = false

var colour_palette: Texture = null

func stop_all_timers() -> void:
	for i in ["star_meter", "flight_meter", "hammer_meter"]:
		set(i, 0)

func handle_invincible_palette() -> void:
	sprite.material.set_shader_parameter("mode", !Settings.file.visuals.rainbow_style)
	sprite.material.set_shader_parameter("player_palette", $PlayerPalette.texture)
	sprite.material.set_shader_parameter("palette_size", colour_palette.get_width())
	sprite.material.set_shader_parameter("invincible_palette", $InvinciblePalette.texture)
	sprite.material.set_shader_parameter("invincible_palette_size", $InvinciblePalette.texture.get_height())
	sprite.material.set_shader_parameter("palette_idx", POWER_STATES.find(power_state.state_name))
	sprite.material.set_shader_parameter("enabled", (has_star or (palette_transform and transforming)))

func handle_block_collision_detection() -> void:
	if ["Pipe"].has(state_machine.state.name): return
	if is_on_ceiling():
		for i in %BlockCollision.get_overlapping_bodies():
			if i is Block:
				i.player_block_hit.emit(self)

func handle_directions() -> void:
	input_direction = 0
	if Global.player_action_pressed("move_right", player_id):
		input_direction = 1
	elif Global.player_action_pressed("move_left", player_id):
		input_direction = -1
	velocity_direction = sign(velocity.x)

# SkyanUltra: Moved projectile handling code into Player for compatibility
# with other power-states, and easier manipulation through parameters.
var projectile_amount = 0
var projectile_type = load("res://Scenes/Prefabs/Entities/Items/Fireball.tscn")

const POWER_PARAM_LIST = {
	"PARTICLE_ON_CONTACT": "PROJ_PARTICLE_ON_CONTACT",
	"SFX_COLLIDE": "PROJ_SFX_COLLIDE",
	"HAS_COLLISION": "PROJ_COLLISION",
	"PIERCE_COUNT": "PROJ_PIERCE_COUNT",
	"PIERCE_HITRATE": "PROJ_PIERCE_HITRATE",
	"BOUNCE_COUNT": "PROJ_BOUNCE_COUNT",
	"GROUND_BOUNCE": "PROJ_GROUND_BOUNCE",
	"WALL_BOUNCE": "PROJ_WALL_BOUNCE",
	"CEIL_BOUNCE": "PROJ_CEIL_BOUNCE",
	"COLLECT_COINS": "PROJ_COLLECT_COINS",
	"LIFETIME": "PROJ_LIFETIME",
	"GROUND_DECEL": "PROJ_GROUND_DECEL",
	"AIR_DECEL": "PROJ_AIR_DECEL",
	"GRAVITY": "PROJ_GRAVITY",
	"BOUNCE_HEIGHT": "PROJ_BOUNCE_HEIGHT",
	"MAX_FALL_SPEED": "PROJ_MAX_FALL_SPEED",
	"MOVE_SPEED_CAP": "PROJ_SPEED_CAP",
}

func handle_projectile_firing(delta: float) -> void:
	if physics_params("PROJ_TYPE", POWER_PARAMETERS) == "" or state_machine.state.name != "Normal":
		return
	if Global.player_action_just_pressed("action", player_id) and (projectile_amount < physics_params("MAX_PROJ_COUNT", POWER_PARAMETERS) or physics_params("MAX_PROJ_COUNT", POWER_PARAMETERS) < 0) and delta > 0:
		throw_projectile()

func throw_projectile() -> void:
	attacked.emit()
	projectile_type = load(physics_params("PROJ_TYPE", POWER_PARAMETERS) + ".tscn")
	var node = projectile_type.instantiate()
	var offset = physics_params("PROJ_OFFSET", POWER_PARAMETERS)
	var speed = physics_params("PROJ_SPEED", POWER_PARAMETERS)
	var speed_scaling = 0
	if physics_params("PROJ_SPEED_SCALING", POWER_PARAMETERS):
		speed_scaling = velocity.x * direction
	
	node.global_position = global_position - Vector2(offset[0] * direction, offset[1] * gravity_vector.y)
	if "direction" in node: node.direction = direction
	if "velocity" in node: node.velocity = Vector2((speed[0] + speed_scaling) * direction, -speed[1])
	if node is Projectile:
		node.is_friendly = true
		if "character" in node:
			node.character = character
		node.PARTICLE = load(physics_params("PROJ_PARTICLE", POWER_PARAMETERS) + ".tscn")
		for param in POWER_PARAM_LIST:
			node.set(param, physics_params(POWER_PARAM_LIST[param], POWER_PARAMETERS))
		node.MOVE_SPEED = speed[0] + speed_scaling
	call_deferred("add_sibling", node)
	projectile_amount += 1
	node.tree_exited.connect(func(): projectile_amount -= 1)
	AudioManager.play_sfx(physics_params("PROJ_SFX_THROW", POWER_PARAMETERS), global_position)
	attacking = true
	await get_tree().create_timer(0.1, false).timeout
	attacking = false

func handle_power_up_states(delta) -> void:
	power_state.update(delta)

func handle_collision_shapes() -> void:
	var collision_size = physics_params("COLLISION_SIZE")
	var hitbox_size = physics_params("COLLISION_SIZE")
	if crouching:
		collision_size = physics_params("CROUCH_COLLISION_SIZE")
		if not normal_state.wall_pushing:
			hitbox_size = physics_params("CROUCH_COLLISION_SIZE")
	collision_size = Vector2(collision_size[0], collision_size[1])
	hitbox_size = Vector2(hitbox_size[0], hitbox_size[1])
	collision_size.x = max(collision_size.x, 6)
	collision_size.y = max(collision_size.y, 8)
	%Collision.sloped_floor_corner = physics_params("ROUNDED_FLOOR_COLLISION")
	%Collision.hitbox = collision_size
	$Hitbox/Shape.shape.size = hitbox_size + Vector2(0.2, 0.2)
	%BlockCollision.position.y = -collision_size.y
	$BlockCollision/Shape.shape.size.x = collision_size.x

func handle_step_collision() -> void:
	var collision_size = physics_params("COLLISION_SIZE")
	if crouching:
		collision_size = physics_params("CROUCH_COLLISION_SIZE")
	collision_size = Vector2(collision_size[0], collision_size[1])
	for i in get_tree().get_nodes_in_group("StepCollision"):
		var on_wall := false
		for x in [$StepWallChecks/LWall, $StepWallChecks/RWall]:
			x.position.x = ((collision_size.x / 2) + 1) * sign(x.position.x)
			if x.is_colliding():
				on_wall = true
		var step_enabled = (not on_wall and (actual_velocity_y()) >= 0 and abs(velocity.x) > 5)
		i.set_deferred("disabled", not step_enabled)
		i.position.x = ((collision_size.x / 2)) * sign(i.position.x)
		i.position.x += 1 * sign(i.position.x)

func handle_star(delta:float) -> void:
	star_meter -= delta
	if star_meter <= 0 and has_star:
		on_star_timeout()
	
func handle_hammer(delta:float) -> void:
	hammer_meter -= delta
	if hammer_meter <= 0 and has_hammer:
		has_hammer = false
		AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.HAMMER)
	%HammerSprite.visible = has_hammer
	%HammerHitbox.collision_layer = has_hammer
	if has_hammer:
		var hammer_offset = physics_params("HAMMER_OFFSET", COSMETIC_PARAMETERS)
		%HammerSprite.offset = Vector2(hammer_offset[0], hammer_offset[1])

func handle_wing_flight(delta: float) -> void:
	flight_meter -= delta
	if flight_meter <= 0 and has_wings:
		has_wings = false
		AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.WING)
		gravity = calculate_speed_param("FALL_GRAVITY", velocity_x_jump_stored)
	%Wings.visible = flight_meter > 0
	var wing_offset = physics_params("WING_OFFSET", COSMETIC_PARAMETERS)
	%Wing.offset = Vector2(wing_offset[0], wing_offset[1])
	if flight_meter <= 0:
		return
	if normal_state.swim_up_meter > 0:
		%Wing.play("Flap")
	else:
		%Wing.play("Idle")
	if flight_meter <= 3:
		%Wings.get_node("AnimationPlayer").play("Flash")
	else:
		%Wings.get_node("AnimationPlayer").play("RESET")

func damage(type: String = "") -> void:
	last_damage_source = type
	if can_hurt == false or is_invincible:
		return
	times_hit += 1
	var damage_state = power_state.damage_state
	if damage_state != null:
		damaged.emit()
		if Settings.file.difficulty.damage_style == 0:
			damage_state = get_node("PowerStates/" +  POWER_STATES[0])
		DiscoLevel.combo_meter -= 50
		AudioManager.play_sfx("damage", global_position)
		await power_up_animation(damage_state.state_name)
		power_state = get_node("PowerStates/" + damage_state.state_name)
		Global.player_power_states[player_id] = str(power_state.get_index())
		do_i_frames()
	else:
		die()

var cam_direction := 1
@onready var last_position := global_position

@onready var camera_position = camera.global_position
var camera_offset = Vector2.ZERO

func point_to_camera_limit(point := 0, point_dir := -1) -> float:
	return point + ((get_viewport_rect().size.x / 2.0) * -point_dir)

func point_to_camera_limit_y(point := 0, point_dir := -1) -> float:
	return point + ((get_viewport_rect().size.y / 2.0) * -point_dir)

func passed_checkpoint() -> void:
	if Settings.file.difficulty.checkpoint_style == 0:
		$Checkpoint/Animation.play("Show")
	AudioManager.play_sfx("checkpoint", global_position)

func do_i_frames() -> void:
	can_hurt = false
	for i in 25:
		sprite.hide()
		if get_tree() == null:
			return
		await get_tree().create_timer(0.04, false).timeout
		sprite.show()
		if get_tree() == null:
			return
		await get_tree().create_timer(0.04, false).timeout
	can_hurt = true
	refresh_hitbox()

var valid_death_types = ["", "Fire"]

func die(pit: bool = false, type: String = "") -> void:
	if ["Dead", "Pipe", "LevelExit"].has(state_machine.state.name):
		return
	if type != "": last_damage_source = type if type in valid_death_types else ""
	is_dead = true
	visible = not pit
	dead.emit()
	AudioManager.play_sfx("die_sting", global_position)
	Global.p_switch_active = false
	Global.p_switch_timer = 0
	stop_all_timers()
	Global.total_deaths += 1
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	state_machine.transition_to("Dead", {"Pit": pit})
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Level.can_set_time = true
	Level.first_load = true
	if Global.current_game_mode == Global.GameMode.MARATHON_PRACTICE:
		SpeedrunHandler.timer_active = false
	if physics_params("DEATH_HANG_TIMER", DEATH_PARAMETERS) > 0:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.SILENCE, 999, false)
		await get_tree().create_timer(physics_params("DEATH_HANG_TIMER", DEATH_PARAMETERS)).timeout
	if Global.current_game_mode != Global.GameMode.BOO_RACE:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.DEATH, 9999, false)
		await get_tree().create_timer(3).timeout
	else:
		AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.RACE_LOSE, 9999, false)
		await get_tree().create_timer(5).timeout

	death_load()

func fire_die() -> void: die(false, "Fire")

func death_load() -> void:
	power_state = get_node("PowerStates/" + physics_params("STARTING_POWER_STATE", POWER_PARAMETERS))
	Global.player_power_states[player_id] = "0"

	if Global.death_load:
		return
	Global.death_load = true

	# Handle lives decrement for CAMPAIGN and MARATHON
	if [Global.GameMode.CAMPAIGN, Global.GameMode.MARATHON].has(Global.current_game_mode):
		if Settings.file.difficulty.inf_lives == 0:
			Global.lives -= 1

	# Full dispatch table for death handling
	var death_actions = {
		Global.GameMode.CUSTOM_LEVEL: func():
			LevelTransition.level_to_transition_to = "res://Scenes/Levels/LevelEditor.tscn"
			Global.transition_to_scene("res://Scenes/Levels/LevelTransition.tscn"),

		Global.GameMode.LEVEL_EDITOR: func():
			Global.level_editor.stop_testing()
			Global.death_load = false,

		Global.GameMode.CHALLENGE: func():
			Global.transition_to_scene("res://Scenes/Levels/ChallengeMiss.tscn"),

		Global.GameMode.BOO_RACE: func():
			Global.reset_values()
			Global.clear_saved_values()
			Global.death_load = false
			Level.start_level_path = Global.current_level.scene_file_path
			Global.current_level.reload_level(),

		"time_up": func():
			Global.transition_to_scene("res://Scenes/Levels/TimeUp.tscn"),

		"game_over": func():
			Global.death_load = false
			Global.transition_to_scene("res://Scenes/Levels/GameOver.tscn"),

		"default_reload": func():
			LevelPersistance.reset_states()
			Global.current_level.reload_level()
	}

	# Determine which action to take
	if death_actions.has(Global.current_game_mode):
		death_actions[Global.current_game_mode].call()
	elif Global.lives <= 0 and Settings.file.difficulty.inf_lives == 0:
		death_actions["game_over"].call()
	elif Global.time <= 0:
		death_actions["time_up"].call()
	else:
		death_actions["default_reload"].call()

func time_up() -> void:
	die()

func set_power_state_frame() -> void:
	colour_palette = ResourceSetter.get_resource(preload("uid://b0quveyqh25dn"))
	$PlayerPalette/ResourceSetterNew.resource_json = (CHARACTER_PALETTES[int(Global.player_characters[player_id])])
	if power_state != null:
		$ResourceSetterNew.resource_json = load(get_character_sprite_path())
		$ResourceSetterNew.update_resource()
	var frames = %Sprite.sprite_frames
	if frames:
		can_pose_anim = frames.has_animation("PoseDoor")
		can_pose_castle_anim = frames.has_animation("PoseToad") or frames.has_animation("PosePeach")
		can_bump_jump_anim = frames.has_animation("JumpBump")
		can_bump_crouch_anim = frames.has_animation("CrouchBump")
		can_bump_swim_anim = frames.has_animation("SwimBump")
		can_bump_fly_anim = frames.has_animation("FlyBump")
		can_kick_anim = frames.has_animation("Kick")
		can_push_anim = frames.has_animation("Push")
		can_spring_land_anim = frames.has_animation("SpringLand")
		can_spring_fall_anim = frames.has_animation("SpringFall")
	$Checkpoint.position.y = physics_params("CHECKPOINT_ICON_HEIGHT", COSMETIC_PARAMETERS)
func get_power_up(power_name := "", give_points := true) -> void:
	if is_dead:
		return
	if give_points:
		Global.score += 1000
		DiscoLevel.combo_amount += 1
		score_note_spawner.spawn_note(1000)
	AudioManager.play_sfx("power_up", global_position)
	powered_up.emit()
	if Settings.file.difficulty.damage_style == 0 and power_state.state_name != power_name:
		if power_name != "Big" and power_state.state_name != "Big":
			power_name = "Big"
	var new_power_state = get_node("PowerStates/" + power_name)
	if power_state.power_tier <= new_power_state.power_tier and new_power_state != power_state:
		can_hurt = false
		await power_up_animation(power_name)
	else:
		return
	power_state = new_power_state
	Global.player_power_states[player_id] = str(power_state.get_index())
	handle_power_up_states(0)
	can_hurt = true
	refresh_hitbox()
	await get_tree().physics_frame
	check_for_block()

func check_for_block() -> void:
	if test_move(global_transform, (Vector2.UP * gravity_vector) * 4):
		crouching = true

func power_up_animation(new_power_state := "") -> void:
	if normal_state.jump_buffer > 0:
		normal_state.jump_buffer += 10

	var old_frames = sprite.sprite_frames
	var new_frames = $ResourceSetterNew.get_resource(load(get_character_sprite_path(new_power_state)))
	var old_state = power_state
	var new_state = get_node("PowerStates/" + new_power_state)

	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.show()
	get_tree().paused = true
	
	var hitbox_changed = new_state.power_tier != old_state.power_tier
	var shrinking = hitbox_changed and (new_state.power_tier < old_state.power_tier)
	var can_powerup_jump = Global.player_action_pressed("jump", player_id) == false
	var anim_name := ""
	if old_state.state_name != "Small" and new_power_state != "Small":
		if %Sprite.sprite_frames.has_animation(new_power_state + "Grow"): # SkyanUltra: Optional check for animations for going from Big to Fire-equivalent power states.
			anim_name = new_power_state + "Shrink" if shrinking else new_power_state + "Grow"
		else: anim_name = ""
	else:
		anim_name = "Shrink" if shrinking else "Grow"
	handle_invincible_palette()
	if hitbox_changed and anim_name != "":
		if Settings.file.visuals.transform_style == 0:
			sprite.speed_scale = 3
			play_animation(anim_name)
			
			var rainbow = physics_params("RAINBOW_POWERUP_FX", COSMETIC_PARAMETERS, new_power_state) or physics_params("RAINBOW_POWERUP_FX", COSMETIC_PARAMETERS, old_state.state_name)
			if rainbow:
				transforming = true
				sprite.material.set_shader_parameter("enabled", true)
			
			await get_tree().create_timer(0.4, true).timeout
			power_state = new_state
			sprite.sprite_frames = new_frames
			handle_invincible_palette()
			play_animation(anim_name, true)
			await get_tree().create_timer(0.4, true).timeout
			
			if rainbow:
				sprite.material.set_shader_parameter("enabled", false)
			transforming = false
		else:
			sprite.speed_scale = 0
			if shrinking:
				%GrowAnimation.play(anim_name)
			else:
				sprite.sprite_frames = new_frames
				%GrowAnimation.play(anim_name)
			await get_tree().create_timer(0.8, true).timeout
			sprite.sprite_frames = new_frames
			transforming = false

	else:
		if Settings.file.visuals.transform_style == 1:
			for i in 6:
				sprite.sprite_frames = new_frames
				await get_tree().create_timer(0.05).timeout
				sprite.sprite_frames = old_frames
				await get_tree().create_timer(0.05).timeout
		else:
			var rainbow = physics_params("RAINBOW_POWERUP_FX", COSMETIC_PARAMETERS, new_power_state) or physics_params("RAINBOW_POWERUP_FX", COSMETIC_PARAMETERS, old_state.state_name)
			if rainbow:
				transforming = true
				sprite.material.set_shader_parameter("enabled", true)
			handle_invincible_palette()
			sprite.stop()
			await get_tree().create_timer(0.6).timeout
			transforming = false
			if rainbow:
				sprite.material.set_shader_parameter("enabled", false)
	sprite.play("Idle")
	get_tree().paused = false
	sprite.process_mode = Node.PROCESS_MODE_INHERIT

	if Global.player_action_pressed("jump", player_id) and can_powerup_jump:
		jump()
	return

const RESERVE_ITEM = preload("res://Scenes/Prefabs/Entities/Items/ReserveItem.tscn")

func dispense_stored_item() -> void:
	add_sibling(RESERVE_ITEM.instantiate())

func get_character_sprite_path(power_stateto_use := power_state.state_name) -> String:
	character = Player.CHARACTERS[Global.player_characters[player_id]]
	var path = "res://Assets/Sprites/Players/" + character + "/" + power_stateto_use + ".json"
	if int(Global.player_characters[player_id]) > 3:
		path = path.replace("res://Assets/Sprites/Players", Global.config_path.path_join("custom_characters/"))
		if FileAccess.file_exists(path) == false:
			path = "res://Assets/Sprites/Players/Mario/" + power_stateto_use + ".json"
			Global.log_error("No sprite found for: " + character + "/" + power_stateto_use  + "!")
	return path

func enter_pipe(pipe: PipeArea, warp_to_level := true) -> void:
	z_index = -10
	can_bump_sfx = false
	Global.can_pause = false
	Global.can_time_tick = false
	pipe_enter_direction = pipe.get_vector(pipe.enter_direction)
	if pipe_enter_direction.x != 0:
		global_position.y = pipe.global_position.y + 14
	AudioManager.play_sfx("pipe", global_position)
	state_machine.transition_to("Pipe")
	PipeArea.exiting_pipe_id = pipe.pipe_id
	hide_pipe_animation()
	if warp_to_level:
		await get_tree().create_timer(1, false).timeout
		if Global.current_game_mode == Global.GameMode.LEVEL_EDITOR:
			LevelEditor.play_pipe_transition = true
			Global.level_editor.transition_to_sublevel(pipe.target_sub_level)
		elif Global.current_level is CustomLevel:
			Global.transition_to_scene(NewLevelBuilder.sub_levels[pipe.target_sub_level])
		else:
			Global.transition_to_scene(pipe.target_level)

func hide_pipe_animation() -> void:
	if pipe_enter_direction.x != 0:
		await get_tree().create_timer(0.3, false).timeout
		hide()
	else:
		await get_tree().create_timer(0.6, false).timeout
		hide()

var exiting_pipe := false

func go_to_exit_pipe(pipe: PipeArea) -> void:
	Global.can_time_tick = false
	exiting_pipe = true
	pipe_enter_direction = Vector2.ZERO
	state_machine.transition_to("Freeze")
	can_hurt = false
	global_position = pipe.global_position + (pipe.get_vector(pipe.enter_direction) * 32)
	reset_physics_interpolation()
	if pipe.enter_direction == 1:
		global_position = pipe.global_position + Vector2(0, -8)
	recenter_camera()
	if pipe.get_vector(pipe.enter_direction).y == 0:
		global_position.y += 16
		global_position.x -= 8 * pipe.get_vector(pipe.enter_direction).x
	reset_physics_interpolation()
	hide()

func do_earthquake() -> void:
	if is_on_floor():
		state_machine.transition_to("Stunned")

func exit_pipe(pipe: PipeArea) -> void:
	show()
	pipe_enter_direction = -pipe.get_vector(pipe.enter_direction)
	AudioManager.play_sfx("pipe", global_position)
	state_machine.transition_to("Pipe")
	can_hurt = false
	await get_tree().create_timer(0.65, false).timeout
	Global.can_pause = true
	can_hurt = true
	exiting_pipe = false
	state_machine.transition_to("Normal")
	Global.can_time_tick = true


func jump() -> void:
	if spring_bouncing:
		return
	velocity.y = calculate_jump_height(calculate_speed_param("JUMP_SPEED")) * gravity_vector.y
	velocity_x_jump_stored = velocity.x
	gravity = calculate_speed_param("JUMP_GRAVITY")
	AudioManager.play_sfx(physics_params("JUMP_SFX", COSMETIC_PARAMETERS), global_position)
	has_jumped = true
	jump_cancelled = false
	jumped.emit()
	await get_tree().physics_frame
	has_jumped = true

func calculate_speed_param(param = "", speed = velocity.x):
	if not physics_params("FALL_GRAVITY_PREDETERMINED"): speed = velocity.x
	if abs(speed) < physics_params("JUMP_WALK_THRESHOLD"):
		param += "_IDLE"
	elif abs(speed) < physics_params("JUMP_RUN_THRESHOLD"):
		param += "_WALK"
	else:
		param += "_RUN"
	return physics_params(param)

func calculate_jump_height(jump_height = physics_params("JUMP_SPEED_IDLE"), jump_incr = physics_params("JUMP_INCR")) -> float: # Thanks wye love you xxx
	return -(jump_height + jump_incr * int(abs(velocity.x) / 25))

const SMOKE_PARTICLE = preload("res://Scenes/Prefabs/Particles/SmokeParticle.tscn")

func teleport_player(new_position := Vector2.ZERO) -> void:
	hide()
	do_smoke_effect()
	var old_state = state_machine.state.name
	state_machine.transition_to("Freeze")
	await get_tree().create_timer(0.5, false).timeout
	global_position = new_position
	recenter_camera()
	await get_tree().create_timer(0.5, false).timeout
	state_machine.transition_to(old_state)
	show()
	velocity = Vector2.ZERO
	do_smoke_effect()

func do_smoke_effect() -> void:
	for i in 2:
		var node = SMOKE_PARTICLE.instantiate()
		node.global_position = global_position - Vector2(0, 16 * i)
		add_sibling(node)
		if power_state.hitbox_size == "Small":
			break
	AudioManager.play_sfx("magic", global_position)

func on_area_entered(area: Area2D) -> void:
	if area.owner is Player and area.owner != self:
		if area.owner.velocity.y > 0 and area.owner.is_actually_on_floor() == false:
			area.owner.enemy_bounce_off(false)
			velocity.y = sign(gravity_vector.y) * 50
			AudioManager.play_sfx("bump", global_position)
	elif area.owner is WaterArea:
		water_entered()


func super_star() -> void:
	if physics_params("STAR_TIME", POWER_PARAMETERS) <= 0:
		return
	is_invincible = true
	has_star = true
	sprite.material.set_shader_parameter("speed", physics_params("RAINBOW_STAR_FX_SPEED", COSMETIC_PARAMETERS))
	star_meter = clamp(physics_params("STAR_TIME", POWER_PARAMETERS) - 2, 0, INF)
	$CanvasLayer/Control2/MarginContainer/Timers/StarTimer/TimerSprite.max_value = star_meter
	DiscoLevel.combo_meter += 1
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.STAR, 1, false)

func hammer_get() -> void:
	if physics_params("HAMMER_TIME", POWER_PARAMETERS) <= 0:
		return
	has_hammer = true
	hammer_meter = physics_params("HAMMER_TIME", POWER_PARAMETERS)
	DiscoLevel.combo_meter += 1
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.HAMMER, 0, false)

func wing_get() -> void:
	if physics_params("WING_TIME", POWER_PARAMETERS) <= 0:
		return
	has_wings = true
	flight_meter = physics_params("WING_TIME", POWER_PARAMETERS)
	DiscoLevel.combo_meter += 1
	AudioManager.set_music_override(AudioManager.MUSIC_OVERRIDES.WING, 0, false, false)

func on_star_timeout() -> void:
	var time = clamp(physics_params("STAR_TIME", POWER_PARAMETERS), 0, 2) * 0.5
	sprite.material.set_shader_parameter("speed", physics_params("RAINBOW_STAR_SLOW_FX_SPEED", COSMETIC_PARAMETERS))
	await get_tree().create_timer(time, false).timeout
	AudioManager.stop_music_override(AudioManager.MUSIC_OVERRIDES.STAR)
	await get_tree().create_timer(time, false).timeout
	sprite.material.set_shader_parameter("speed", physics_params("RAINBOW_FX_SPEED", COSMETIC_PARAMETERS))
	if star_meter <= 0:
		has_star = false
		is_invincible = false

func water_exited() -> void:
	await get_tree().physics_frame
	if in_water: return
	normal_state.swim_up_meter = 0
	if actual_velocity_y() < 0:
		var holding_up = Global.player_action_pressed("move_up", player_id) if gravity_vector.y >= 0 else Global.player_action_pressed("move_down", player_id)
		velocity.y = sign(gravity_vector.y) * -physics_params("SWIM_EXIT_SPEED") if actual_velocity_y() < -50.0 or holding_up else velocity.y
	has_jumped = true
	if Global.player_action_pressed("move_up", player_id):
		gravity = calculate_speed_param("JUMP_GRAVITY")
	else:
		gravity = calculate_speed_param("FALL_GRAVITY", velocity_x_jump_stored)

func reset_camera_to_center() -> void:
	animating_camera = true
	var old_position = camera.position
	camera.global_position = get_viewport().get_camera_2d().get_screen_center_position()
	camera.reset_physics_interpolation()
	var tween = create_tween()
	tween.tween_property(camera, "position", old_position, 0.5)
	await tween.finished
	camera.position = old_position
	animating_camera = false

func on_area_exited(area: Area2D) -> void:
	if area is WaterArea:
		water_exited()

func water_entered() -> void:
	velocity.y = max(-physics_params("SWIM_HEIGHT"), velocity.y)


func on_modifier_applied() -> void:
	pass
