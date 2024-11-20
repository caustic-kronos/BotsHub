;############################
;#  by rheek				#
;#  modified by mhaendler	#
;# GWCA Update By 3vcloud	#
;# C+ to LUA   By MrJambix	#
;#  improved by night		#
;############################
; v1.7, source: github.com/rheek123/GwBotApiPatcher
;
; This file contains all headers that gwa2 uses to communicate with the gameservers directly.
; The headers are named variables. The names should indicate what the header is about.
; The comments give a litte more detail about what the header does.
;
; If you need to update the headers, the comments give hints about what action to trigger while recording CtoGS packets..
;
; Night edit : if you wish to have a better, updated list of those headers, look up Opcodes.h from GWCA, the values are the same

#include-once

; GAME_CMSG_ - Trade related
; Player trade
Global Const $HEADER_TRADE_PLAYER = 0x00		; Send trade request to player
Global Const $HEADER_TRADE_CANCEL = 0x01		; Cancels an ongoing trade
Global Const $HEADER_TRADE_ADD_ITEM = 0x02		; Adds an item to the trade window
;Global Const $HEADER_TRADE_CHANGE_OFFER = 0x02	; Change offer
Global Const $HEADER_TRADE_SUBMIT_OFFER = 0x03	; Submit offer
Global Const $HEADER_TRADE_OFFER_ITEM = 0x04	; Add item to trade window
Global Const $HEADER_TRADE_REMOVE_ITEM = 0x05	; Removes an item from the trade window
Global Const $HEADER_TRADE_CANCEL_OFFER = 0x06	; Cancels a previously sent trade offer
Global Const $HEADER_TRADE_ACCEPT = 0x07		; Accepts a trade offer
Global Const $HEADER_TRADE_INITIATE = 0x48		; Initiates a trade with another player
Global Const $HEADER_TRANSACT_ITEMS = 0x4C		; Confirms a transaction involving items

; NPC Trade
Global Const $HEADER_REQUEST_QUOTE = 0x4B		; Requests a quote or price for an item

; GAME_CMSG_ - Connection and Ping
Global Const $HEADER_DISCONNECT = 0x08			; Disconnects from the server or session
Global Const $HEADER_PING_REPLY = 0x09			; Sends a reply to a ping request
Global Const $HEADER_HEARTBEAT = 0x0A			; Sends a heartbeat signal to maintain connection
Global Const $HEADER_PING_REQUEST = 0x0B		; Requests a ping to check the connection status

; GAME_CMSG_ - Quests
Global Const $HEADER_QUEST_ABANDON = 0x10				; Abandons a selected quest
Global Const $HEADER_QUEST_REQUEST_INFOS = 0x11			; Requests information about a quest
Global Const $HEADER_QUEST_SET_ACTIVE_CONFIRMED = 0x13	; Confirms setting a quest as active
Global Const $HEADER_QUEST_ACCEPT = 0x3A				; Accepts a quest from the NPC
Global Const $HEADER_QUEST_REWARD = 0x3A				; Retrieves Quest reward from NPC

; GAME_CMSG_ - Heroes and NPCs
Global Const $HEADER_HERO_BEHAVIOR = 0x14		; Sets the behavior/aggression level of a hero
Global Const $HEADER_HERO_LOCK_TARGET = 0x15	; Locks a target for the hero
Global Const $HEADER_HERO_SKILL_TOGGLE = 0x18	; Toggles a hero's skill on or off
Global Const $HEADER_PARTY_PLACE_FLAG = 0x1A	; Sets the party position flag, all party-npcs runs to position
Global Const $HEADER_PARTY_CLEAR_FLAG = 0x1A	; Clears the party position flag
Global Const $HEADER_HERO_AGGRESSION = 0x14		; Sets the heroes aggression level
Global Const $HEADER_HERO_PLACE_FLAG = 0x19		; Sets the heroes position flag, hero runs to position
Global Const $HEADER_HERO_CLEAR_FLAG = 0x19		; Clears the heroes position flag
Global Const $HEADER_HERO_TOGGLE_SKILL = 0x1A	; Enables or disables the heroes skill
Global Const $HEADER_HERO_LOCK = 0x15			; Locks the heroes target
Global Const $HEADER_USE_HERO_SKILL = 0x1B		; For use with UseHeroSkillByPacket() only
Global Const $HEADER_HERO_ADD = 0x1D			; Adds a hero to the party
Global Const $HEADER_HERO_KICK = 0x1E			; Removes a hero from the party
Global Const $HEADER_HEROES_KICK = 0x1E			; Kicks ALL heroes from party

