extends Node

onready var nameGen = $NameGenerator
onready var tpRequestTimer = $TpRequestTimer
onready var shoutTimer = $ShoutTimer
var rng = RandomNumberGenerator.new()

#export(int) var max_NPCs = 20
#export(int) var max_customers = 5
#export(int) var min_name_length = 2
#export(int) var max_name_length = 15

var current_zone: Node2D
var local_NPCs = []
var customers = []
var tp_request_index = 0
export(float) var tp_request_min_time = 1.0
export(float) var tp_request_max_time = 5.0
export(bool) var shouts_on = true # DEBUG
var shout_index = 0
export(float) var shout_min_time = 0.5
export(float) var shout_max_time = 3.0

func _ready():
	Events.connect('cmd_invite', self, '_on_cmd_invite_received')
	Events.connect('party_member_kicked', self, '_on_party_member_kicked')
	
	rng.randomize()


#############
# NPC SETUP #
#############

# This should probably take the args for maxNPCs and maxCustomers
### Parent will grab values from the zone or change things based on story state 
func setup_npcs(max_npcs, max_customers, min_name_length, max_name_length):
	if local_NPCs.size() > 0:
		_clear_npcs_and_customers()
	
	for _i in range(max_npcs):
		var new_npc = create_npc(nameGen.generate(min_name_length, max_name_length))
		local_NPCs.append(new_npc)
#		print(new_npc.username + ' added to local NPCs.')
		
		if customers.size() < max_customers:
			turn_npc_into_customer(new_npc)
			assign_random_destination(new_npc)
#			print(new_npc.username + " is a customer!")
	
#	print(str(local_NPCs.size()) + ' NPCs created in this zone.')


func _clear_npcs_and_customers():
	local_NPCs.clear()
	customers.clear()
	print('cleared')


func create_npc(username: String):
	var new_npc = NpcData.new()
	new_npc.username = username
	
	return new_npc


func turn_npc_into_customer(npc):
	if current_zone.has_method('base_payment_get'):
		npc.willing_to_pay = current_zone.base_payment
		npc.status = Static.customer_status.CUSTOMER
		customers.append(npc)
	else:
		print('Don\'t bother ' + npc.username + ', there\'s no market here.')


func assign_random_destination(npc):
	var keys = Static.destinations.keys() # Returns an array of the Dict's keys: [City1, City2, etc]
	var random_index = randi() % keys.size()
	var random_dest_key = keys[random_index]
	
	# Assign the destination's dictionary to the NPC
	npc.destination = Static.destinations[random_dest_key]


func _on_cmd_invite_received(target):
	
	for npc in local_NPCs:
		if npc.username == target:
			if npc.status == Static.customer_status.CUSTOMER:
				# Signal must come before add_to_party to send correct message
				Events.emit_signal('cmd_invite_processed', npc.username, npc.status)
				customers.erase(npc)
				Events.emit_signal('invite_accepted', npc)
				return
			else: 
				Events.emit_signal('cmd_invite_processed', npc.username, npc.status)
				return
	
	# If target not found in local_NPCs
	Events.emit_signal('cmd_invite_processed', target)

func _on_party_member_kicked(npc: NpcData):
	turn_npc_into_customer(npc)

#######################
# TELEPORT REQUESTING #
#######################

# LATER: maybe create a timer per customer? randomly select ppl from local_NPCs
func _on_TpRequestTimer_timeout():

	if customers.size() == 0:
		return
	
	if tp_request_index > customers.size() - 1:
		tp_request_index = 0
	
	var requester = customers[tp_request_index]
	var dest_key = requester.destination
	tp_request_index += 1
	
	request_teleport(requester, dest_key)
	
	# set random time for next timer
	var random_float = rng.randf_range(tp_request_min_time, tp_request_max_time)
	tpRequestTimer.start(random_float)


func request_teleport(requester: NpcData, destination):
	Events.emit_signal('teleport_requested', requester, destination)


#################
# RANDOM SHOUTS #
#################

func _on_ShoutTimer_timeout():
	if not local_NPCs.size() > 0:
		return
	
	# Choose random non-party NPC
	if shouts_on: # DEBUG
		# Emit signal with NPC (connected to Chatbox)
		pass # Replace with function body.
		
	# set random time for next timer
	var random_float = rng.randf_range(shout_min_time, shout_max_time)
	shoutTimer.start(random_float)
