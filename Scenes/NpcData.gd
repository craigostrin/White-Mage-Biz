class_name NpcData
extends Resource

#enum types {ADVENTURER, TRAVELER, TRADER}

export(String) var username = 'ThisIsTheLongestName'

# enums for these are in Static singleton
var status = -1 # NO_TP
var destination = null # destinations are dictionaries
var willing_to_pay = -1

#export(types) var type = 0
