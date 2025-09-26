extends VBoxContainer

var page_number := 1
@onready var http_request: HTTPRequest = $HTTPRequest

const LSS_URL := "https://levelsharesquare.com"

signal closed
signal level_selected(container: OnlineLevelContainer)

var list := {}
const ONLINE_LEVEL_CONTAINER = preload("uid://cr2pku7fjkgpo")

var filter = 0
var selected_lvl_idx := -1
var order := 0
static var number_of_pages := -1

func _ready() -> void:
	set_process(false)

func open(refresh_list := true) -> void:
	show()
	if refresh_list:
		grab_levels()
	await get_tree().physics_frame
	if selected_lvl_idx >= 0:
		%OnlineLevelList.get_child(selected_lvl_idx).grab_focus()
	else:
		%RefreshList.grab_focus()
	set_process(true)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_back"):
		closed.emit()
		close()

func close() -> void:
	set_process(false)
	hide()

func grab_levels() -> void:
	selected_lvl_idx = -1
	%OverloadMSG.hide()
	%ErrorMSG.hide()
	http_request.cancel_request()
	for i in %OnlineLevelList.get_children():
		i.queue_free()
	$LoadingMSG.show()
	var filter_str = ["", "", "&sort=plays", "&sort=rating"][filter]
	var get_type = ["featured?", "get?", "get?", "get?"][filter]
	var page_str = "&page=" + str(page_number)
	var url = LSS_URL + "/api/levels/filter/" + get_type + "game=" + str(Global.LSS_GAME_ID) + "&authors=1" + filter_str + page_str + "&sortType=" + str(order)
	http_request.request(url, [], HTTPClient.METHOD_GET)

func level_list_retrieved(result := 0, response_code := 0, headers: PackedStringArray = [], body: PackedByteArray = []) -> void:
	$LoadingMSG.hide()
	var string = body.get_string_from_utf8()
	if response_code != HTTPClient.RESPONSE_OK:
		%ErrorMSG.show()
		return
	if string == "Too many requests, please slow down!":
		%OverloadMSG.show()
		return
	var json = JSON.parse_string(string)
	list = json
	spawn_containers()
	%Page.values.clear()
	number_of_pages = json.numberOfPages
	setup_page_numbers()

func setup_page_numbers() -> void:
	for i in number_of_pages:
		%Page.values.append(str(int(i + 1)))

func spawn_containers() -> void:
	$HSeparator.show()
	for i in list.levels:
		var container = ONLINE_LEVEL_CONTAINER.instantiate()
		container.level_name = i.name
		if i.has("status"):
			container.featured = i.status == "Featured"
		container.level_author = i.author.username
		container.difficulty = i.difficulty
		container.level_id = i._id
		container.ratings = i.rates
		container.level_selected.connect(show_info)
		if i.has("thumbnail"):
			if i.thumbnail != null:
				container.thumbnail_url = i.thumbnail
		%OnlineLevelList.add_child(container)

func show_info(container: OnlineLevelContainer) -> void:
	selected_lvl_idx = container.get_index()
	level_selected.emit(container)

func set_filter(filter_idx := 0) -> void:
	filter = filter_idx
	grab_levels()

func set_page(page_idx := 0) -> void:
	page_number = page_idx + 1
	grab_levels()

func set_order(order_idx := 0) -> void:
	order = [-1, 1][order_idx]
	grab_levels()
