#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2026 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
#CE ===========================================================================

#include-once
#include <Array.au3>
#include 'JSON.au3'
#include 'Utils-Console.au3'

; ============================================================================
; Loot configuration - one decision per item
;
; The loot configuration JSON has three roots:
;	Items		item families > items > sub categories > leaf, each leaf holding one decision string:
;				'ignore'								the item is neither picked up nor touched in the bags
;				'[identify+]keep|salvage|sell|store'	the item is picked up, identified first when asked, then kept in the bags,
;														salvaged, sold or stored
;	Mods		weapon mods, inscriptions, runes and insignias, each leaf holding:
;				'ignore'				the mod is left on the item
;				'salvage+store'			the mod is salvaged out of items that are salvaged or sold, and stored
;				'salvage+sell'			same, but the salvaged mod is sold
;	Buy items	booleans, unchanged from the previous format
;
; Loaded configurations are kept in two maps:
;	$loot_decisions				leaf path -> decision, in display order
;	$inventory_management_cache	every path (leaves and groups) -> True when active, plus the derived '@' flags
;								a leaf is active when not ignored (items), salvaged (mods) or bought (buy items)
;								a group is active when all leaves below it are active
;
; Configurations saved in the previous format (one tree per action) are migrated on load.
; This file does not depend on the game and can be tested headless.
; ============================================================================

Global Const $LOOT_ROOT_ITEMS				= 'Items'
Global Const $LOOT_ROOT_MODS				= 'Mods'
Global Const $LOOT_ROOT_BUY					= 'Buy items'
Global Const $LOOT_ROOTS[]					= [$LOOT_ROOT_ITEMS, $LOOT_ROOT_MODS, $LOOT_ROOT_BUY]

Global Const $LOOT_KIND_ITEM				= 'item'
Global Const $LOOT_KIND_MOD					= 'mod'
Global Const $LOOT_KIND_BUY					= 'buy'

Global Const $LOOT_DECISION_IGNORE			= 'ignore'
Global Const $LOOT_FLAG_IDENTIFY			= 'identify'
Global Const $LOOT_ACTION_KEEP				= 'keep'
Global Const $LOOT_ACTION_SALVAGE			= 'salvage'
Global Const $LOOT_ACTION_SELL				= 'sell'
Global Const $LOOT_ACTION_STORE				= 'store'
Global Const $LOOT_ACTIONS[]				= [$LOOT_ACTION_KEEP, $LOOT_ACTION_SALVAGE, $LOOT_ACTION_SELL, $LOOT_ACTION_STORE]

; Families and leaves shared by the configuration and the item classifier
Global Const $LOOT_MONEY					= 'Gold'
Global Const $LOOT_WEAPONS_FAMILY			= 'Weapons and offhands'
Global Const $LOOT_LOW_REQ_RULE				= 'Low req max stats'
Global Const $LOOT_RARE_SKINS				= 'Rare skins'
Global Const $LOOT_OTHER_SKINS				= 'Other skins'
Global Const $LOOT_GREEN_RARITY				= 'Green'
Global Const $LOOT_WEAPON_MAX_REQ			= 13
Global Const $LOOT_WEAPON_TYPE_NAMES[]		= ['Axe', 'Sword', 'Dagger', 'Hammer', 'Scythe', 'Spear', 'Bow', 'Wand', 'Staff', 'Focus', 'Shield']
Global Const $LOOT_WEAPON_RARITY_NAMES[]	= ['White', 'Blue', 'Purple', 'Gold']
Global Const $LOOT_ARMOR_FAMILY				= 'Armor salvageables'
Global Const $LOOT_TROPHIES_FAMILY			= 'Trophies'
Global Const $LOOT_TROPHIES_NICHOLAS		= 'Nicholas trophies'
Global Const $LOOT_TROPHIES_RARE_MATERIALS	= 'Rare material trophies'
Global Const $LOOT_TROPHIES_COMMON_MATERIALS = 'Common material trophies'
Global Const $LOOT_TROPHIES_OTHER			= 'Other trophies'
Global Const $LOOT_BASIC_MATERIALS_FAMILY	= 'Basic Materials'
Global Const $LOOT_RARE_MATERIALS_FAMILY	= 'Rare Materials'
Global Const $LOOT_CONSUMABLES				= 'Consumables'
Global Const $LOOT_SCROLLS_FAMILY			= 'Scrolls'
Global Const $LOOT_OTHER_GOLD_SCROLLS		= 'Other gold scrolls'
Global Const $LOOT_OTHER_FAMILY				= 'Other items'
Global Const $LOOT_OTHER_STACKABLES			= 'Stackables'
Global Const $LOOT_OTHER_UNKNOWN			= 'Unknown items'
; Groups of the Mods root
Global Const $LOOT_WEAPON_MODS_GROUP		= 'Weapon mods'
Global Const $LOOT_INSCRIPTIONS_GROUP		= 'Inscriptions'
Global Const $LOOT_ARMOR_UPGRADES_GROUP		= 'Armor upgrades'

