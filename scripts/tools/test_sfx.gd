extends SceneTree
## Headless SFX smoke test: godot --headless -s res://scripts/tools/test_sfx.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	if not Engine.has_singleton("Sfx") and not get_root().has_node("/root/Sfx"):
		# Autoload appears as /root/Sfx
		pass
	var sfx := get_root().get_node_or_null("/root/Sfx")
	if sfx == null:
		push_error("TEST FAIL: /root/Sfx autoload missing")
		ok = false
	else:
		print("TEST: Sfx node OK")
		if sfx.has_method("play_arrow"):
			sfx.play_arrow()
			sfx.play_hire()
			sfx.play_kingdom_hit()
			print("TEST: play_* calls OK")
		else:
			push_error("TEST FAIL: play methods missing")
			ok = false
	for path in [
		"res://audio/sfx_arrow.wav",
		"res://audio/sfx_hire.wav",
		"res://audio/sfx_kingdom_hit.wav",
	]:
		if ResourceLoader.exists(path):
			var s = load(path)
			print("TEST: loaded ", path, " -> ", s)
			if s == null:
				ok = false
		else:
			push_error("TEST FAIL: missing %s" % path)
			ok = false
	print("TEST RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
