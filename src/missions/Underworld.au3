#CS ===========================================================================
=====================================================
|	Underworld clearing farm bot					|
|	Authors: Akiro/The Great Gree					|
| Rewrite Authors for BotsHub: Gahais, BuddyLeeX	|
=====================================================
; Copyright 2025 caustic-kronos
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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $UNDERWORLD_FARM_INFORMATIONS = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'Due to Hero Flag mechanics place healers in slots 6-8' & @CRLF _
	& 'In NM with quests disabled bot takes about 1 hour 30 minutes to clear/farm on average.' & @CRLF _
	& 'In NM with quests enabled bot takes about 2 hours 15 minutes to clear on average.' & @CRLF _
	& 'Bot not tested in HM' & @CRLF _
	& 'Make sure to set loot filters to purple swords in case crystalline sword drops from quest chests.' & @CRLF _
	& 'Manually set $ATTEMPT_REAPER_QUESTS to False if you want to farm ecto only.' & @CRLF _
	& 'Or disable specific Reaper quests that take too long.' & @CRLF _
	& 'Must be Rt/A or A/Rt in order to do Four Horsemen quest.' & @CRLF

Global Const $UW_FARM_DURATION = 90 * 60 * 1000 ; Runs take about 90 minutes if quests set to False
Global Const $MAX_UW_FARM_DURATION = 135 * 60 * 1000 ; Runs take about 135 minutes if all quests set to True

Global Const $RTA_UNDERWORLD_FARMER_SKILLBAR = 'OAejAqiMpR0gdOXT+glTfTRbQTA'
Global Const $ART_UNDERWORLD_FARMER_SKILLBAR = 'OwhjAyi84QXT+glTVTQT0gAAAAA'

Global Const $UNDERWORLD_SUMMON_SPIRITS			= 1
Global Const $UNDERWORLD_RECALL					= 2
Global Const $UNDERWORLD_SIGNET_OF_SPIRITS		= 3
Global Const $UNDERWORLD_VAMPIRISM				= 4
Global Const $UNDERWORLD_BLOODSONG				= 5
Global Const $UNDERWORLD_PAIN					= 6
Global Const $UNDERWORLD_ANGUISH				= 7
Global Const $UNDERWORLD_ARMOR_OF_UNFEELING		= 8

Global Const $ATTEMPT_REAPER_QUESTS = False ; Set this to True in order for bot to do Reaper quests

; Specific Quest Knobs
Global Const $ENABLE_WRATHFUL_SPIRITS = True ; Quest takes too long and mobs do not drop loot.
Global Const $ENABLE_SERVANTS_OF_GRENTH = True
Global Const $ENABLE_TERRORWEB_QUEEN = True
Global Const $ENABLE_IMPRISONED_SPIRITS = True ; Hero Healer AI lets spirits die often
Global Const $ENABLE_DEMON_ASSASSIN = True ; Behemoths do not drop ectos. Skips Mountain area too.
Global Const $ENABLE_ESCORT_OF_SOULS = True
Global Const $ENABLE_UNWANTED_GUESTS = True
Global Const $ENABLE_THE_FOUR_HORSEMEN = True ; Rt/A or A/Rt only at the moment
Global Const $ENABLE_THE_NIGHTMAN_COMETH = True ; TODO

Global $underworld_fight_options = CloneDictMap($default_move_aggro_kill_options)
Global $underworld_player_profession = $ID_RITUALIST
Global $uw_farm_setup = False


;~ Main loop function
Func UnderworldFarm()
	If Not $uw_farm_setup Then SetupUnderworldFarm()
	Local $result = EnterUnderworld()
	If $result <> $SUCCESS Then Return $result
	$result = UnderworldFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared Underworld')
	If $result == $FAIL Then Info('Could not clear Underworld')
	TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name)
	Return $result
EndFunc


Func SetupUnderworldFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name)
	SetupPlayerUnderworldFarm()
	SwitchToHardModeIfEnabled()
	$uw_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerUnderworldFarm()
	Info('Setting up player build skill bar')
	If $ATTEMPT_REAPER_QUESTS And ($ENABLE_THE_FOUR_HORSEMEN Or $ENABLE_THE_NIGHTMAN_COMETH) Then
		Switch DllStructGetData(GetMyAgent(), 'Primary')
			Case $ID_ASSASSIN
				$underworld_player_profession = $ID_ASSASSIN
				LoadSkillTemplate($ART_UNDERWORLD_FARMER_SKILLBAR)
			Case $ID_RITUALIST
				$underworld_player_profession = $ID_RITUALIST
				LoadSkillTemplate($RTA_UNDERWORLD_FARMER_SKILLBAR)
			Case Else
				If $ATTEMPT_REAPER_QUESTS Then
					Warn('Bot will skip Four Horsement quest and Nightman Cometh unless A/Rt or Rt/A profession combos.')
			EndIf
		EndSwitch
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func UnderworldFarmLoop()
	Info('Starting Farm')
	UseUWConsetsAndConsumables()
	If ClearTheChamberUnderworld() == $FAIL Then Return $FAIL

	; Accept reward & take quest Restoring Grenth's Monuments
	Local $reaper_Labyrinth = GetNearestNPCToCoords(-5694, 12772)
	TakeQuestReward($reaper_Labyrinth, $ID_QUEST_CLEAR_THE_CHAMBER, 0x806507)
	TakeQuest($reaper_Labyrinth, $ID_QUEST_RESTORING_GRENTH_S_MONUMENTS, 0x806D01, 0x806D03)
	Info('Taking Restoring Grenths Monuments Quest')

	UseUWConsetsAndConsumables()
	If ClearTheForgottenVale() == $FAIL Then Return $FAIL
	Local $reaper_ForgottenVale = GetNearestNPCToCoords(-13211, 5322)
	If WrathfulSpirits() == $FAIL Then Return $FAIL

	UseUWConsetsAndConsumables()
	If ClearTheFrozenWastes() == $FAIL Then Return $FAIL
	If ServantsOfGrenth() == $FAIL Then Return $FAIL

	UseUWConsetsAndConsumables()
	If ClearTheChaosPlanes() == $FAIL Then Return $FAIL
	If TheFourHorsemen($reaper_Labyrinth) == $FAIL Then Return $FAIL

	UseUWConsetsAndConsumables()
	If ClearSpawningPools($reaper_Labyrinth) == $FAIL Then Return $FAIL
	If TerrorwebQueen() == $FAIL Then Return $FAIL

	UseUWConsetsAndConsumables()
	If ClearBonePits($reaper_Labyrinth) == $FAIL Then Return $FAIL
	If ImprisonedSpirits() == $FAIL Then Return $FAIL

	If ClearTwinSerpentMountains() == $FAIL Then Return $FAIL
	If DemonAssassin() == $FAIL Then Return $FAIL

	If IsQuestReward($ID_QUEST_RESTORING_GRENTH_S_MONUMENTS) Then 
		Info('Accepting quest reward for Restoring Grenths Monuments quest')
		TakeQuestReward($reaper_Labyrinth, $ID_QUEST_RESTORING_GRENTH_S_MONUMENTS, 0x806D07)

		If EscortOfSouls($reaper_Labyrinth, $reaper_ForgottenVale) == $FAIL Then Return $FAIL
		If UnwantedGuests($reaper_Labyrinth) == $FAIL Then Return $FAIL
		; TODO: The Nightman Cometh
	Else
		Info('Skipping remaining quests per settings.')
	EndIf

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Small wrapper to use both conset and legionnaire summoning crystal
Func UseUWConsetsAndConsumables()
	UseConsumable($ID_LEGIONNAIRE_SUMMONING_CRYSTAL)
	UseConset()
EndFunc


;~ Have a Reaper send user back to an area
Func TeleportBackToArea($reaper, $secondDialog, $thirdDialog, $area, $initialDialog = '0x7F')
	Info('Teleporting back to ' & $area)
	Sleep(1000)
	GoToNPC($reaper)
	Sleep(1000)
	If $initialDialog <> Null Then Dialog($initialDialog)
	Sleep(1000)
	Dialog($secondDialog)
	Sleep(1000)
	Dialog($thirdDialog)
	Sleep(1000)
EndFunc


