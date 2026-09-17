class_name BackendModels
extends RefCounted
## Data returned by the Backend service. Mirrors the planned Nakama RPC payloads.


class Profile:
	extends RefCounted

	## Server account id; shown to colleagues as a profile QR code.
	var user_id: String = ""
	var balance: int = 0
	var streak_days: int = 1
	## Reward multiplier for the current streak, e.g. 1.5.
	var multiplier: float = 1.0
	var welcome_bonus: int = 0
	var car_id: String = "vaz2104"
	var car_name: String = ""
	var car_speed_kmh: int = 110
	var outfit: Dictionary = {}


class TaskInfo:
	extends RefCounted

	var id: String
	var title: String
	var description: String
	var room: StringName
	## Office map cell where the player stands to start the task.
	var spot: Vector2i
	var minigame: String
	## Screen-only minigame used when the device lacks the sensors `minigame` needs; empty = none.
	var fallback_minigame: String = ""
	## Minigame settings from the admin panel, e.g. {"steps": 120}.
	var params: Dictionary = {}
	var base_reward: int
	## Final reward: base reward x difficulty multiplier x streak multiplier.
	var reward: int
	## normal | hard | very_hard
	var difficulty: String = "normal"
	var difficulty_multiplier: float = 1.0
	var skippable: bool = false
	var completed: bool
	var skipped: bool

	## Completed or skipped: nothing left to do today.
	func is_closed() -> bool:
		return completed or skipped


class TaskResult:
	extends RefCounted

	var ok: bool = false
	var error: String = ""
	var reward: int = 0
	var balance: int = 0


class ShopOffer:
	extends RefCounted

	var offer_id: String
	var item_id: String
	var name: String
	var description: String
	var rarity: String
	var icon: int
	var base_price: int
	var price: int
	var discount_percent: int
	var purchased: bool


class ShopState:
	extends RefCounted

	var offers: Array[ShopOffer] = []
	## Unix time (seconds) when the assortment rotates.
	var refresh_at: int = 0


class PurchaseResult:
	extends RefCounted

	enum Status { GRANTED, PENDING_APPROVAL, FAILED }

	var status: Status = Status.FAILED
	var error: String = ""
	var balance: int = 0
	## Promo code or voucher text for instantly granted rewards.
	var voucher: String = ""


class ActionResult:
	extends RefCounted

	var ok: bool = false
	var error: String = ""


class WardrobeItem:
	extends RefCounted

	var slot: String
	var id: String
	var name: String
	var unlocked: bool
	## free | shop | streak
	var unlock_type: String = "free"
	## Shop item id for "shop", number of days for "streak".
	var unlock_value: String = ""


class WardrobeState:
	extends RefCounted

	var items: Array[WardrobeItem] = []
	var outfit: Dictionary = {}
	var streak_days: int = 1


class CarInfo:
	extends RefCounted

	var id: String
	var name: String
	var description: String
	var price: int
	var speed_kmh: int
	var owned: bool
	var selected: bool


class GarageState:
	extends RefCounted

	var cars: Array[CarInfo] = []
