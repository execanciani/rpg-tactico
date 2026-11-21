class_name ExperienceRules
extends RefCounted

const MAX_LEVEL := 80
const MAX_EXPERIENCE_GAIN := 1_000_000_000

static func xp_for_next_level(level: int) -> int:
	if level < 1 or level >= MAX_LEVEL:
		return 0
	# Curva sublineal al inicio y progresivamente más exigente: 75 + 42 * nivel^1.48.
	return maxi(100, roundi(75.0 + 42.0 * pow(float(level), 1.48)))

static func total_xp_for_level(level: int) -> int:
	var safe_level := clampi(level, 1, MAX_LEVEL)
	var total := 0
	for current_level in range(1, safe_level):
		total += xp_for_next_level(current_level)
	return total

static func level_for_total_xp(total_experience: int) -> int:
	var safe_xp := maxi(0, total_experience)
	var level := 1
	while level < MAX_LEVEL and safe_xp >= total_xp_for_level(level + 1):
		level += 1
	return level

static func sp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return 4 if level % 10 == 0 else 2
