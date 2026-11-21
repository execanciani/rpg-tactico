class_name CampaignManager
extends RefCounted

const MISSION_PATHS: Array[String] = [
	"res://data/missions/mission_01.tres",
	"res://data/missions/mission_02.tres",
	"res://data/missions/mission_03.tres",
]

var current_mission_index := 0
var missions: Array[MissionData] = []
var profile := CampaignProfile.new()

func load_catalog() -> void:
	missions.clear()
	for path in MISSION_PATHS:
		var mission := load(path) as MissionData
		if mission != null:
			missions.append(mission)
	current_mission_index = clampi(current_mission_index, 0, maxi(0, missions.size() - 1))
	if profile.hero_progress.is_empty():
		profile.initialize_default()

func current_mission() -> MissionData:
	if missions.is_empty():
		return null
	return missions[current_mission_index]

func has_next_mission() -> bool:
	return current_mission_index + 1 < missions.size()

func advance() -> bool:
	if not has_next_mission():
		return false
	current_mission_index += 1
	return true
