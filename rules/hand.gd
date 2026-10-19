extends RefCounted
class_name HandRules

static func shuffle_with(cards: Array, rng: RandomNumberGenerator) -> void:
	var n = cards.size()
	for i in range(n - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

static func draw_card(player: Player) -> Card:
	if player.deck.size() == 0:
		return null
	var card = player.deck.pop_front()
	player.hand.append(card)
	return card

static func draw_cards(player: Player, n: int) -> int:
	var drawn := 0
	for i in range(n):
		if player.deck.size() == 0:
			break
		draw_card(player)
		drawn += 1
	return drawn

static func setup_player(player: Player, rng: RandomNumberGenerator, neutral_cards: Array = []) -> bool:
	if player.deck.size() < Constants.OPENING_LANES:
		return false
	for i in range(Constants.OPENING_LANES):
		var card = player.deck.pop_front()
		player.lanes[i].card = card
		player.lanes[i].state = Lane.LaneState.FACE_DOWN
	draw_cards(player, Constants.OPENING_HAND_SIZE)
	for nc in neutral_cards:
		player.deck.append(nc.copy())
	shuffle_with(player.deck, rng)
	return true

static func play_monster(player: Player, hand_index: int, lane_index: int, start_index: int) -> bool:
	if hand_index < 0 or hand_index >= player.hand.size():
		return false
	var card = player.hand[hand_index]
	if card.card_type != Card.CardType.MONSTER:
		return false
	if lane_index < 0 or lane_index >= Constants.LANES_PER_PLAYER:
		return false
	var lane = player.lanes[lane_index]
	if lane.state != Lane.LaneState.FLIPPED:
		return false
	if not GameEngine.can_pay(player, card.cost):
		return false
	var monster = Monster.new(card.name, card.size, lane_index, start_index, card.atk, card.hp)
	if not GameEngine.place_monster(player, lane_index, start_index, monster):
		return false
	GameEngine.pay_cost(player, card.cost)
	player.hand.remove_at(hand_index)
	return true

static func play_spell(player: Player, hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= player.hand.size():
		return false
	var card = player.hand[hand_index]
	if card.card_type != Card.CardType.SPELL:
		return false
	if not GameEngine.pay_cost(player, card.cost):
		return false
	player.trigger_log.append(card.effect_id)
	player.hand.remove_at(hand_index)
	player.discard.append(card)
	return true

static func set_trap(player: Player, hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= player.hand.size():
		return false
	var card = player.hand[hand_index]
	if card.card_type != Card.CardType.TRAP:
		return false
	if player.set_traps.size() >= Constants.MAX_SET_TRAPS:
		return false
	if not GameEngine.pay_cost(player, card.cost):
		return false
	player.hand.remove_at(hand_index)
	player.set_traps.append(card)
	return true

static func discard_from_hand(player: Player, hand_index: int) -> bool:
	if hand_index < 0 or hand_index >= player.hand.size():
		return false
	var card = player.hand[hand_index]
	player.hand.remove_at(hand_index)
	player.discard.append(card)
	return true