; GAME_CMSG_ - Targeting and Movement
Global Const $HEADER_CALL_TARGET = 0x22			; Calls the target without attacking (Ctrl+Shift+Space)
Global Const $HEADER_ATTACK_AGENT = 0x25		; Initiates an attack on a selected agent
Global Const $HEADER_CANCEL_ACTION = 0x27		; Cancels the current action
Global Const $HEADER_DRAW_MAP = 0x2A			; Draws on the map (for map pinging/markers)
Global Const $HEADER_AGENT_FOLLOW = 0x32		; Follows the agent/npc. Ctrl+Click triggers 'I am following Person' in chat
Global Const $HEADER_NPC_TALK = 0x38			; talks/goes to npc
Global Const $HEADER_MOVE_TO_COORD = 0x3D		; Moves to specified coordinates
Global Const $HEADER_INTERACT_ITEM = 0x3E		; Interacts with an item in the environment
Global Const $HEADER_ROTATE_PLAYER = 0x3F		; Rotates the player character

; GAME_CMSG_ - Inventory and Items
Global Const $HEADER_ITEM_DROP = 0x2B				; Drops item from inventory to ground
Global Const $HEADER_GOLD_DROP = 0x2E				; Drops gold from inventory to ground
Global Const $HEADER_ITEM_EQUIP = 0x2F				; Equips item from inventory/chest/no idea
Global Const $HEADER_ITEM_PICKUP = 0x3E				; Picks up an item from ground
Global Const $HEADER_UNEQUIP_ITEM = 0x4E			; Unequips an item
Global Const $HEADER_SIGNPOST_RUN = 0x50			; Runs to signpost
Global Const $HEADER_SEND_SIGNPOST_DIALOG = 0x52	; Sends a dialog or interaction to a signpost
Global Const $HEADER_EQUIP_VISIBILITY = 0x56		; Toggles the visibility of equipped items
Global Const $HEADER_ITEM_DESTROY = 0x68			; Destroys the item
Global Const $HEADER_ITEM_APPLY_DYE = 0x69			; Applies dye to an item
Global Const $HEADER_TOME_UNLOCK_SKILL = 0x6C		; Unlocks a skill using a tome
Global Const $HEADER_ITEM_MOVE = 0x71				; Moves an item within the inventory
Global Const $HEADER_EQUIP_BAG = 0x71
Global Const $HEADER_ITEMS_ACCEPT_UNCLAIMED = 0x72	; Accepts ITEMS not picked up in missions
Global Const $HEADER_ITEM_MOVE_EX = 0x74			; Moves an item, with amount to be moved.
Global Const $HEADER_ITEM_SPLIT_STACK = 0x74		; Splits a stack of items
Global Const $HEADER_CHANGE_GOLD = 0x7B				; Moves Gold (from chest to inventory, and otherway around IIRC)
Global Const $HEADER_ITEM_USE = 0x7D				; Uses item from inventory/chest
Global Const $HEADER_UPGRADE_ARMOR_1 = 0x84			; used by gwapi. is it even useful? NOT TESTED
Global Const $HEADER_UPGRADE_ARMOR_2 = 0x87			; used by gwapi. is it even useful? NOT TESTED
Global Const $HEADER_UPGRADE = 0x87					; used by gwapi. is it even useful? NOT TESTED

; Identify and Salvage
Global Const $HEADER_ITEM_ID = 0x6B					; Identifies item in inventory
Global Const $HEADER_SALVAGE_SESSION = 0x76			; Salvages mods from item
Global Const $HEADER_SALVAGE_SESSION_CANCEL = 0x77	; Salvages mods from item
Global Const $HEADER_SALVAGE_SESSION_DONE = 0x78	; Salvages mods from item
Global Const $HEADER_SALVAGE_MATS = 0x79			; Salvages materials from item
Global Const $HEADER_SALVAGE_MODS = 0x7A			; Salvages mods from item

; GAME_CMSG_ - Instance Management
Global Const $HEADER_INSTANCE_LOAD_REQUEST_SPAWN = 0x87		; Requests spawn in an instance
Global Const $HEADER_INSTANCE_LOAD_REQUEST_PLAYERS = 0x8F	; Requests player information in an instance
Global Const $HEADER_INSTANCE_LOAD_REQUEST_ITEMS = 0x90		; Requests item information in an instance
Global Const $HEADER_MODE_SWITCH = 0x9A						; Toggles hard- and normal mode
Global Const $HEADER_PARTY_ACCEPT_INVITE = 0x9B				; Accepts a party invitation
Global Const $HEADER_INVITE_CANCEL = 0x9C					; Cancel invitation of player
Global Const $HEADER_PARTY_ACCEPT_REFUSE = 0x9D				; Refuses a party invitation
Global Const $HEADER_HENCHMAN_ADD = 0x9E					; Adds henchman to party
Global Const $HEADER_INVITE_TARGET = 0x9F					; Invite target player to party
Global Const $HEADER_PARTY_INVITE_PLAYER_NAME = 0xA0		; Invites a player to the party by name
Global Const $HEADER_PARTY_LEAVE = 0xA1						; Leaves the party
Global Const $HEADER_PARTY_CANCEL_ENTER_CHALLENGE = 0xA2	; Cancels entry into a challenge or mission
Global Const $HEADER_MISSION_ENTER = 0xA4					; Enter a mission/challenge
Global Const $HEADER_OUTPOST_RETURN = 0xA6					; Returns to outpost after /resign
Global Const $HEADER_HENCHMAN_KICK = 0xA7					; Kicks a henchman from party
Global Const $HEADER_PARTY_KICK_PLAYER = 0xA8				; Kicks a player from the party
Global Const $HEADER_PARTY_SEARCH_SEEK = 0xA9				; Seeks members for party formation
Global Const $HEADER_PARTY_SEARCH_CANCEL = 0xAA				; Cancels a party search
Global Const $HEADER_PARTY_SEARCH_REQUEST_JOIN = 0xAB		; Requests to join a party search
Global Const $HEADER_PARTY_SEARCH_REQUEST_REPLY = 0xAC		; Replies to a party search join request
Global Const $HEADER_MISSION_FOREIGN_ENTER = 0xAC			; Enters a foreign mission/challenge (no idea honestly)
Global Const $HEADER_PARTY_SEARCH_TYPE = 0xAD				; Sets the type of party search
Global Const $HEADER_PARTY_READY_STATUS = 0xAE				; Indicates ready status in a party


