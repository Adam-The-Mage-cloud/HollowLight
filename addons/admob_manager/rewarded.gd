extends Node

var _rewarded_ad: RewardedAd
var _full_screen_content_callback := FullScreenContentCallback.new()
var _reward_listener := OnUserEarnedRewardListener.new()

var android_unit_id := "ca-app-pub-3940256099942544/5224354917"
var ios_unit_id := "ca-app-pub-3940256099942544/1712485313"

func _ready() -> void:
	_reward_listener.on_user_earned_reward = func(rewarded_item: RewardedItem) -> void:
		print("Reward earned:", rewarded_item.amount, rewarded_item.type)
		# Give the player their reward here.
		get_parent().rewarded_watched.emit()
	_full_screen_content_callback.on_ad_clicked = func() -> void:
		print("on_ad_clicked")
	_full_screen_content_callback.on_ad_impression = func() -> void:
		print("on_ad_impression")
	_full_screen_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("on_ad_showed_full_screen_content")
	_full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("on_ad_failed_to_show_full_screen_content")
	_full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("on_ad_dismissed_full_screen_content")
		if _rewarded_ad:
			_rewarded_ad.destroy()
			_rewarded_ad = null

func _on_load_pressed() -> void:
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null

	var unit_id := ""
	if OS.get_name() == "Android":
		unit_id = android_unit_id
	elif OS.get_name() == "iOS":
		unit_id = ios_unit_id

	var load_callback := RewardedAdLoadCallback.new()

	load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		print(error.message)

	load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		print("Rewarded ad loaded")

		_rewarded_ad = ad
		_rewarded_ad.full_screen_content_callback = _full_screen_content_callback
		_rewarded_ad.show(_reward_listener)

	RewardedAdLoader.new().load(unit_id, AdRequest.new(), load_callback)