; Leaf path -> decision (string for items and mods, boolean for buy items), in display order
Global $loot_decisions[]
; Every path -> active flag, plus derived '@' flags - shared with the whole bot
Global $inventory_management_cache[]


#Region Decisions
;~ Kind of a configuration node from its path: item, mod, buy or empty when unknown
Func GetLootNodeKind($path)
	Local $first = StringInStr($path, '.') > 0 ? StringLeft($path, StringInStr($path, '.') - 1) : $path
	Switch $first
		Case $LOOT_ROOT_ITEMS
			Return $LOOT_KIND_ITEM
		Case $LOOT_ROOT_MODS
			Return $LOOT_KIND_MOD
		Case $LOOT_ROOT_BUY
			Return $LOOT_KIND_BUY
	EndSwitch
	Return ''
EndFunc


;~ Parse an item decision string into a map with keys ignore, identify and action
Func ParseItemDecision($decision)
	Local $result[]
	$decision = StringLower(StringStripWS($decision, 8))
	$result['ignore'] = ($decision == $LOOT_DECISION_IGNORE)
	$result['identify'] = False
	$result['action'] = $LOOT_ACTION_KEEP
	If $result['ignore'] Then Return $result
	Local $parts = StringSplit($decision, '+')
	For $i = 1 To $parts[0]
		Switch $parts[$i]
			Case $LOOT_FLAG_IDENTIFY
				$result['identify'] = True
			Case $LOOT_ACTION_KEEP, $LOOT_ACTION_SALVAGE, $LOOT_ACTION_SELL, $LOOT_ACTION_STORE
				$result['action'] = $parts[$i]
		EndSwitch
	Next
	Return $result
EndFunc


;~ Build an item decision string
Func FormatItemDecision($ignore, $identify, $action)
	If $ignore Then Return $LOOT_DECISION_IGNORE
	Return ($identify ? $LOOT_FLAG_IDENTIFY & '+' : '') & $action
EndFunc


;~ Parse a mod decision string into a map with keys salvage and store
Func ParseModDecision($decision)
	Local $result[]
	$decision = StringLower(StringStripWS($decision, 8))
	$result['salvage'] = StringLeft($decision, StringLen($LOOT_ACTION_SALVAGE)) == $LOOT_ACTION_SALVAGE
	$result['store'] = $result['salvage'] And StringInStr($decision, '+' & $LOOT_ACTION_STORE) > 0
	Return $result
EndFunc


;~ Build a mod decision string
Func FormatModDecision($salvage, $store)
	If Not $salvage Then Return $LOOT_DECISION_IGNORE
	Return $LOOT_ACTION_SALVAGE & '+' & ($store ? $LOOT_ACTION_STORE : $LOOT_ACTION_SELL)
EndFunc


;~ Return a valid decision for the node, whatever was found in the file
Func NormalizeLootDecision($path, $value)
	Switch GetLootNodeKind($path)
		Case $LOOT_KIND_BUY
			Return $value == True
		Case $LOOT_KIND_ITEM
			If Not IsString($value) Then Return $LOOT_DECISION_IGNORE
			Local $parsed = ParseItemDecision($value)
			Return FormatItemDecision($parsed['ignore'], $parsed['identify'], $parsed['action'])
		Case $LOOT_KIND_MOD
			If Not IsString($value) Then Return $LOOT_DECISION_IGNORE
			Local $parsed = ParseModDecision($value)
			Return FormatModDecision($parsed['salvage'], $parsed['store'])
	EndSwitch
	Return $LOOT_DECISION_IGNORE
EndFunc


;~ True when the decision makes the bot act on the node: item not ignored, mod salvaged, buy item bought
Func IsLootDecisionActive($path, $decision)
	Switch GetLootNodeKind($path)
		Case $LOOT_KIND_ITEM
			Return $decision <> $LOOT_DECISION_IGNORE
		Case $LOOT_KIND_MOD
			Return StringLeft($decision, StringLen($LOOT_ACTION_SALVAGE)) == $LOOT_ACTION_SALVAGE
		Case $LOOT_KIND_BUY
			Return $decision == True
	EndSwitch
	Return False
EndFunc


;~ True when the leaf exists in the loaded configuration
Func LootLeafExists($path)
	Return MapExists($loot_decisions, $path)
EndFunc


;~ Decision of an item leaf as a map with keys ignore, identify and action - Null when the leaf does not exist
Func GetLootItemDecision($path)
	If Not MapExists($loot_decisions, $path) Then Return Null
	Return ParseItemDecision($loot_decisions[$path])
EndFunc


;~ Decision of a mod leaf as a map with keys salvage and store - Null when the leaf does not exist
Func GetLootModDecision($path)
	If Not MapExists($loot_decisions, $path) Then Return Null
	Return ParseModDecision($loot_decisions[$path])
EndFunc


;~ Set one decision and its active flag - group flags are refreshed separately
Func SetLootDecision($path, $decision)
	$loot_decisions[$path] = $decision
	$inventory_management_cache[$path] = IsLootDecisionActive($path, $decision)
EndFunc


;~ Replace every decision by those of the given map and rebuild the cache - used by the GUI when changes are applied
Func ApplyLootDecisions($decisions)
	Local $emptyDecisions[]
	Local $emptyCache[]
	$loot_decisions = $emptyDecisions
	$inventory_management_cache = $emptyCache
	For $path In MapKeys($decisions)
		SetLootDecision($path, $decisions[$path])
	Next
	RefreshLootGroupFlags()
	BuildInventoryDerivedFlags()
EndFunc


;~ Recompute the active flag of every group: a group is active when all leaves below it are active
Func RefreshLootGroupFlags()
	Local $groups[]
	For $path In MapKeys($loot_decisions)
		Local $active = $inventory_management_cache[$path]
		Local $parts = StringSplit($path, '.')
		Local $current = ''
		For $i = 1 To $parts[0] - 1
			$current &= ($i == 1 ? '' : '.') & $parts[$i]
			If Not MapExists($groups, $current) Then $groups[$current] = True
			If Not $active Then $groups[$current] = False
		Next
	Next
	For $group In MapKeys($groups)
		$inventory_management_cache[$group] = $groups[$group]
	Next
EndFunc
#EndRegion Decisions


#Region Loading and saving
;~ Load a parsed loot configuration into $loot_decisions and $inventory_management_cache
;~ Configurations in the previous format (one tree per action) are migrated first
;~ Returns True when a configuration was loaded
Func LoadLootDecisionsFromJson($json)
	If Not IsMap($json) Then Return False
	If Not MapExists($json, $LOOT_ROOT_ITEMS) And MapExists($json, 'Pick up items') Then
		Info('Loot configuration uses the previous format (one tree per action) - migrating it to one decision per item')
		$json = MigrateLootConfigurationV1($json)
	EndIf
	Local $emptyDecisions[]
	Local $emptyCache[]
	$loot_decisions = $emptyDecisions
	$inventory_management_cache = $emptyCache
	For $root In $LOOT_ROOTS
		If MapExists($json, $root) Then LoadLootDecisionsNode($json[$root], $root)
	Next
	BuildInventoryDerivedFlags()
	Return True
EndFunc


;~ Recursive part of the loading - returns True when every leaf below the node is active
Func LoadLootDecisionsNode($node, $path)
	If IsMap($node) Then
		Local $allActive = True
		For $key In MapKeys($node)
			If Not LoadLootDecisionsNode($node[$key], $path & '.' & $key) Then $allActive = False
		Next
		$inventory_management_cache[$path] = $allActive
		Return $allActive
	EndIf
	Local $decision = NormalizeLootDecision($path, $node)
	$loot_decisions[$path] = $decision
	Local $active = IsLootDecisionActive($path, $decision)
	$inventory_management_cache[$path] = $active
	Return $active
EndFunc


;~ Build the JSON object of a loot configuration from decisions, in their display order
Func BuildLootJson($decisions = Null)
	If $decisions == Null Then $decisions = $loot_decisions
	Local $json[]
	For $path In MapKeys($decisions)
		_JSON_addChangeDelete($json, $path, $decisions[$path])
	Next
	Return $json
EndFunc
#EndRegion Loading and saving


#Region Derived flags
;~ Flags summarising the configuration, used by the bot to skip useless trips to town
;~ '@<action>.something' and '@<action>.nothing' overall, plus per family for weapons, armor salvageables, trophies and materials
Func BuildInventoryDerivedFlags()
	Local $flags[]
	For $path In MapKeys($loot_decisions)
		Local $decision = $loot_decisions[$path]
		Switch GetLootNodeKind($path)
			Case $LOOT_KIND_ITEM
				Local $parsed = ParseItemDecision($decision)
				If $parsed['ignore'] Then ContinueLoop
				Local $family = GetLootFamilyKey($path)
				$flags['pickup'] = True
				If $family <> '' Then $flags['pickup.' & $family] = True
				If $parsed['identify'] Then $flags['identify'] = True
				If $parsed['action'] == $LOOT_ACTION_KEEP Then ContinueLoop
				$flags[$parsed['action']] = True
				If $family <> '' Then $flags[$parsed['action'] & '.' & $family] = True
				If $family == 'materials.basic' Or $family == 'materials.rare' Then $flags[$parsed['action'] & '.materials'] = True
			Case $LOOT_KIND_MOD
				; Salvaged mods are then stored or sold like any other item
				Local $mod = ParseModDecision($decision)
				If Not $mod['salvage'] Then ContinueLoop
				$flags['components'] = True
				Local $modAction = $mod['store'] ? $LOOT_ACTION_STORE : $LOOT_ACTION_SELL
				$flags[$modAction] = True
			Case $LOOT_KIND_BUY
				If Not IsLootDecisionActive($path, $decision) Then ContinueLoop
				$flags['buy'] = True
				Local $family = GetLootFamilyKey($path)
				If $family <> '' Then $flags['buy.' & $family] = True
				If $family == 'materials.basic' Or $family == 'materials.rare' Then $flags['buy.materials'] = True
		EndSwitch
	Next

	Local $names = ['pickup', 'pickup.weapons', 'identify', 'components', 'buy', 'buy.materials', 'buy.materials.basic', 'buy.materials.rare']
	For $name In $names
		SetInventoryDerivedFlag($name, MapExists($flags, $name))
	Next
	Local $families = ['weapons', 'salvageables', 'trophies', 'materials', 'materials.basic', 'materials.rare']
	For $action In $LOOT_ACTIONS
		If $action == $LOOT_ACTION_KEEP Then ContinueLoop
		SetInventoryDerivedFlag($action, MapExists($flags, $action))
		For $family In $families
			SetInventoryDerivedFlag($action & '.' & $family, MapExists($flags, $action & '.' & $family))
		Next
	Next
EndFunc


;~ Write the '@name.something' and '@name.nothing' pair
Func SetInventoryDerivedFlag($name, $value)
	$inventory_management_cache['@' & $name & '.something'] = $value
	$inventory_management_cache['@' & $name & '.nothing'] = Not $value
EndFunc


;~ Short family key of a leaf path for the derived flags, empty for families without flags
Func GetLootFamilyKey($path)
	Local $parts = StringSplit($path, '.')
	If $parts[0] < 2 Then Return ''
	Switch $parts[2]
		Case $LOOT_WEAPONS_FAMILY
			Return 'weapons'
		Case $LOOT_ARMOR_FAMILY
			Return 'salvageables'
		Case $LOOT_TROPHIES_FAMILY
			Return 'trophies'
		Case $LOOT_BASIC_MATERIALS_FAMILY
			Return 'materials.basic'
		Case $LOOT_RARE_MATERIALS_FAMILY
			Return 'materials.rare'
	EndSwitch
	Return ''
EndFunc
#EndRegion Derived flags


#Region Migration from the previous format
;~ Convert a configuration with one tree per action (Pick up items, Identify items, Salvage items, Sell items, Store items,
;~ Keep components, Buy items) into the decisions per item format. Returns the new JSON object.
;~ Picked up = not ignored. When several actions were ticked, salvage wins over sell, which wins over store.
;~ Identification follows the rarity of weapons and armor salvageables, other items are not identifiable.
Func MigrateLootConfigurationV1($old)
	Local $flat[]
	FlattenLootJsonV1($old, '', $flat)
	Local $new[]
	Local $items = $LOOT_ROOT_ITEMS & '.'

	; ---------------------------------------- Money ----------------------------------------
	AddMigratedItem($new, $items & $LOOT_MONEY, OldLootFlag($flat, 'Pick up items.Gold'), False, False, False, OldLootFlag($flat, 'Store items.Gold'))

	; --------------------------------------- Weapons ---------------------------------------
	Local $weapons = $items & $LOOT_WEAPONS_FAMILY & '.'
	; The low requirement rule picked such weapons up whatever their leaf said, and the keep rules stored them
	AddMigratedItem($new, $weapons & $LOOT_LOW_REQ_RULE, OldLootFlag($flat, 'Pick up items.Weapons and offhands.Low Req Max Stats'), True, False, False, True)
	For $type In $LOOT_WEAPON_TYPE_NAMES
		For $rarity In $LOOT_WEAPON_RARITY_NAMES
			Local $identify = OldLootFlag($flat, 'Identify items.' & $rarity)
			For $req = 0 To $LOOT_WEAPON_MAX_REQ
				Local $oldSuffix = '.Weapons and offhands.' & $rarity & '.' & $type & '.Req ' & $req
				Local $pickup	= OldLootFlag($flat, 'Pick up items' & $oldSuffix)
				Local $salvage	= OldLootFlag($flat, 'Salvage items' & $oldSuffix)
				Local $sell		= OldLootFlag($flat, 'Sell items' & $oldSuffix)
				Local $store	= OldLootFlag($flat, 'Store items' & $oldSuffix)
				Local $newPrefix = $weapons & $type & '.' & $rarity & '.Req ' & $req & '.'
				AddMigratedItem($new, $newPrefix & $LOOT_RARE_SKINS, $pickup, $identify, $salvage, $sell, $store)
				AddMigratedItem($new, $newPrefix & $LOOT_OTHER_SKINS, $pickup, $identify, $salvage, $sell, $store)
			Next
		Next
		; Green weapons have no requirement choice: one leaf per type, active when any requirement was
		Local $greenPickup = False, $greenSalvage = False, $greenSell = False, $greenStore = False
		For $req = 0 To $LOOT_WEAPON_MAX_REQ
			Local $oldSuffix = '.Weapons and offhands.' & $LOOT_GREEN_RARITY & '.' & $type & '.Req ' & $req
			If OldLootFlag($flat, 'Pick up items' & $oldSuffix) Then $greenPickup = True
			If OldLootFlag($flat, 'Salvage items' & $oldSuffix) Then $greenSalvage = True
			If OldLootFlag($flat, 'Sell items' & $oldSuffix) Then $greenSell = True
			If OldLootFlag($flat, 'Store items' & $oldSuffix) Then $greenStore = True
		Next
		AddMigratedItem($new, $weapons & $type & '.' & $LOOT_GREEN_RARITY, $greenPickup, OldLootFlag($flat, 'Identify items.' & $LOOT_GREEN_RARITY), $greenSalvage, $greenSell, $greenStore)
	Next

	; --------------------------------- Armor salvageables ---------------------------------
	For $rarity In $LOOT_WEAPON_RARITY_NAMES
		Local $oldSuffix = '.Armor salvageables.' & $rarity
		AddMigratedItem($new, $items & $LOOT_ARMOR_FAMILY & '.' & $rarity, OldLootFlag($flat, 'Pick up items' & $oldSuffix), OldLootFlag($flat, 'Identify items.' & $rarity), _
			OldLootFlag($flat, 'Salvage items' & $oldSuffix), OldLootFlag($flat, 'Sell items' & $oldSuffix), OldLootFlag($flat, 'Store items' & $oldSuffix))
	Next

	; --------------------------------------- Trophies ---------------------------------------
	Local $trophies = $items & $LOOT_TROPHIES_FAMILY & '.'
	For $name In OldLootGroupKeys($old, 'Pick up items.Trophies')
		If $name == $LOOT_TROPHIES_OTHER Then ContinueLoop
		Local $oldSuffix = '.Trophies.' & $name
		AddMigratedItem($new, $trophies & $name, OldLootFlag($flat, 'Pick up items' & $oldSuffix), False, _
			OldLootFlag($flat, 'Salvage items' & $oldSuffix), OldLootFlag($flat, 'Sell items' & $oldSuffix), OldLootFlag($flat, 'Store items' & $oldSuffix))
	Next
	; Trophies without their own entry: the previous rules salvaged the ones giving common materials when any trophy salvage was ticked,
	; never touched Nicholas and rare material trophies, and sold the rest when anything at all was sold
	Local $otherTrophiesPickup = OldLootFlag($flat, 'Pick up items.Trophies.Other trophies')
	AddMigratedItem($new, $trophies & $LOOT_TROPHIES_COMMON_MATERIALS, $otherTrophiesPickup, False, OldLootAnyFlag($flat, 'Salvage items.Trophies'), False, False)
	AddMigratedItem($new, $trophies & $LOOT_TROPHIES_NICHOLAS, $otherTrophiesPickup, False, False, False, False)
	AddMigratedItem($new, $trophies & $LOOT_TROPHIES_RARE_MATERIALS, $otherTrophiesPickup, False, False, False, False)
	AddMigratedItem($new, $trophies & $LOOT_TROPHIES_OTHER, $otherTrophiesPickup, False, False, OldLootAnyFlag($flat, 'Sell items'), False)

	; -------------------------------------- Materials --------------------------------------
	For $name In OldLootGroupKeys($old, 'Pick up items.Basic Materials')
		Local $oldSuffix = '.Basic Materials.' & $name
		AddMigratedItem($new, $items & $LOOT_BASIC_MATERIALS_FAMILY & '.' & $name, OldLootFlag($flat, 'Pick up items' & $oldSuffix), False, _
			False, OldLootFlag($flat, 'Sell items' & $oldSuffix), OldLootFlag($flat, 'Store items' & $oldSuffix))
	Next
	For $name In OldLootGroupKeys($old, 'Pick up items.Rare Materials')
		Local $oldSuffix = '.Rare Materials.' & $name
		AddMigratedItem($new, $items & $LOOT_RARE_MATERIALS_FAMILY & '.' & $name, OldLootFlag($flat, 'Pick up items' & $oldSuffix), False, _
			OldLootFlag($flat, 'Salvage items' & $oldSuffix), OldLootFlag($flat, 'Sell items' & $oldSuffix), OldLootFlag($flat, 'Store items' & $oldSuffix))
	Next

	; ------------------------------------- Consumables -------------------------------------
	Local $pickupConsumables = OldLootFlag($flat, 'Pick up items.Consumables')
	AddMigratedItem($new, $items & $LOOT_CONSUMABLES, $pickupConsumables, False, False, False, OldLootFlag($flat, 'Store items.Consumables'))
	Local $consumableFamilies = ['Alcohols', 'Party', 'Sweets', 'PCons', 'Morale', 'Special drops']
	For $family In $consumableFamilies
		For $name In OldLootGroupKeys($old, 'Pick up items.' & $family)
			Local $oldSuffix = '.' & $family & '.' & $name
			AddMigratedItem($new, $items & $family & '.' & $name, OldLootFlag($flat, 'Pick up items' & $oldSuffix), False, False, False, OldLootFlag($flat, 'Store items' & $oldSuffix))
		Next
	Next
	; Consets and summoning stones were only listed for storage and picked up as consumables
	Local $storedFamilies = ['Consets', 'Summoning stones']
	For $family In $storedFamilies
		For $name In OldLootGroupKeys($old, 'Store items.' & $family)
			AddMigratedItem($new, $items & $family & '.' & $name, $pickupConsumables, False, False, False, OldLootFlag($flat, 'Store items.' & $family & '.' & $name))
		Next
	Next

	; ----------------------------------------- Tomes -----------------------------------------
	Local $tomeKinds = ['Normal', 'Elite']
	For $kind In $tomeKinds
		For $name In OldLootGroupKeys($old, 'Pick up items.Tomes.' & $kind)
			Local $oldSuffix = '.Tomes.' & $kind & '.' & $name
			AddMigratedItem($new, $items & 'Tomes.' & $kind & '.' & $name, OldLootFlag($flat, 'Pick up items' & $oldSuffix), False, False, False, OldLootFlag($flat, 'Store items' & $oldSuffix))
		Next
	Next

	; ---------------------------------------- Scrolls ----------------------------------------
	AddMigratedItem($new, $items & $LOOT_SCROLLS_FAMILY & '.Blue', OldLootFlag($flat, 'Pick up items.Scrolls.Blue'), False, False, OldLootFlag($flat, 'Sell items.Scrolls.Blue'), OldLootFlag($flat, 'Store items.Scrolls.Blue'))
	For $name In OldLootGroupKeys($old, 'Pick up items.Scrolls.Gold')
		Local $oldSuffix = '.Scrolls.Gold.' & $name
		AddMigratedItem($new, $items & $LOOT_SCROLLS_FAMILY & '.Gold.' & $name, OldLootFlag($flat, 'Pick up items' & $oldSuffix), False, False, OldLootFlag($flat, 'Sell items' & $oldSuffix), OldLootFlag($flat, 'Store items' & $oldSuffix))
	Next

	; ----------------------------------------- Dyes ------------------------------------------
	For $name In OldLootGroupKeys($old, 'Pick up items.Dyes')
		AddMigratedItem($new, $items & 'Dyes.' & $name, OldLootFlag($flat, 'Pick up items.Dyes.' & $name), False, False, False, OldLootFlag($flat, 'Store items.Dyes.' & $name))
	Next

	; ------------------------------------ Keys and others ------------------------------------
	AddMigratedItem($new, $items & 'Keys', OldLootFlag($flat, 'Pick up items.Keys'), False, False, OldLootFlag($flat, 'Sell items.Keys'), OldLootFlag($flat, 'Store items.Keys'))
	AddMigratedItem($new, $items & 'Lockpicks', OldLootFlag($flat, 'Pick up items.Lockpicks'), False, False, False, OldLootFlag($flat, 'Store items.Lockpicks'))
	AddMigratedItem($new, $items & 'Miniatures', OldLootFlag($flat, 'Pick up items.Miniatures'), False, False, False, False)
	AddMigratedItem($new, $items & 'Quest items.Map pieces', OldLootFlag($flat, 'Pick up items.Quest items.Map pieces'), False, False, False, False)
	; Stackables without their own entry were picked up, anything else was left on the ground
	AddMigratedItem($new, $items & $LOOT_OTHER_FAMILY & '.' & $LOOT_OTHER_STACKABLES, True, False, False, False, False)
	AddMigratedItem($new, $items & $LOOT_OTHER_FAMILY & '.' & $LOOT_OTHER_UNKNOWN, False, False, False, False, False)

	; ----------------------------------------- Mods ------------------------------------------
	; Kept components become salvaged components, stored unless upgrade components were not stored
	Local $storeComponents = Not MapExists($flat, 'Store items.Upgrade components') Or OldLootFlag($flat, 'Store items.Upgrade components')
	Local $oldComponentsPrefix = 'Keep components.'
	For $path In MapKeys($flat)
		If StringLeft($path, StringLen($oldComponentsPrefix)) <> $oldComponentsPrefix Then ContinueLoop
		If Not IsLootLeafPathV1($flat, $path) Then ContinueLoop
		Local $newPath = StringTrimLeft($path, StringLen($oldComponentsPrefix))
		; 'Keep components.Mods' held the weapon mods, next to inscriptions and armor upgrades
		If StringLeft($newPath, 5) == 'Mods.' Then $newPath = $LOOT_WEAPON_MODS_GROUP & StringTrimLeft($newPath, 4)
		_JSON_addChangeDelete($new, $LOOT_ROOT_MODS & '.' & $newPath, FormatModDecision($flat[$path], $storeComponents))
	Next

	; --------------------------------------- Buy items ---------------------------------------
	Local $oldBuyPrefix = $LOOT_ROOT_BUY & '.'
	For $path In MapKeys($flat)
		If StringLeft($path, StringLen($oldBuyPrefix)) <> $oldBuyPrefix Then ContinueLoop
		If Not IsLootLeafPathV1($flat, $path) Then ContinueLoop
		_JSON_addChangeDelete($new, $path, $flat[$path] == True)
	Next
	Return $new
EndFunc


;~ Add one migrated item leaf - salvage wins over sell, which wins over store, identification needs the item to be picked up
Func AddMigratedItem(ByRef $json, $path, $pickup, $identify, $salvage, $sell, $store)
	Local $action = $LOOT_ACTION_KEEP
	If $salvage Then
		$action = $LOOT_ACTION_SALVAGE
	ElseIf $sell Then
		$action = $LOOT_ACTION_SELL
	ElseIf $store Then
		$action = $LOOT_ACTION_STORE
	EndIf
	_JSON_addChangeDelete($json, $path, FormatItemDecision(Not $pickup, $identify And $pickup, $action))
EndFunc


;~ Flatten a previous format configuration into path -> boolean, groups being True when all their leaves are
Func FlattenLootJsonV1($node, $path, ByRef $flat)
	If IsMap($node) Then
		Local $all = True
		For $key In MapKeys($node)
			If Not FlattenLootJsonV1($node[$key], ($path == '' ? $key : $path & '.' & $key), $flat) Then $all = False
		Next
		If $path <> '' Then $flat[$path] = $all
		Return $all
	EndIf
	$flat[$path] = ($node == True)
	Return $node == True
EndFunc


;~ Value of a previous format flag, False when it did not exist
Func OldLootFlag(ByRef $flat, $path)
	If Not MapExists($flat, $path) Then Return False
	Return $flat[$path] == True
EndFunc


;~ True when any leaf below the path was ticked in a previous format configuration
Func OldLootAnyFlag(ByRef $flat, $path)
	Local $prefix = $path & '.'
	For $key In MapKeys($flat)
		If StringLeft($key, StringLen($prefix)) == $prefix And $flat[$key] == True Then Return True
	Next
	Return False
EndFunc


;~ True when the path is a leaf of the flattened previous format configuration
Func IsLootLeafPathV1(ByRef $flat, $path)
	Local $prefix = $path & '.'
	For $key In MapKeys($flat)
		If StringLeft($key, StringLen($prefix)) == $prefix Then Return False
	Next
	Return True
EndFunc


;~ Keys of a group of a previous format configuration, in file order - empty when the group does not exist
Func OldLootGroupKeys($old, $path)
	Local $none[0]
	Local $node = _JSON_Get($old, $path)
	If @error Or Not IsMap($node) Then Return $none
	Return MapKeys($node)
EndFunc
#EndRegion Migration from the previous format
