extends Node

var billing_client : BillingClient
var ads_disabled := false
var ad_unit_id = "ca-app-pub-7245685656323801/6643744015"
var first_loadup = false

# Your plugin nodes live inside this autoload
@onready var banner = $banner
@onready var interstitial = $interstitial
@onready var rewarded = $rewarded
@onready var rewarded_interstitial = $rewarded_intertitial

func _ready():
	print("ADMOB READY:", self)
	print("CHILDREN:", get_children())

	banner = $banner
	interstitial = $interstitial
	rewarded = $rewarded
	rewarded_interstitial = $rewarded_intertitial
	MobileAds.initialize()
	init_billing() ########################### DELETEMDKASL
	load_ads_disabled()

func _init_ads():
	if not ads_disabled:
		load_interstitial()



# ---------------------------------------------------------
# AD LOADING / SHOWING
# ---------------------------------------------------------

func load_interstitial():
	if ads_disabled:
		return
	interstitial._on_load_pressed()


func show_round_ad():
	if ads_disabled:
		return
	# Load + show interstitial (plugin auto-shows)
	interstitial._on_load_pressed()




func load_banner():
	if ads_disabled:
		return
	banner._on_load_banner_pressed()

func destroy_banner():
	banner.destroy_ad_view()

func load_rewarded():
	rewarded._on_load_pressed()

func load_rewarded_interstitial():
	rewarded_interstitial._on_load_pressed()


# ---------------------------------------------------------
# BILLING (unchanged)
# ---------------------------------------------------------

func init_billing():
	billing_client = BillingClient.new()
	billing_client.connected.connect(_on_billing_connected)
	billing_client.query_product_details_response.connect(_on_query_product_details_response)
	billing_client.query_purchases_response.connect(_on_query_purchases_response)
	billing_client.on_purchase_updated.connect(_on_purchase_updated)
	billing_client.consume_purchase_response.connect(_on_consume_purchase_response)
	billing_client.acknowledge_purchase_response.connect(_on_acknowledge_purchase_response)
	billing_client.start_connection()

func _on_billing_connected():
	billing_client.query_product_details(["ad_free"], BillingClient.ProductType.INAPP)
	billing_client.query_purchases(BillingClient.ProductType.INAPP)

func _on_query_product_details_response(result: Dictionary):
	if result.response_code != BillingClient.BillingResponseCode.OK:
		print("Product details failed: ", result.response_code, " ", result.debug_message)

func _on_query_purchases_response(result: Dictionary):
	if result.response_code == BillingClient.BillingResponseCode.OK:
		for purchase in result.purchases:
			_process_purchase(purchase)

func _on_purchase_updated(result: Dictionary):
	if result.response_code == BillingClient.BillingResponseCode.OK:
		for purchase in result.purchases:
			_process_purchase(purchase)

func _process_purchase(purchase: Dictionary):
	if "ad_free" in purchase.product_ids and purchase.purchase_state == BillingClient.PurchaseState.PURCHASED:
		ads_disabled = true
		_save_ads_disabled()

		if not purchase.is_acknowledged:
			billing_client.acknowledge_purchase(purchase.purchase_token)

func _on_consume_purchase_response(result: Dictionary):
	print("Consume purchase response: ", result)

func _on_acknowledge_purchase_response(result: Dictionary):
	if result.response_code == BillingClient.BillingResponseCode.OK:
		print("Acknowledge purchase success")
	else:
		print("Acknowledge purchase failed: ", result.response_code, " ", result.debug_message)

func _save_ads_disabled():
	var data = { "ads_disabled": ads_disabled }
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	file.store_var(data)


# ---------------------------------------------------------
# REWARDED CALLBACKS
# ---------------------------------------------------------

func _on_rewarded_watched():
	print("Rewarded watched!")

func _on_rewarded_interstitial_watched():
	print("Rewarded interstitial watched!")


# ---------------------------------------------------------
# SETTINGS
# ---------------------------------------------------------

func load_ads_disabled():
	if FileAccess.file_exists("user://settings.save"):
		var file = FileAccess.open("user://settings.save", FileAccess.READ)
		var data = file.get_var()
		ads_disabled = data.get("ads_disabled", false)
