extends RefCounted
class_name Enum
## Public enums used throughout the project


enum GroupingIndex {
	NONE,
	BATCH,
	SURFACE_TYPE,
}
enum SideAlertType {
	LOG,
	WARNING,
	ERROR,
}
enum SurfaceType { # 20 types
	#Resets the player position back to the nearest path point
	RESET,
	
	# Track Snow
	SNOW_MAIN,
	
	# Snow Particles
	SNOW_SIDE,
	
	# Many Snow Particles, Player Sinks Slightly
	SNOW_POWDER,
	
	# Many Snow Particles, Player Sinks, Speed Decrease
	SNOW_POWDER_HEAVY,
	
	# Speed Increase, Slippery
	ICE,
	
	# Unrideable. Causes the player to bounce off
	REBOUND,
	
	# No Trail
	ICE_WATER,
	
	# Many Snow Particles
	SNOW5,
	
	# Speed Decrease, Spark Particles. Rock Grinding Sounds
	ROCK,
	
	# Unrideable. Causes the player to bounce off
	REBOUND_ROCK,
	
	# No Trail, Ice Scraping Sound
	UNKNOWN,
	
	# No Trail, Wood Sounds?
	WOOD,
	
	# Slippery, Speed Decrease, Metal Sounds, Spark Particles
	METAL,
	
	# No Trail, Speed Increase, Scraping Sound
	UNKNOWN2,
	
	# Like standard snow?
	SNOW6,
	
	# Standard Sand
	SAND,
	
	# Player passes through
	NO_COLLISION,
	
	# Metal Sounds
	METAL_RAMP,
	
	# Metal Sounds
	METAL_RAMP2,
}