Func ClearTheChamberUnderworld()
	Info('Moving to left of the stairs')
	MoveAggroAndKill(-495, 6509)
	MoveAggroAndKill(-2191, 5688)
	Info('Moving to the middle of the chamber')
	MoveAggroAndKill(-1371, 7179)
	MoveAggroAndKill(-1244, 7835)
	Info('Killing Pop-Up')
	MoveAggroAndKill(-862, 8923)
	Info('Going up Middle of chamber stairs')
	MoveAggroAndKill(-1669, 10631)

	Info('Going for skeletons')
	MoveAggroAndKill(-2706, 10149)
	Info('Killing skeletons')
	MoveAggroAndKill(-1767, 10583)
	MoveAggroAndKill(-694, 8957)

	Info('Moving to Aatxes at top right of stairs')
	MoveAggroAndKill(-106, 9116)
	MoveAggroAndKill(848, 9720)
	Info('Killing pop-up')
	MoveAggroAndKill(1204, 10380)

	Info('Bottom Stairs right side chamber')
	MoveAggroAndKill(1119, 12220)
	MoveAggroAndKill(1659, 12775)
	MoveAggroAndKill(2503, 13092)
	MoveAggroAndKill(3242, 12862)
	MoveAggroAndKill(2252, 13197)
	MoveAggroAndKill(1146, 12451)

	Info('Going back for quest')
	MoveAggroAndKill(1196, 10567)
	MoveAggroAndKill(461, 9219)
	MoveAggroAndKill(879, 7759)
	MoveAggroAndKill(910, 7115)
	MoveTo(378, 7209)

	Info('Taking Clear the Chamber Quest')
	Local $lostSoul = GetNearestNPCToCoords(246, 7177)
	TakeQuest($lostSoul, $ID_QUEST_CLEAR_THE_CHAMBER, 0x0806501)
	; bottem left stairs
	MoveAggroAndKill(187, 6606)
	; check top left side
	MoveAggroAndKill(-1977, 5802)
	; going to right side
	MoveAggroAndKill(-1207, 6524)
	MoveAggroAndKill(-1361, 7832)
	MoveAggroAndKill(-805, 8886)
	MoveAggroAndKill(553, 9338)
	; wait at top right stairs for grasping darkness
	Sleep(30000)
	; top middle chamber stairs
	MoveAggroAndKill(-1495, 10562)
	MoveAggroAndKill(-2824, 10222)
	; doing 'Clear the Chamber' quest
	MoveAggroAndKill(-4210, 11372)
	MoveAggroAndKill(-4675, 11733)
	; doing left side
	MoveAggroAndKill(-4186, 12722)
	MoveAggroAndKill(-4050, 13182)
	MoveAggroAndKill(-5572, 13250)
	Info('Killing Terrorweb Dryders')
	MoveAggroAndKill(-5694, 12772)
	MoveAggroAndKill(-5922, 11468)
	MoveAggroAndKill(-5897, 12496)
	MoveAggroAndKill(-5694, 12772)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearTheForgottenVale()
	Local $optionsForgottenVale = CloneDictMap($underworld_fight_options)
	$optionsForgottenVale.Item('fightRange') = $RANGE_EARSHOT
	$optionsForgottenVale.Item('flagHeroesOnFight') = False
	$optionsForgottenVale.Item('ignoreDroppedLoot') = False
	Info('Moving to Forgotten Vale')
	MoveAggroAndKill(-5973, 12410)
	MoveAggroAndKill(-6330, 10177)
	MoveAggroAndKill(-5241, 8923)
	MoveAggroAndKill(-8641, 5709)
	Info('Kill Popups')
	MoveAggroAndKill(-8009, 6331)
	RandomSleep(3000)
	MoveAggroAndKill(-8641, 5709)
	MoveAggroAndKill(-7264, 3390, '', $optionsForgottenVale)
	MoveAggroAndKill(-7714, 2222, '', $optionsForgottenVale)
	MoveAggroAndKill(-8694, 2213, '', $optionsForgottenVale)
	Info('Kill Popups')
	MoveAggroAndKill(-7714, 2222, '', $optionsForgottenVale)
	RandomSleep(3000)
	Info('Kill Grasping Darkness')
	MoveAggroAndKill(-9849, 1994, '', $optionsForgottenVale)
	MoveAggroAndKill(-9025, 114)
	MoveAggroAndKill(-10838, -234)
	MoveAggroAndKill(-11684, 1200)
	MoveAggroAndKill(-15299, 566)
	MoveAggroAndKill(-14724, 2102)
	MoveAggroAndKill(-13845, 2391)
	MoveAggroAndKill(-13710, 3854)
	Info('Kill Terrorweb Dryders')
	MoveAggroAndKill(-13491, 4605)
	Info('Kill Some Coldfire Patrols')
	$optionsForgottenVale.Item('flagHeroesOnFight') = True
	$optionsForgottenVale.Item('fightRange') = $RANGE_EARSHOT * 1.25
	MoveAggroAndKill(-13505, 6040, '', $optionsForgottenVale)
	Info('Waiting for Coldfire Patrols 1')
	RandomSleep(5000)
	MoveAggroAndKill(-12745, 5980, '', $optionsForgottenVale)
	Info('Waiting for Coldfire Patrols 2')
	RandomSleep(5000)
	MoveAggroAndKill(-12533, 6296, '', $optionsForgottenVale)
	MoveAggroAndKill(-13751, 7192, '', $optionsForgottenVale)
	MoveAggroAndKill(-15065, 7074, '', $optionsForgottenVale)
	Info('Waiting for Coldfire Patrols 3')
	RandomSleep(5000)
	Info('Cleanup any Coldfires missed')
	MoveAggroAndKill(-15975, 8443, '', $optionsForgottenVale)
	MoveAggroAndKill(-12464, 7236, '', $optionsForgottenVale)
	MoveAggroAndKill(-12521, 9882, '', $optionsForgottenVale)
	MoveAggroAndKill(-11313, 9186, '', $optionsForgottenVale)
	MoveAggroAndKill(-10901, 11553, '', $optionsForgottenVale)
	MoveAggroAndKill(-10825, 10397, '', $optionsForgottenVale)
	MoveAggroAndKill(-9478, 9096, '', $optionsForgottenVale)
	MoveAggroAndKill(-10799, 7361, '', $optionsForgottenVale)
	Info('Go back to Reaper')
	MoveAggroAndKill(-12533, 6296)
	MoveAggroAndKill(-13230, 5246)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc

Func WrathfulSpirits()
	; Take Quest Wrathful spirits from the Reaper and complete
	Local $reaper = GetNearestNPCToCoords(-13211, 5322)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_WRATHFUL_SPIRITS Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_WRATHFUL_SPIRITS] &' quest per settings.')
		TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsForgottenVale = CloneDictMap($underworld_fight_options)
	$optionsForgottenVale.Item('fightRange') = $RANGE_EARSHOT
	$optionsForgottenVale.Item('flagHeroesOnFight') = False
	$optionsForgottenVale.Item('ignoreDroppedLoot') = False
	TakeQuest($reaper, $ID_QUEST_WRATHFUL_SPIRITS, 0x806E01, 0x806E03)
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_WRATHFUL_SPIRITS) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_WRATHFUL_SPIRITS])
			ExitLoop
		EndIf
		Info('1st Group')
		MoveTo(-13290, 3629)
		MoveTo(-13200, 2657)
		MoveAggroAndKill(-13881, 1866)
		Info('Protect Mayor Alegheri')
		MoveTo(-13409, 1059)
		MoveAggroAndKill(-12908, 822)
		MoveAggroAndKill(-13194, 75)
		MoveAggroAndKill(-12908, 822)
		MoveAggroAndKill(-12250, 944)
		Info('2nd Group')
		MoveAggroAndKill(-11631, 839)
		MoveAggroAndKill(-10395, 286)
		Info('3rd Group')
		MoveAggroAndKill(-11631, 839)
		MoveAggroAndKill(-10972, 1709)
		MoveAggroAndKill(-10215, 1825)
		Info('4th Group')
		MoveAggroAndKill(-11631, 839)
		MoveAggroAndKill(-12250, 944)
		MoveAggroAndKill(-13296, 278)
		Info('Moving to Final Group')
		MoveAggroAndKill(-13229, 720)
		MoveAggroAndKill(-13849, 1291)
		MoveAggroAndKill(-13200, 2657, '', $optionsForgottenVale)
		MoveAggroAndKill(-13290, 3629, '', $optionsForgottenVale)
		MoveAggroAndKill(-12530, 6322)
		MoveAggroAndKill(-13588, 7149)
		MoveAggroAndKill(-14825, 6855)
		MoveAggroAndKill(-15210, 5363)
		Info('Final Group')
		MoveAggroAndKill(-15283, 3394)
		Info('Returning to Reaper')
		MoveAggroAndKill(-15210, 5363)
		MoveAggroAndKill(-14825, 6855)
		MoveAggroAndKill(-13588, 7149)
		MoveAggroAndKill(-12530, 6322)
		MoveAggroAndKill(-13665, 4673)
		MoveAggroAndKill(-13211, 5322)
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_WRATHFUL_SPIRITS])
		Return $FAIL
	EndIf
	TakeQuestReward($reaper, $ID_QUEST_WRATHFUL_SPIRITS, 0x806E07)
	Info('Parking Heroes out of loot range for chest.')
	CommandAll(-8233, 45)
	RandomSleep(30000)
	Info('Looting chest')
	MoveTo(-13704, 4954)
	Sleep(1000)
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	Sleep(250)
	CancelAll()
	MoveAggroAndKill(-13211, 5322)
	TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearTheFrozenWastes()
	Local $optionsFrozenWastes = CloneDictMap($underworld_fight_options)
	$optionsFrozenWastes.Item('fightRange') = $RANGE_EARSHOT
	$optionsFrozenWastes.Item('flagHeroesOnFight') = False
	$optionsFrozenWastes.Item('ignoreDroppedLoot') = False
	$optionsFrozenWastes.Item('priorityMobs') = True
	Info('Moving to Frozen Wastes')
	MoveAggroAndKill(-5129, 13248)
	MoveAggroAndKill(-4, 13337)
	MoveAggroAndKill(978, 12601)
	MoveAggroAndKill(1263, 10332)
	MoveAggroAndKill(1703, 10411)
	MoveAggroAndKill(2521, 10263)
	MoveAggroAndKill(3189, 9148)
	; killing skeletons
	MoveAggroAndKill(3255, 8279)
	Info('Killing Aatxes and Grasping Darkness')
	MoveAggroAndKill(3960, 7966)
	MoveAggroAndKill(5286, 7761)
	MoveAggroAndKill(5590, 8664)
	MoveAggroAndKill(5662, 9962)
	MoveAggroAndKill(6399, 10817)
	MoveAggroAndKill(7459, 11497)
	MoveAggroAndKill(8610, 12048)
	; killing skeletons
	MoveAggroAndKill(8966, 12885)
	MoveAggroAndKill(8893, 13807)
	MoveAggroAndKill(8480, 14491)
	MoveAggroAndKill(7321, 15188)
	Info('Killing Smite mob 1')
	MoveAggroAndKill(7413, 16318, '', $optionsFrozenWastes)
	MoveAggroAndKill(8881, 17134, '', $optionsFrozenWastes)
	MoveAggroAndKill(9142, 16760, '', $optionsFrozenWastes)
	Info('Killing Smite mob 2')
	MoveAggroAndKill(10193, 15872, '', $optionsFrozenWastes)
	MoveAggroAndKill(11159, 15195, '', $optionsFrozenWastes)
	MoveAggroAndKill(12473, 15153, '', $optionsFrozenWastes)
	Info('Killing Smite mob 3')
	$optionsFrozenWastes.Item('flagHeroesOnFight') = True
	MoveAggroAndKill(13973, 17130, '', $optionsFrozenWastes)
	MoveAggroAndKill(13920, 19641, '', $optionsFrozenWastes)
	MoveAggroAndKill(12576, 20212, '', $optionsFrozenWastes)
	MoveAggroAndKill(11881, 20024, '', $optionsFrozenWastes)
	Info('Killing Smite mob 4')
	MoveAggroAndKill(11125, 20565, '', $optionsFrozenWastes)
	MoveAggroAndKill(9660, 21593, '', $optionsFrozenWastes)
	$optionsFrozenWastes.Item('flagHeroesOnFight') = False
	MoveAggroAndKill(8277, 22011, '', $optionsFrozenWastes)
	Info('Killing Smite mob 5')
	MoveAggroAndKill(7785, 21633, '', $optionsFrozenWastes)
	MoveAggroAndKill(6229, 20807, '', $optionsFrozenWastes)
	MoveAggroAndKill(6034, 19970, '', $optionsFrozenWastes)
	MoveAggroAndKill(5635, 18749, '', $optionsFrozenWastes)
	Info('Killing Smite mob 6')
	MoveAggroAndKill(5175, 17857, '', $optionsFrozenWastes)
	MoveAggroAndKill(4217, 16400, '', $optionsFrozenWastes)
	Info('Killing Smite mob 7')
	MoveAggroAndKill(4121, 15928, '', $optionsFrozenWastes)
	MoveAggroAndKill(2643, 16990, '', $optionsFrozenWastes)
	MoveAggroAndKill(2754, 18508, '', $optionsFrozenWastes)
	MoveAggroAndKill(2827, 19050, '', $optionsFrozenWastes)
	Info('Killing Smite mob 8')
	$optionsFrozenWastes.Item('fightRange') = $RANGE_EARSHOT * 1.25
	MoveAggroAndKill(2253, 19856, '', $optionsFrozenWastes)
	MoveAggroAndKill(784, 19901, '', $optionsFrozenWastes)
	MoveAggroAndKill(-498, 18792, '', $optionsFrozenWastes)
	Info('Killing Smite mob 9')
	$optionsFrozenWastes.Item('fightRange') = $RANGE_EARSHOT
	MoveAggroAndKill(-837, 18762, '', $optionsFrozenWastes)
	MoveAggroAndKill(884, 20412, '', $optionsFrozenWastes)
	MoveAggroAndKill(418, 21487, '', $optionsFrozenWastes)
	MoveAggroAndKill(-1481, 20952, '', $optionsFrozenWastes)
	Info('Killing Smite mob 10')
	MoveAggroAndKill(-2031, 20595, '', $optionsFrozenWastes)
	MoveAggroAndKill(-2568, 18775, '', $optionsFrozenWastes)
	MoveAggroAndKill(-4033, 18700, '', $optionsFrozenWastes)
	MoveAggroAndKill(-4701, 19366, '', $optionsFrozenWastes)
	; Move to Reaper
	MoveAggroAndKill(-4033, 18700)
	MoveAggroAndKill(-2568, 18775)
	MoveAggroAndKill(-2031, 20595)
	MoveAggroAndKill(-1481, 20952)
	MoveAggroAndKill(418, 21487)
	MoveAggroAndKill(884, 20412)
	MoveAggroAndKill(12, 19396)
	Info('Killing Dryders and moving to Reaper')
	MoveAggroAndKill(-458, 18492)
	MoveAggroAndKill(526, 18407)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ServantsOfGrenth()
	; Take Quest Servants of Grenth from Reaper of the Ice Wastes
	Local $reaper = GetNearestNPCToCoords(526, 18407)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_SERVANTS_OF_GRENTH Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_SERVANTS_OF_GRENTH] &' quest per settings.')
		TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsFrozenWastes = CloneDictMap($underworld_fight_options)
	$optionsFrozenWastes.Item('fightRange') = $RANGE_EARSHOT * 1.5
	$optionsFrozenWastes.Item('flagHeroesOnFight') = False
	$optionsFrozenWastes.Item('ignoreDroppedLoot') = True
	$optionsFrozenWastes.Item('priorityMobs') = True
	Info('Setting heroes up for quest')
	CommandHero(1, 2158, 19713)
	CommandHero(2, 2482, 19482)
	CommandHero(3, 2756, 19080)
	CommandHero(4, 1854, 19723)
	CommandHero(5, 2080, 19392)
	CommandHero(6, 2303, 19144)
	CommandHero(7, 2511, 18753)
	RandomSleep(16000)
	TakeQuest($reaper, $ID_QUEST_SERVANTS_OF_GRENTH, 0x806601, 0x806603)
	RandomSleep(1000)
	MoveTo(1762, 20090)
	KillFoesInArea($optionsFrozenWastes)
	Info('Killing waves of Dryders and Skeletons')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_SERVANTS_OF_GRENTH) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_SERVANTS_OF_GRENTH])
			ExitLoop
		Else
			KillFoesInArea($optionsFrozenWastes)
			RandomSleep(250)
		EndIf
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_SERVANTS_OF_GRENTH])
		Return $FAIL
	EndIf
	MoveAggroAndKill(2514, 17133, '', $optionsFrozenWastes)
	CancelAllHeroes()
	MoveAggroAndKill(3693, 16071, '', $optionsFrozenWastes)
	MoveAggroAndKill(4718, 16549, '', $optionsFrozenWastes)
	MoveAggroAndKill(6093, 19040, '', $optionsFrozenWastes)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	Info('Parking Heroes out of loot range for chest.')
	CommandAll(7656, 18838)
	MoveTo(6093, 19040)
	MoveTo(4718, 16549)
	MoveTo(4514, 15732)
	MoveTo(3828, 15754)
	MoveTo(2514, 17133)
	MoveTo(2799, 18863)
	MoveTo(2762, 19787)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveTo(2128, 19929)
	MoveTo(800, 19825)
	MoveTo(-326, 19043)
	MoveTo(-293, 18508)
	MoveTo(322, 18408)
	MoveTo(646, 18064)
	; Loot Chest
	Sleep(1000)
	Info('Looting chest')
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	CancelAll()
	MoveTo(560, 18377)
	TakeQuestReward($reaper, $ID_QUEST_SERVANTS_OF_GRENTH, 0x806607)
	TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearTheChaosPlanes()
	Local $optionsChaosPlanes = CloneDictMap($underworld_fight_options)
	$optionsChaosPlanes.Item('fightRange') = $RANGE_EARSHOT
	$optionsChaosPlanes.Item('flagHeroesOnFight') = False
	$optionsChaosPlanes.Item('ignoreDroppedLoot') = False
	$optionsChaosPlanes.Item('priorityMobs') = True
	Info('Moving to Chaos Plains')
	MoveAggroAndKill(-4922, 13288)
	MoveAggroAndKill(-127, 13346)
	MoveAggroAndKill(1077, 12548)
	MoveAggroAndKill(1218, 10407)
	MoveAggroAndKill(2143, 10472)
	MoveAggroAndKill(3031, 10071)
	MoveAggroAndKill(3538, 7483)
	MoveAggroAndKill(4144, 5637)
	MoveAggroAndKill(3131, 5571)
	MoveAggroAndKill(2179, 4514)
	MoveAggroAndKill(1545, 4634)
	MoveAggroAndKill(217, 3801)
	Info('Killing skeletons')
	MoveAggroAndKill(123, 3678)
	Info('Killing aatxes and grasping darkness')
	MoveTo(-812, 1738)
	MoveAggroAndKill(-1168, 1754)
	MoveAggroAndKill(-2297, 1732)
	MoveAggroAndKill(-3432, 945)
	MoveAggroAndKill(-3063, 4219)
	Info('Extra mobs on the ledge above forgotten vale')
	MoveAggroAndKill(-3447, 4719, '', $optionsChaosPlanes)
	MoveAggroAndKill(-4559, 4954, '', $optionsChaosPlanes)
	MoveAggroAndKill(-5223, 4703, '', $optionsChaosPlanes)
	MoveAggroAndKill(-6031, 3642, '', $optionsChaosPlanes)
	MoveAggroAndKill(-6098, 2699, '', $optionsChaosPlanes)
	MoveAggroAndKill(-5639, 1794, '', $optionsChaosPlanes)
	MoveAggroAndKill(-6147, 745, '', $optionsChaosPlanes)
	MoveAggroAndKill(-5639, 1794, '', $optionsChaosPlanes)
	MoveAggroAndKill(-6098, 2699, '', $optionsChaosPlanes)
	MoveAggroAndKill(-6031, 3642, '', $optionsChaosPlanes)
	MoveAggroAndKill(-5223, 4703, '', $optionsChaosPlanes)
	MoveAggroAndKill(-4559, 4954, '', $optionsChaosPlanes)
	MoveAggroAndKill(-3447, 4719, '', $optionsChaosPlanes)
	MoveAggroAndKill(-3063, 4219, '', $optionsChaosPlanes)
	MoveAggroAndKill(-3432, 945, '', $optionsChaosPlanes)
	MoveAggroAndKill(-2711, -90, '', $optionsChaosPlanes)
	MoveAggroAndKill(-663, -535, '', $optionsChaosPlanes)
	Info('Moving to worms')
	MoveAggroAndKillSafeTraps(412, 1324)
	Info('Clear Traps for Heroes')
	CommandAll(412, 1324)
	MoveTo(1358, 2087)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(1835, 2562)
	;Let's Just avoid Behemoths if possible
	Info('Avoiding Worm 1')
	CommandAll(2968, 2616)
	MoveTo(2968, 2616)
	CommandAll(3030, 2259)
	MoveTo(3030, 2259)
	CommandAll(2684, 1457)
	MoveTo(2684, 1457)
	RandomSleep(5000)
	CommandAll(3820, 1178)
	MoveTo(3820, 1178)
	Info('Avoiding Worm 2')
	CommandAll(4608, 1467)
	MoveTo(4608, 1467)
	Info('Avoiding Worm 3')
	CommandAll(5453, 602)
	MoveTo(5453, 602)
	CommandAll(6290, 1341)
	MoveTo(6290, 1341)
	CancelAll()
	RandomSleep(2500)
	Info('Killing Charged Blackness')
	MoveAggroAndKillSafeTraps(6826, 1806)
	MoveAggroAndKillSafeTraps(7710, 1685)
	Info('Killing Worm 4')
	MoveAggroAndKillSafeTraps(7905, 265)
	Info('Clear Traps for Heroes')
	CommandAll(7905, 265)
	MoveTo(8021, -275)
	RandomSleep(5000)
	CancelAll()
	RandomSleep(2500)
	Info('Avoiding Worm Mob 5 & 6')
	CommandAll(8824, -1125)
	MoveTo(8824, -1125)
	CommandAll(8385, -2335)
	MoveTo(8385, -2335)
	CommandAll(8274, -4431)
	MoveTo(8274, -4431)
	CancelAll()
	Info('Kill Charged Blackness')
	MoveAggroAndKillSafeTraps(8705, -4770)
	MoveAggroAndKillSafeTraps(8730, -5244)
	MoveAggroAndKillSafeTraps(8422, -6149)
	Info('Kill Worm Mob 7')
	MoveAggroAndKillSafeTraps(7870, -7200)
	Info('Kill Worm Mob 8')
	MoveAggroAndKillSafeTraps(7923, -7720)
	Info('Clear Final Traps for Heroes')
	CommandAll(7798, -7798)
	MoveTo(8873, -8096)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKill(9747, -8488)
	MoveAggroAndKill(9621, -9465)
	Sleep(5000)
	Info('At planes')
	Info('Collecting Lords')
	MoveAggroAndKill(9153, -10780)
	MoveAggroAndKill(10020, -11292)
	MoveAggroAndKill(10533, -10474)
	; kill mobs
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(10753, -11413)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(11809, -10680)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(10555, -10746)
	MoveAggroAndKill(9166, -11161)
	Info('Moving to spot two')
	MoveAggroAndKill(10469, -10241)
	MoveAggroAndKill(12146, -10312)
	MoveAggroAndKill(12852, -9597, '', $optionsChaosPlanes)
	MoveAggroAndKill(13227, -9181, '', $optionsChaosPlanes)
	Info('Killing...')
	MoveAggroAndKill(13192, -9027, '', $optionsChaosPlanes)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(13102, -9902, '', $optionsChaosPlanes)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(12702, -9263, '', $optionsChaosPlanes)
	MoveAggroAndKill(11573, -8295, '', $optionsChaosPlanes)
	MoveAggroAndKill(11150, -8305, '', $optionsChaosPlanes)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(11850, -8248, '', $optionsChaosPlanes)
	MoveAggroAndKill(13077, -7583, '', $optionsChaosPlanes)
	Info('Moving to spot 3')
	MoveAggroAndKill(13280, -9025)
	MoveAggroAndKill(13668, -12144)
	MoveAggroAndKill(12009, -13476)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(13019, -12773)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(10652, -14686)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(11164, -13191)
	Info('Moving to spot 4')
	MoveAggroAndKill(13646, -12643)
	MoveAggroAndKill(13938, -14000)
	MoveAggroAndKill(13736, -15558)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(13938, -14000)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(13575, -16756)
	MoveAggroAndKill(13736, -15558)
	RandomSleep(1500)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(13575, -16756)
	Info('Moving to spot 5')
	MoveAggroAndKill(13736, -15558)
	MoveAggroAndKill(13938, -14000)
	MoveAggroAndKill(13646, -12643)
	MoveAggroAndKill(10641, -11650)
	MoveAggroAndKill(8618, -11218)
	MoveAggroAndKill(7515, -12059)
	MoveAggroAndKill(8327, -13146)
	MoveAggroAndKill(8272, -14002)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(8283, -13214)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(8098, -13962)
	MoveAggroAndKill(7496, -15081)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(8268, -13928)
	MoveAggroAndKill(7807, -12111)
	MoveAggroAndKill(9218, -11620)
	Info('Moving to spot 6')
	MoveAggroAndKill(7322, -12220)
	MoveAggroAndKill(6825, -13247)
	MoveAggroAndKill(7392, -14467)
	MoveAggroAndKill(6896, -15201)
	MoveAggroAndKill(5986, -14869)
	Info('Killing Skeletons Mob')
	MoveAggroAndKill(6971, -16245)
	MoveAggroAndKill(6519, -17280)
	MoveAggroAndKill(5980, -17888)
	Info('Moving to spot 7')
	MoveAggroAndKill(4806, -17454)
	MoveAggroAndKill(5980, -17888)
	MoveAggroAndKill(3839, -18881)
	MoveAggroAndKill(3074, -19617)
	Info('Moving to spot 8')
	FlagMoveAggroAndKill(2421, -17792)
	FlagMoveAggroAndKill(2268, -15530)
	FlagMoveAggroAndKill(2168, -14641)
	Info('Moving to spot 9')
	MoveAggroAndKill(2268, -15530)
	MoveAggroAndKill(2421, -17792)
	MoveAggroAndKill(3074, -19617)
	MoveAggroAndKill(3839, -18881)
	MoveAggroAndKill(5980, -17888)
	MoveAggroAndKill(7037, -17817)
	MoveAggroAndKill(7389, -19109)
	MoveAggroAndKill(8301, -19998)
	MoveAggroAndKill(8711, -20500)
	MoveAggroAndKill(9597, -19937)
	Info('Kill Mindblade Spawns')
	MoveAggroAndKill(8711, -20500)
	RandomSleep(10000)
	MoveAggroAndKill(8711, -20500)
	Info('Moving to Spot 10')
	MoveAggroAndKill(10264, -18524)
	Info('Moving to Monument to clear Terrorweb Dryders')
	MoveAggroAndKill(11160, -17710)
	RandomSleep(5000)
	Info('Killing Mindblade Mob 1')
	$optionsChaosPlanes.Item('ignoreDroppedLoot') = True
	$optionsChaosPlanes.Item('fightRange') = $RANGE_EARSHOT * 1.5
	MoveAggroAndKill(12211, -17522, '', $optionsChaosPlanes) ; Right Short
	MoveAggroAndKill(11160, -17710, '', $optionsChaosPlanes) ; Center
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(10550, -18575, '', $optionsChaosPlanes) ; Left
	MoveAggroAndKill(11160, -17710, '', $optionsChaosPlanes) ; Center
	RandomSleep(7000)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(12211, -17522, '', $optionsChaosPlanes) ; Right Short
	MoveAggroAndKill(11160, -17710, '', $optionsChaosPlanes) ; Center
	RandomSleep(5000)
	Info('Sweeping for Safety')
	MoveAggroAndKill(12211, -17522, '', $optionsChaosPlanes) ; Right Short
	MoveAggroAndKill(11160, -17710, '', $optionsChaosPlanes) ; Center
	MoveAggroAndKill(10550, -18575, '', $optionsChaosPlanes) ; Left
	RandomSleep(5000)
	MoveAggroAndKill(12211, -17522, '', $optionsChaosPlanes) ; Right Short
	MoveAggroAndKill(11160, -17710, '', $optionsChaosPlanes) ; Center
	MoveAggroAndKill(10550, -18575, '', $optionsChaosPlanes) ; Left
	RandomSleep(5000)
	MoveAggroAndKill(12211, -17522, 'Picking Up Loot on Right Side')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(11160, -17710, 'Picking Up Loot at Reaper')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(10550, -18575, 'Picking Up Loot on Left Side')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(11160, -17710, '', $optionsChaosPlanes) ; Center

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearSpawningPools($reaper)
	Local $optionsSpawningPools = CloneDictMap($underworld_fight_options)
	$optionsSpawningPools.Item('fightRange') = $RANGE_EARSHOT
	$optionsSpawningPools.Item('flagHeroesOnFight') = True
	$optionsSpawningPools.Item('ignoreDroppedLoot') = False
	$optionsSpawningPools.Item('priorityMobs') = True
	TeleportBackToArea($reaper, '0x84', '0x8B', 'Chaos Planes')
	Info('Moving to Spawning Pools')
	MoveAggroAndKill(10235, -19396)
	MoveAggroAndKill(8730, -20479)
	MoveAggroAndKill(7864, -19622)
	MoveAggroAndKill(6793, -17598)
	MoveAggroAndKill(3052, -19590)
	MoveAggroAndKill(2367, -16766)
	MoveAggroAndKill(1922, -14866)
	Info('Moving to Spot 1')
	MoveAggroAndKill(713, -14715, '', $optionsSpawningPools)
	MoveAggroAndKill(1308, -14803, '', $optionsSpawningPools)
	MoveAggroAndKill(-1171, -16802, '', $optionsSpawningPools)
	Info('Moving to Spot 2')
	MoveAggroAndKill(-1480, -18462, '', $optionsSpawningPools)
	MoveAggroAndKill(-2248, -18375, '', $optionsSpawningPools)
	MoveAggroAndKill(-3597, -16722, '', $optionsSpawningPools)
	Info('Moving to Spot 3')
	MoveAggroAndKill(-3484, -15522, '', $optionsSpawningPools)
	MoveAggroAndKill(-4380, -14784, '', $optionsSpawningPools)
	MoveAggroAndKill(-4873, -13979, '', $optionsSpawningPools)
	MoveAggroAndKill(-5763, -12827, '', $optionsSpawningPools)
	Info('Moving to Spot 4')
	MoveAggroAndKill(-7401, -11875, '', $optionsSpawningPools)
	MoveAggroAndKill(-9322, -12164, '', $optionsSpawningPools)
	MoveAggroAndKill(-10205, -12849, '', $optionsSpawningPools)
	MoveAggroAndKill(-9322, -12164, '', $optionsSpawningPools)
	MoveAggroAndKill(-10508, -11945, '', $optionsSpawningPools)
	MoveAggroAndKill(-11924, -10782, '', $optionsSpawningPools)
	Info('Moving to Spot 5')
	MoveAggroAndKill(-9322, -12164, '', $optionsSpawningPools)
	MoveAggroAndKill(-13390, -12545, '', $optionsSpawningPools)
	MoveAggroAndKill(-12502, -13592, '', $optionsSpawningPools)
	MoveAggroAndKill(-11998, -14098, '', $optionsSpawningPools)
	MoveAggroAndKill(-12302, -15274, '', $optionsSpawningPools)
	Info('Moving to Spot 6')
	MoveAggroAndKill(-12492, -16163, '', $optionsSpawningPools)
	MoveAggroAndKill(-13533, -16502, '', $optionsSpawningPools)
	MoveAggroAndKill(-14297, -17125, '', $optionsSpawningPools)
	MoveAggroAndKill(-13563, -17632, '', $optionsSpawningPools)
	MoveAggroAndKill(-12874, -18019, '', $optionsSpawningPools)
	Info('Moving to Spot 7')
	MoveAggroAndKill(-11432, -18087, '', $optionsSpawningPools)
	MoveAggroAndKill(-10381, -17482, '', $optionsSpawningPools)
	MoveAggroAndKill(-9931, -17845, '', $optionsSpawningPools)
	MoveAggroAndKill(-9739, -19466, '', $optionsSpawningPools)
	Info('Moving to Monument to clear Terrorweb Dryders')
	$optionsSpawningPools.Item('ignoreDroppedLoot') = True
	MoveAggroAndKill(-8466, -19867, '', $optionsSpawningPools)
	Info('Move to protect Reaper')
	MoveAvoidingBodyBlock(-7150, -19480)
	KillFoesInArea($optionsSpawningPools)
	MoveAggroAndKill(-6254, -20456, '', $optionsSpawningPools)
	MoveAggroAndKill(-5280, -19470, '', $optionsSpawningPools)
	MoveAggroAndKill(-6340, -18499, '', $optionsSpawningPools)
	MoveAggroAndKill(-6962, -19505, '', $optionsSpawningPools)
	Info('Picking Up Loot')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(-7102, -19484, '', $optionsSpawningPools)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(-5280, -19470, '', $optionsSpawningPools)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(-6340, -18499, '', $optionsSpawningPools)
	MoveAggroAndKill(-6962, -19505, '', $optionsSpawningPools)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func TerrorwebQueen()
	; Take Quest Terrorweb Queen from the Reaper of the Spawning Pools
	Local $reaper = GetNearestNPCToCoords(-6962, -19505)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_TERRORWEB_QUEEN Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_TERRORWEB_QUEEN] &' quest per settings.')
		TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsSpawningPools = CloneDictMap($underworld_fight_options)
	$optionsSpawningPools.Item('fightRange') = $RANGE_EARSHOT
	$optionsSpawningPools.Item('flagHeroesOnFight') = True
	$optionsSpawningPools.Item('ignoreDroppedLoot') = False
	$optionsSpawningPools.Item('priorityMobs') = True
	TakeQuest($reaper, $ID_QUEST_TERRORWEB_QUEEN, 0x806B01, 0x806B03)
	Info('Clearing Exterior')
	MoveAggroAndKill(-8585, -19681)
	MoveAggroAndKill(-9400, -17320)
	MoveAggroAndKill(-10559, -17253)
	MoveAggroAndKill(-11617, -17931)
	MoveAggroAndKill(-12004, -17412)
	MoveAggroAndKill(-13004, -16973)
	Info('Moving to Queen')
	MoveAggroAndKill(-12526, -16388, '', $optionsSpawningPools)
	MoveAggroAndKill(-12422, -15861, '', $optionsSpawningPools)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	Info('Moving back to Reaper & parking heroes')
	MoveAggroAndKill(-11447, -17260)
	CommandAll(-14324, -17073)
	MoveAggroAndKill(-9400, -17320)
	MoveAggroAndKill(-8585, -19681)
	MoveAggroAndKill(-6962, -19505)
	MoveTo(-6736, -19084)
	; Loot Chest
	Sleep(1000)
	Info('Looting chest')
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	CancelAll()
	TakeQuestReward($reaper, $ID_QUEST_TERRORWEB_QUEEN, 0x806B07)
	TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearBonePits($reaper)
	Local $optionsBonePits = CloneDictMap($underworld_fight_options)
	$optionsBonePits.Item('fightRange') = $RANGE_EARSHOT * 1.1
	$optionsBonePits.Item('flagHeroesOnFight') = False
	$optionsBonePits.Item('ignoreDroppedLoot') = False
	TeleportBackToArea($reaper, '0x84', '0x8B', 'Chaos Planes')
	MoveAggroAndKill(13653, -16965)
	Info('Let us make sure Reaper is ok before proceeding.')
	MoveAggroAndKill(12564, -17553)
	MoveAggroAndKill(11306, -17893)
	RandomSleep(10000)
	MoveAggroAndKill(10430, -18514)
	MoveAggroAndKill(11306, -17893)
	Sleep(10000)
	Info('Moving to Bone Pits')
	MoveAggroAndKill(13653, -16965)
	MoveAggroAndKill(13926, -13717)
	MoveAggroAndKill(13403, -10107)
	Info('Moving to Spot 1')
	MoveAggroAndKill(12928, -7262)
	MoveAggroAndKill(12037, -5339)
	MoveAggroAndKill(10951, -3185)
	Info('Moving to Spot 2')
	MoveAggroAndKill(11503, -1978)
	MoveAggroAndKill(10331, -63, '', $optionsBonePits)
	MoveAggroAndKill(11141, 87, '', $optionsBonePits)
	Info('Moving to Spot 3')
	MoveAggroAndKill(11953, -617, '', $optionsBonePits)
	MoveAggroAndKill(12904, -850, '', $optionsBonePits)
	MoveAggroAndKill(13601, -397, '', $optionsBonePits)
	MoveAggroAndKill(14240, -165, '', $optionsBonePits)
	MoveAggroAndKill(14437, 661, '', $optionsBonePits)
	MoveAggroAndKill(14507, 1522, '', $optionsBonePits)
	MoveAggroAndKill(14214, 2627, '', $optionsBonePits)
	Info('Moving to Spot 4')
	MoveAggroAndKill(15012, 3185, '', $optionsBonePits)
	MoveAggroAndKill(15732, 2686, '', $optionsBonePits)
	MoveAggroAndKill(15756, 1806, '', $optionsBonePits)
	Info('Moving to Spot 5')
	MoveAggroAndKill(15775, 840)
	MoveAggroAndKill(15442, 198)
	MoveAggroAndKill(13277, 1171)
	MoveAggroAndKill(13741, 3481)
	MoveAggroAndKill(12702, 1854)
	Info('Moving to Spot 6')
	MoveAggroAndKill(12325, 3612)
	MoveAggroAndKill(13305, 5036)
	MoveAggroAndKill(14020, 7369)
	MoveAggroAndKill(15497, 6824)
	MoveAggroAndKill(15092, 4850)
	MoveAggroAndKill(15497, 6824)
	MoveAggroAndKill(14020, 7369)
	MoveAggroAndKill(13305, 5036)
	MoveAggroAndKill(12291, 4345)
	Info('Moving to Spot 7')
	MoveAggroAndKill(11763, 5315)
	MoveAggroAndKill(11964, 7474)
	MoveAggroAndKill(11228, 7159)
	Info('Moving to Spot 8')
	MoveAggroAndKill(10333, 4245)
	MoveAggroAndKill(9743, 5146)
	Info('Moving to Monument to clear Terrorweb Dryders')
	MoveAggroAndKill(10076, 6717)
	MoveAggroAndKill(9145, 6561)
	MoveAggroAndKill(8759, 6314)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ImprisonedSpirits()
	; Take Quest Imprisoned Spirits from the Reaper of the Bone Pits
	Local $reaper = GetNearestNPCToCoords(8759, 6314)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_IMPRISONED_SPIRITS Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_IMPRISONED_SPIRITS] &' quest per settings.')
		TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsBonePits = CloneDictMap($underworld_fight_options)
	$optionsBonePits.Item('fightRange') = $RANGE_EARSHOT
	$optionsBonePits.Item('flagHeroesOnFight') = False
	$optionsBonePits.Item('ignoreDroppedLoot') = True
	$optionsBonePits.Item('priorityMobs') = True
	Info('Setting heroes up for quest')
	CommandHero(1, 12815, 4535)
	CommandHero(2, 12600, 3110)
	CommandHero(3, 12100, 3260)
	CommandHero(4, 12320, 4320)
	CommandHero(5, 12115, 3875)
	CommandHero(6, 12800, 3545)
    CommandHero(7, 13100, 4170)
	RandomSleep(30000)
	TakeQuest($reaper, $ID_QUEST_IMPRISONED_SPIRITS, 0x806901, 0x806903)
	MoveTo(12525, 3865)
	KillFoesInArea($optionsBonePits)
	Info('Killing waves of Dryders and Skeletons')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_IMPRISONED_SPIRITS) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_IMPRISONED_SPIRITS])
			ExitLoop
		Else
			KillFoesInArea($optionsBonePits)
			RandomSleep(5000)
		EndIf
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_IMPRISONED_SPIRITS])
		Return $FAIL
	EndIf
	; Loot here
	Info('Picking up Loot')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveTo(12388, 3054)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	Info('Parking Heroes out of loot range for chest.')
	CancelAllHeroes()
	RandomSleep(250)
	CommandAll(12799, 2226)
	Info('Going back to Reaper for quest turn-in and chest.')
	MoveTo(11763, 5315)
	MoveTo(11964, 7474)
	MoveTo(11228, 7159)
	MoveTo(10058, 8105)
	MoveTo(9233, 7416)
	MoveTo(8759, 6314)
	; Loot Chest
	Sleep(1000)
	Info('Looting chest')
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	CancelAll()
	TakeQuestReward($reaper, $ID_QUEST_IMPRISONED_SPIRITS, 0x806907)
	TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearTwinSerpentMountains()
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_DEMON_ASSASSIN Then
		Info('Skipping Twin Serpent Mounts Area as per settings')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsTwinSerpentMountains = CloneDictMap($underworld_fight_options)
	$optionsTwinSerpentMountains.Item('fightRange') = $RANGE_EARSHOT * 0.9
	$optionsTwinSerpentMountains.Item('flagHeroesOnFight') = False
	$optionsTwinSerpentMountains.Item('ignoreDroppedLoot') = False
	$optionsTwinSerpentMountains.Item('priorityMobs') = True
	Info('Moving to Twin Serpent Mountains')
	MoveAggroAndKill(-4922, 13288)
	MoveAggroAndKill(-127, 13346)
	MoveAggroAndKill(1077, 12548)
	MoveAggroAndKill(1218, 10407)
	MoveAggroAndKill(2143, 10472)
	MoveAggroAndKill(3031, 10071)
	MoveAggroAndKill(3538, 7483)
	MoveAggroAndKill(4144, 5637)
	MoveAggroAndKill(3131, 5571)
	MoveAggroAndKill(2179, 4514)
	MoveAggroAndKill(1545, 4634)
	MoveAggroAndKill(217, 3801)
	MoveAggroAndKillSafeTraps(412, 1324)
	MoveAggroAndKillSafeTraps(1835, 2562)
	;Pre-Clear for Unwanted Guests Quest
	Info('Killing Worm 1')
	MoveAggroAndKillSafeTraps(2968, 2616)
	MoveAggroAndKillSafeTraps(3030, 2259)
	MoveAggroAndKillSafeTraps(2684, 1457)
	MoveAggroAndKillSafeTraps(3820, 1178)
	Info('Killing Worm 2')
	MoveAggroAndKillSafeTraps(4608, 1467)
	Info('Killing Worm 3')
	MoveAggroAndKillSafeTraps(5453, 602)
	Info('Taking shorter path')
	Info('Moving to Spot 1')
	MoveAggroAndKillSafeTraps(4844, -2010)
	Info('Clear Traps for Heroes')
	CommandAll(4850, -1613)
	MoveTo(4080, -1885)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Spot 2')
	MoveAggroAndKillSafeTraps(3106, -2463)
	Info('Clear Traps for Heroes')
	CommandAll(3212, -2281)
	MoveTo(2150, -2710)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Spot 3')
	MoveAggroAndKillSafeTraps(-854, -3370)
	Info('Clear Traps for Heroes')
	CommandAll(-657, -3100)
	MoveTo(-1400, -3908)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Spot 4')
	MoveAggroAndKillSafeTraps(-3901, -5809, '', $optionsTwinSerpentMountains)
	MoveAggroAndKillSafeTraps(-4281, -5058, '', $optionsTwinSerpentMountains)
	Info('Clear Traps for Heroes')
	CommandAll(-4281, -5058)
	MoveTo(-5032, -4363)
	MoveTo(-4281, -5058)
	RandomSleep(5000)
	CancelAll()
	$optionsTwinSerpentMountains.Item('ignoreDroppedLoot') = True
	MoveAggroAndKillSafeTraps(-4649, -5910, '', $optionsTwinSerpentMountains)
	Info('Moving to Spot 5')
	MoveAggroAndKillSafeTraps(-4281, -5058, '', $optionsTwinSerpentMountains)
	MoveAggroAndKillSafeTraps(-5334, -4614, '', $optionsTwinSerpentMountains)
	Info('Clear Traps for Heroes')
	CommandAll(-5334, -4614)
	MoveTo(-5866, -4621)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(-6421, -6062, '', $optionsTwinSerpentMountains)
	MoveAggroAndKillSafeTraps(-7086, -6240, '', $optionsTwinSerpentMountains)
	Info('Clear Traps for Heroes')
	CommandAll(-7086, -6240)
	MoveTo(-7418, -5871)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Monument to clear Terrorweb Dryders')
	MoveAggroAndKillSafeTraps(-7418, -5871, '', $optionsTwinSerpentMountains)
	MoveAggroAndKillSafeTraps(-7284, -4115, '', $optionsTwinSerpentMountains)
	$optionsTwinSerpentMountains.Item('fightRange') = $RANGE_EARSHOT * 1.25
	MoveAggroAndKillSafeTraps(-8150, -4800, '', $optionsTwinSerpentMountains)
	CommandAll(-7988, -4615)
	MoveTo(8220, 5202)
	Sleep(5000)
	CancelAll()
	MoveTo(8220, 5202)
	
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func DemonAssassin()
	; Take Quest Demon Assassin from the Reaper of the Twin Serpent Mountains & defend
	Local $reaper = GetNearestNPCToCoords(8220, 5202)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_DEMON_ASSASSIN Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_DEMON_ASSASSIN] &' quest per settings.')
		TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsTwinSerpentMountains = CloneDictMap($underworld_fight_options)
	$optionsTwinSerpentMountains.Item('fightRange') = $RANGE_EARSHOT * 1.5
	$optionsTwinSerpentMountains.Item('flagHeroesOnFight') = False
	$optionsTwinSerpentMountains.Item('ignoreDroppedLoot') = True
	$optionsTwinSerpentMountains.Item('priorityMobs') = True
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT)
	MoveTo(8220, 5202)
	Info('Setting heroes up for quest')
	CommandHero(1, -4629, -5282)
	CommandHero(2, -4928, -5373)
	CommandHero(3, -4535, -5765)
	CommandHero(4, -4898, -5730)
	CommandHero(5, -4792, -6052)
	CommandHero(6, -5288, -5621)
	CommandHero(7, -5165, -6047)
	RandomSleep(16000)
	TakeQuest($reaper, $ID_QUEST_DEMON_ASSASSIN, 0x806801, 0x806803)
	MoveTo(-4742, -5531)
	Info('Killing the Slayer')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_DEMON_ASSASSIN) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_IMPRISONED_SPIRITS])
			ExitLoop
		Else
			KillFoesInArea($optionsTwinSerpentMountains)
			RandomSleep(5000)
		EndIf
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_IMPRISONED_SPIRITS])
		Return $FAIL
	EndIf
	Info('Waiting for the waves of Dryders')
	RandomSleep(50000)
	Info('Killing Dryders')
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT*2.35)
	While IsPlayerOrPartyAlive() And UBound($foes) > 0
		MoveTo(-4629, -5282)
		KillFoesInArea($optionsTwinSerpentMountains)
		RandomSleep(5000)
		$foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT*2.35)
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Failed Dryders Waves on Demon Assassin Quest')
		Return $FAIL
	EndIf
	Info('Picking up Loot')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveTo(-4742, -5531)
	CancelAllHeroes()
	RandomSleep(250)
	Info('Parking Heroes out of loot range for chest.')
	CommandAll(-381, -2955)
	MoveTo(-7055, -5970)
	MoveTo(-8426, -5685)
	; Loot Chest
	Sleep(1000)
	Info('Looting chest')
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	CancelAll()
	TakeQuestReward($reaper, $ID_QUEST_DEMON_ASSASSIN, 0x806807)
	TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func EscortOfSouls($reaper, $reaper_ForgottenVale)
	; Take Quest Escort of Souls from the Reaper in the Labyrinth
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_ESCORT_OF_SOULS Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_ESCORT_OF_SOULS] &' quest per settings.')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Info('Setting heroes up for quest')
	CommandAll(-5190, 8820)
	RandomSleep(16000)
	TakeQuest($reaper, $ID_QUEST_ESCORT_OF_SOULS, 0x806C03, 0x806C01)
	MoveTo(-5190, 8820)
	CancelAll()
	MoveAggroAndKill(-5190, 8820, 'Spot 1')
	MoveAggroAndKill(-5761, 8496, 'Spot 2')
	MoveAggroAndKill(-8720, 5614, 'Spot 3')
	MoveAggroAndKill(-7358, 3543, 'Spot 4')
	MoveTo(-7700, 2290)
	MoveAggroAndKill(-7700, 2290, 'Spot 5')
	MoveAggroAndKill(-9457, 2155, 'Spot 6')
	MoveAggroAndKill(-12610, 886, 'Spot 7')
	MoveAggroAndKill(-12122, 968, 'Spot 8')
	Local $MayorAlegheri = GetNearestNPCToCoords(-12122, 968)
	Info('Waiting for Souls to come to the Vale')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_ESCORT_OF_SOULS) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_ESCORT_OF_SOULS])
			ExitLoop
		Else
			RandomSleep(5000)
		EndIf
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_ESCORT_OF_SOULS])
		Return $FAIL
	EndIf
	TakeQuestReward($MayorAlegheri, $ID_QUEST_ESCORT_OF_SOULS, 0x806C07)
	Info('Moving back to the Labyrinth')
	MoveTo(-13766, 1311)
	MoveTo(-13550, 4930)
	TeleportBackToArea($reaper_ForgottenVale, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc

Func UnwantedGuests($reaper)
	; Take Quest Unwanted Guests from the Reaper in the Labyrinth
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_UNWANTED_GUESTS Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_UNWANTED_GUESTS] &' quest per settings.')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsUnwantedGuests = CloneDictMap($underworld_fight_options)
	$optionsUnwantedGuests.Item('fightRange') = $RANGE_EARSHOT * 1.25
	$optionsUnwantedGuests.Item('flagHeroesOnFight') = False
	$optionsUnwantedGuests.Item('ignoreDroppedLoot') = True
	$optionsUnwantedGuests.Item('priorityMobs') = True
	Info('Setting heroes up for quest')
	CommandAll(-7362, 14283)
	Info('Waiting 20 seconds for life spirits to expire')
	RandomSleep(20000)
	TakeQuest($reaper, $ID_QUEST_UNWANTED_GUESTS, 0x806703, 0x806701)
	; Rarely the dryder spawn will pat too far and aggro the Reaper
	Info('Moving to the Forgotten Vale')
	TeleportBackToArea($reaper, '0x8A', '0x91', 'Forgotten Vale')
	CancelAll()
	MoveTo(-13783,  1170)
	MoveTo(-12610, 886)
	MoveTo(-7643, 2332)
	MoveTo(-7400, 3630)
	MoveTo(-7760, 4130)
	TrackVengefulAatxes(-6390, 7858, 'away')
	MoveAvoidingBodyBlock(-8670, 5690)
	Info('Killing Keeper of Souls 1')
	KillKeeperOfSouls()
	MoveAggroAndKill(-8670, 5690)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	MoveAggroAndKill(-5233, 8960)
	MoveTo(-5233, 8961)
	MoveTo(-6366, 10238)
	TrackVengefulAatxes(-4673, 11711, 'nearby', $RANGE_COMPASS -  1000)
	RandomSleep(10000)
	TrackVengefulAatxes(-2436, 10363, 'away', $RANGE_COMPASS -  1000)
	MoveAvoidingBodyBlock(-4825, 12075)
	MoveAvoidingBodyBlock(-4250, 11560)
	MoveAvoidingBodyBlock(-3350, 10555)
	Info('Killing Keeper of Souls 2')
	KillKeeperOfSouls($RANGE_SPIRIT)
	MoveAggroAndKill(-3350, 10555)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	MoveTo(-5722, 12758)
	MoveTo(-4886, 13309)
	MoveTo(-4480, 13320)
	TrackVengefulAatxes(-4480, 13320, 'nearby', $RANGE_COMPASS, $RANGE_EARSHOT * 2)
	TrackVengefulAatxes(-10, 13312, 'away')
	MoveAvoidingBodyBlock(-1046, 13343)
	Info('Killing Keeper of Souls 3')
	KillKeeperOfSouls($RANGE_SPIRIT)
	MoveAggroAndKill(-1046, 13343)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	MoveAggroAndKill(224, 13362)
	MoveTo(915, 12787)
	TrackVengefulAatxes(1875, 10465, 'nearby', $RANGE_COMPASS, $RANGE_EARSHOT)
	TrackVengefulAatxes(-180, 9400, 'away', $RANGE_COMPASS, $RANGE_EARSHOT) ; old coords 336, 9321
	MoveAvoidingBodyBlock(2422, 10322)
	Info('Killing Keeper of Souls 4')
	KillKeeperOfSouls($RANGE_SPIRIT)
	MoveAggroAndKill(2422, 10322)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	MoveTo(1200, 10700)
	MoveAggroAndKill(224, 13362)
	MoveTo(-1167, 13345)
	MoveTo(-4886, 13309)
	MoveTo(-5722, 12758)
	TeleportBackToArea($reaper, '0x87', '0x8E', 'Twin Serpent Mountains')
	MoveAggroAndKillSafeTraps(-3757, -5800)
	MoveAggroAndKillSafeTraps(-175, -2678)
	MoveAggroAndKillSafeTraps(4660, -2347)
	MoveAggroAndKillSafeTraps(5371, 300)
	MoveAggroAndKillSafeTraps(2753, 2853)
	MoveTo(1650, 2230)
	TrackVengefulAatxes(-2424, 1767, 'away')
	RandomSleep(5000)
	CommandAll(1650, 2230)
	Info('Aggro killable mobs away from Vengeful Aatxe path')
	MoveAvoidingBodyBlock(367, 1623)
	MoveAvoidingBodyBlock(90, 1940)
	MoveAvoidingBodyBlock(367, 1623)
	MoveAvoidingBodyBlock(1650, 2230)
	CancelAll()
	KillFoesInArea($optionsUnwantedGuests)
	CommandAll(1650, 2230)
	RandomSleep(5000)
	CancelAll()
	KillFoesInArea($optionsUnwantedGuests)
	CommandAll(1650, 2230)
	RandomSleep(5000)
	TrackVengefulAatxes(-2424, 1767, 'away')
	CancelAll()
	MoveAvoidingBodyBlock(-214, 2775)
	MoveAvoidingBodyBlock(267, 3575)
	Info('Killing Keeper of Souls 5')
	KillKeeperOfSouls($RANGE_SPIRIT)
	MoveAggroAndKill(267, 3575)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
	MoveAggroAndKill(-3436, 1260)
	MoveAggroAndKill(-3184, 4456)
	MoveTo(-2690, 5115)
	TrackVengefulAatxes(-1255, 6500, 'nearby')
	TrackVengefulAatxes(980, 7740, 'away')
	MoveAvoidingBodyBlock(-630, 6415)
	Info('Killing Keeper of Souls 6')
	KillKeeperOfSouls()
	MoveAggroAndKill(-630, 6415)
	If Not IsPlayerOrPartyAlive() Then Return $FAIL
	MoveAggroAndKill(-1380, 10396)
	MoveAggroAndKill(-5703, 12732)
	If IsQuestReward($ID_QUEST_UNWANTED_GUESTS) Then 
		Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_UNWANTED_GUESTS])
		TakeQuestReward($reaper, $ID_QUEST_UNWANTED_GUESTS, 0x806707)
	Else
		Info('Quest Failed?: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_UNWANTED_GUESTS])
		If IsPlayerOrPartyAlive() Then UnwantedGuests($reaper)
	EndIf

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Return true if agent is a Keeper of Souls
Func IsKeeperOfSouls($agent)
	Return DllStructGetData($agent, 'ModelID') == $ID_KEEPER_OF_SOULS
EndFunc


;~ Kill Keeper of Souls if found
Func KillKeeperOfSouls($range = $RANGE_COMPASS)
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $range, IsKeeperOfSouls)
	If IsArray($foes) And UBound($foes) > 0 Then
		Local $keeperOfSouls = $foes[0]
		MoveAggroAndKill(DllStructGetData($keeperOfSouls, 'X'), DllStructGetData($keeperOfSouls, 'Y'))
	EndIf
	Return $SUCCESS
