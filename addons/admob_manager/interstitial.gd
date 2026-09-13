extends Node

var _interstitial_ad: InterstitialAd
var _full_screen_content_callback := FullScreenContentCallback.new()

var android_unit_id := "ca-app-pub-7245685656323801/1172246289"
var ios_unit_id := "ca-app-pub-7245685656323801/1172246289"

func _ready() -> void:
	_full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Interstitial closed")
		get_tree().paused = false

		# Destroy ONLY here
		if _interstitial_ad:
			_interstitial_ad.destroy()
			_interstitial_ad = null
			

	_full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("Failed to show:", ad_error.message)
		# DO NOT unpause here
		# DO NOT destroy here


func _on_load_pressed() -> void:
	await get_tree().create_timer(0.5).timeout

	var unit_id := ""
	if OS.get_name() == "Android":
		unit_id = android_unit_id
	else:
		unit_id = ios_unit_id

	var load_callback := InterstitialAdLoadCallback.new()

	load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print("Failed to load:", error.message)
		get_tree().paused = false

	load_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		print("Interstitial loaded")
		_interstitial_ad = ad
		_interstitial_ad.full_screen_content_callback = _full_screen_content_callback
		await get_tree().process_frame
		get_tree().paused = true
		_interstitial_ad.show()

	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), load_callback)