;=BUFFS=
Global Const $HEADER_STOP_MAINTAIN_ENCH = 0x28	; Drops buff, cancel enchantmant, whatever you call it

;=TRAVEL=
Global Const $HEADER_MAP_TRAVEL = 0xB0			; Travels to outpost via worldmap
Global Const $HEADER_GUILDHALL_TRAVEL = 0xAF	; Travels to guild hall
Global Const $HEADER_GUILDHALL_LEAVE = 0xB1		; Leaves Guildhall

;=FACTION=
Global Const $HEADER_FACTION_DONATE = 0x34		; Donates kurzick/luxon faction to ally

;=TITLE=
Global Const $HEADER_TITLE_DISPLAY = 0x57		; Displays title
Global Const $HEADER_TITLE_CLEAR = 0x58			; Hides title
Global Const $HEADER_TITLE_TRACK_INFO = 0x76
Global Const $HEADER_TITLE_UPDATE = 0xF5

;=DIALOG=
Global Const $HEADER_DIALOG = 0x3A				; Sends a dialog to NPC
Global Const $HEADER_HOM_DIALOG = 0x59
Global Const $HEADER_CINEMATIC_SKIP = 0x62		; Skips the cinematic

; GAME_CMSG_ - Attributes and Skills
Global Const $HEADER_ATTRIBUTE_DECREASE = 0x0C		; Decreases a player's attribute level
Global Const $HEADER_ATTRIBUTE_INCREASE = 0x0D		; Increases a player's attribute level
Global Const $HEADER_ATTRIBUTE_LOAD = 0x0E			; Loads a set of player attributes
Global Const $HEADER_SET_ATTRIBUTES = 0x0F			; hidden in init stuff like sendchat
Global Const $HEADER_CHANGE_SECONDARY = 0x40		; Changes Secondary class (from Build window, not class changer)
Global Const $HEADER_OPEN_SKILLS = 0x41
Global Const $HEADER_USE_SKILL = 0x45
Global Const $HEADER_PROFESSION_ULOCK = 0x41
Global Const $HEADER_SKILL_USE_ALLY = 0x4C			; used by gwapi. appears to have changed
Global Const $HEADER_SKILL_USE_FOE = 0x4C			; used by gwapi. appears to have changed
Global Const $HEADER_SKILL_USE_ID = 0x4C			;
Global Const $HEADER_SET_SKILLBAR_SKILL = 0x5B		; Changes a skill on the skillbar
Global Const $HEADER_LOAD_SKILLBAR = 0x5C			; Loads a complete build
Global Const $HEADER_SKILLBAR_SKILL_REPLACE = 0x5D	; Replaces a skill in the skill bar
Global Const $HEADER_PLAYER_ATTR_UPDATE = 0x87
Global Const $HEADER_PLAYER_ATTR_SET = 0x98

;=CHEST=
Global Const $HEADER_OPEN_CHEST = 0x52

;=CHAT=
Global Const $HEADER_SEND_CHAT = 0x63				; Needed for sending messages in chat

;=MOVEMENT=
Global Const $HEADER_MOVEMENT_TICK = 0x1F

;=OTHER CONSTANTS=
Global Const $HEADER_MAX_ATTRIBUTES_CONST_5 = 0x03	; constant at word 5 of max attrib packet. Changed from 3 to four in most recent update
Global Const $HEADER_MAX_ATTRIBUTES_CONST_22 = 0x03	; constant at word 22 of max attrib packet. Changed from 3 to four in most recent update
Global Const $HEADER_OPEN_GB_WINDOW = 0x9F
Global Const $HEADER_CLOSE_GB_WINDOW = 0xA0
Global Const $HEADER_START_RATING_GVG = 0xA9