EndFunc

;~ Return true if agent is a Vengeful Aatxe
Func IsVengefulAatxe($agent)
	Return DllStructGetData($agent, 'ModelID') == $ID_VENGEFUL_AATXE
EndFunc


;~ Wait for Vengeful Aatxe to pat
Func TrackVengefulAatxes($x, $y, $direction = 'away', $range = $RANGE_COMPASS, $distance = $RANGE_NEARBY) 
	Info('Waiting for Vengeful Aatxe to pat ' & $direction & '.' )
    Local $vengefulAaxteNearSpot = False
    While Not $vengefulAaxteNearSpot
        Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $range, IsVengefulAatxe)
        If IsArray($foes) And UBound($foes) > 0 Then
            For $i = 0 To UBound($foes) - 1
                Local $vengefulAaxte = $foes[$i]
                If IsAgentInRange($vengefulAaxte, $x, $y, $distance) Then
                    $vengefulAaxteNearSpot = True
                    ExitLoop
                EndIf
            Next
            If Not $vengefulAaxteNearSpot Then
                RandomSleep(1000)
            EndIf
        Else
            Info('No Vengeful Aatxe found.')
            ExitLoop
        EndIf
    WEnd
    Return $SUCCESS
EndFunc


Func TheFourHorsemen($reaper)
	Local $reaper_ChaosPlanes = GetNearestNPCToCoords(11306, -17893)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_THE_FOUR_HORSEMEN Or $underworld_player_profession <> $ID_RITUALIST Or $ID_ASSASSIN Then
		Info('Skipping ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_THE_FOUR_HORSEMEN] &' quest per settings.')
		TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsChaosPlanes = CloneDictMap($underworld_fight_options)
	$optionsChaosPlanes.Item('fightRange') = $RANGE_EARSHOT * 1.5
	$optionsChaosPlanes.Item('flagHeroesOnFight') = False
	$optionsChaosPlanes.Item('ignoreDroppedLoot') = True
	$optionsChaosPlanes.Item('priorityMobs') = True
	Info('Setting heroes & spirits up for quest')
	CommandHero(1, 13153, -12503)
	CommandHero(2, 13795, -12084)
	CommandHero(3, 13413, -12219)
	CommandHero(4, 13414, -12808)
	CommandHero(5, 13697, -12538)
	CommandHero(6, 13689, -12910)
	CommandHero(7, 13987, -12807)

	UseSkillEx($UNDERWORLD_RECALL, $reaper_ChaosPlanes)
	MoveTo(6768, -16996)
	UseSkillEx($UNDERWORLD_VAMPIRISM)
	MoveTo(7235, -17161)
	UseSkillEx($UNDERWORLD_BLOODSONG)
	MoveTo(7500, -17560)
	UseSkillEx($UNDERWORLD_PAIN)
	MoveTo(6855, -17622)
	UseSkillEx($UNDERWORLD_SIGNET_OF_SPIRITS)
	UseSkillEx($UNDERWORLD_ARMOR_OF_UNFEELING)
	DropBuff($ID_RECALL, GetMyAgent())
	Sleep(5000)
	TakeQuest($reaper_ChaosPlanes, $ID_QUEST_THE_FOUR_HORSEMEN, 0x806A01, 0x806A03)
	UseSkillEx($UNDERWORLD_RECALL, $reaper_ChaosPlanes)
	MoveTo(7468, -19050)
	Sleep(7000)

	Local $myHealth = DllStructGetData(GetMyAgent(), 'HealthPercent')
	While $myHealth > 0.3
		; Recast Spirits @ new spot
		UseSkillEx($UNDERWORLD_VAMPIRISM)
		MoveTo(7540, -19425)
		UseSkillEx($UNDERWORLD_BLOODSONG)
		MoveTo(7890, -19275)
		UseSkillEx($UNDERWORLD_PAIN)
		$myHealth = DllStructGetData(GetMyAgent(), 'HealthPercent')
		MoveTo(7770, -19742)
		UseSkillEx($UNDERWORLD_SIGNET_OF_SPIRITS)
		MoveTo(8132, -19510)
		UseSkillEx($UNDERWORLD_ANGUISH)
		UseSkillEx($UNDERWORLD_ARMOR_OF_UNFEELING)
		MoveTo(10480, -19800)
		$myHealth = DllStructGetData(GetMyAgent(), 'HealthPercent')
		Sleep(10000)
		$myHealth = DllStructGetData(GetMyAgent(), 'HealthPercent')
	
		; Recast Spirits @ new spot
		UseSkillEx($UNDERWORLD_VAMPIRISM)
		MoveTo(10355, -19490)
		UseSkillEx($UNDERWORLD_BLOODSONG)
		MoveTo(10770, -19690)
		UseSkillEx($UNDERWORLD_PAIN)
		MoveTo(10660, -19330)
        $myHealth = DllStructGetData(GetMyAgent(), 'HealthPercent')
		UseSkillEx($UNDERWORLD_SIGNET_OF_SPIRITS)
		UseSkillEx($UNDERWORLD_ARMOR_OF_UNFEELING)
		MoveTo(10525, -16735)
        $myHealth = DllStructGetData(GetMyAgent(), 'HealthPercent')
        Sleep(10000)

		ExitLoop
	WEnd
	
	DropBuff($ID_RECALL, GetMyAgent())
	TeleportBackToArea($reaper, '0x86', '0x8D', 'Labyrinth')
	CancelAllHeroes()
	TeleportBackToArea($reaper, '0x84', '0x8B', 'Chaos Planes')

	CommandHero(1, 11076, -17974)
	CommandHero(2, 11563, -17492)
	CommandHero(3, 11744, -17898)
	CommandHero(4, 10867, -17746)
	CommandHero(5, 11420, -17833)
	CommandHero(6, 11240, -17213)
	CommandHero(7, 10894, -17430)

	Info('Final Stand against the Four Horsemen at Reaper.')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_THE_FOUR_HORSEMEN) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_THE_FOUR_HORSEMEN])
			ExitLoop
		Else
			Local $four_minute_timer = TimerInit()
			; Protect Reaper for 4 minutes
			While TimerDiff($four_minute_timer) < 4 * 60 * 1000 And IsPlayerOrPartyAlive()
				MoveTo(11210, -17560)
				KillFoesInArea($optionsChaosPlanes)
				RandomSleep(5000)
				If IsQuestReward($ID_QUEST_THE_FOUR_HORSEMEN) Then ExitLoop
			WEnd
			; If quest still isn't complete, roam and search for stuck horseman
			If Not IsQuestReward($ID_QUEST_THE_FOUR_HORSEMEN) And IsPlayerOrPartyAlive() Then
				Info('Quest still not complete. Roaming for last Horseman.')
				While IsPlayerOrPartyAlive() And Not IsQuestReward($ID_QUEST_THE_FOUR_HORSEMEN)
                    CancelAllHeroes()
                    MoveAggroAndKill(11200, -17615)
                    MoveAggroAndKill(10000, -19630)
					MoveAggroAndKill(13800, -15800)
                    RandomSleep(10000)
					If IsQuestReward($ID_QUEST_THE_FOUR_HORSEMEN) Then ExitLoop
                    MoveAggroAndKill(13730, -12820)
                    MoveAggroAndKill(11555, -13500)
                    MoveAggroAndKill(13432, -10358)
				WEnd
			EndIf
		EndIf
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_THE_FOUR_HORSEMEN])
		Return $FAIL
	EndIf
	CancelAllHeroes()
	Info('Parking Heroes out of loot range for chest.')
	CommandAll(13153, -12503)
	MoveTo(11210, -17560)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT * 2)
	Info('Going to loot any drops on this side')
	MoveTo(7685, -19340)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT * 2)
	Info('Going back to Reaper.')
	MoveTo(11306, -17893)
	; Loot Chest
	Info('Looting chest')
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	CancelAll()


	TakeQuestReward($reaper_ChaosPlanes, $ID_QUEST_THE_FOUR_HORSEMEN, 0x806A07)
	TeleportBackToArea($reaper_ChaosPlanes, '0x86', '0x8D', 'Labyrinth', Null)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc
