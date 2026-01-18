#CS ===========================================================================
==================================================
|	Underworld clearing farm bot		         |
|	Authors: Akiro/The Great Gree		         |
| Rewrite Authors for BotsHub: Gahais, BuddyLeeX |
==================================================
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
Global Const $UNDERWORLD_FARM_INFORMATIONS = 'For best results, don''t cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'Due to Hero Flag mechanics place healers in slots 6-8' & @CRLF _
	& 'In NM with quests disabled bot takes about 1 hour 30 minutes to clear/farm on average.' & @CRLF _
	& 'In NM with quests enabled bot takes about 2 hours 15 minutes to clear on average.' & @CRLF _
	& 'Bot not tested in HM' & @CRLF _
	& 'Make sure to set loot filters to purple swords in case crystalline sword drops from quest chests.' & @CRLF _
	& 'Manually set $ATTEMPT_REAPER_QUESTS to False if you want to farm ecto only.' & @CRLF _
	& 'Or disable specific Reaper quests that take too long.' & @CRLF _
	& 'Bot is still under development and not all quests are implemented yet.' & @CRLF

Global Const $UW_FARM_DURATION = 90 * 60 * 1000 ; Runs take about 90 minutes if quests set to False
Global Const $MAX_UW_FARM_DURATION = 135 * 60 * 1000 ; Runs take about 135 minutes if all quests set to True

Global Const $ATTEMPT_REAPER_QUESTS = False ; Set this to True in order for bot to do Reaper quests

; Specific Quest Knobs
Global Const $ENABLE_WRATHFULSPIRITS = False ; Quest takes too long and mobs don't drop loot.
Global Const $ENABLE_SERVANTSOFGRENTH = True
Global Const $ENABLE_THEFOURHORSEMEN = False ; Quest not implemented yet.
Global Const $ENABLE_TERRORWEBQUEEN = True
Global Const $ENABLE_IMPRISONEDSPIRITS = True
Global Const $ENABLE_DEMONASSASSIN = False ; Behemoths don't drop ecto. Skips Mountain area too.

Global $UNDERWORLD_FIGHT_OPTIONS = CloneDictMap($Default_MoveAggroAndKill_Options)

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
	SwitchToHardModeIfEnabled()
	$uw_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func UnderworldFarmLoop()
	Info('Starting Farm')

	ClearTheChamberUnderworld()

	; Accept reward & take quest Restoring Grenth's Monuments
	Local $Reaper_Labyrinth = GetNearestNPCToCoords(-5694, 12772)
	TakeQuestReward($Reaper_Labyrinth, $ID_QUEST_CLEAR_THE_CHAMBER, 0x806507)
	TakeQuest($Reaper_Labyrinth, $ID_QUEST_RESTORING_GRENTH_S_MONUMENTS, 0x806D01, 0x806D03)
	Info('Taking ''Restoring Grenths Monuments'' Quest')

	ClearTheForgottenVale()
	; Take Quest Wrathful spirits from the Reaper and complete
	Local $Reaper_ForgottenVale
	$Reaper_ForgottenVale = GetNearestNPCToCoords(-13211, 5322)
	WrathfulSpirits($Reaper_ForgottenVale)

	ClearTheFrozenWastes()
	; Take Quest Servants of Grenth from Reaper of the Ice Wastes
	Local $Reaper_IceWastes
	$Reaper_IceWastes = GetNearestNPCToCoords(526, 18407)
	ServantsOfGrenth($Reaper_IceWastes)

	ClearTheChaosPlanes()
	; Take Quest The Four Horsemen from Reaper of the Chaos Planes
	Local $Reaper_ChaosPlanes
	$Reaper_ChaosPlanes = GetNearestNPCToCoords(11306, -17893)
	; TODO: Currently this function simply takes player back to Labyrinth Reaper
	TheFourHorsemen($Reaper_ChaosPlanes)

	ClearSpawningPools($Reaper_Labyrinth)
	; Take Quest Terrorweb Queen from the Reaper of the Spawning Pools
	Local $Reaper_SpawningPools
	$Reaper_SpawningPools = GetNearestNPCToCoords(-6962, -19505)
	TerrorwebQueen($Reaper_SpawningPools)

	ClearBonePits($Reaper_Labyrinth)
	; Take Quest Imprisoned Spirits from the Reaper of the Bone Pits
	Local $Reaper_BonePits
	$Reaper_BonePits = GetNearestNPCToCoords(8759, 6314)
	ImprisonedSpirits($Reaper_BonePits)

	If $ATTEMPT_REAPER_QUESTS == True Then
		ClearTwinSerpentMountains()
		; Take Quest Demon Assassin from the Reaper of the Twin Serpent Mountains & defend
		Local $Reaper_TwinSerpentMountains
		$Reaper_TwinSerpentMountains = GetNearestNPCToCoords(8220, 5202)
		DemonAssassin($Reaper_TwinSerpentMountains)
	Else
		Info('Skipping ''Twin Serpent Mounts'' Area as per settings')
	EndIf

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc

;~ Send user back to Chaos Plains
Func TeleportBackToChaosPlains($Reaper)
	Info('Teleporting back to Chaos Plains')
	Sleep(1000)
	GoToNPC($Reaper)
	Sleep(1000)
	Dialog(0x7F)
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	Dialog(0x8B)
	Sleep(1000)
EndFunc

;~ Send user back to Labyrinth if skipping quest
Func TeleportBackToLabyrinthQuestSkip($Reaper)
	Info('Teleporting back to Labyrinth')
	Sleep(1000)
	GoToNPC($Reaper)
	Sleep(1000)
	Dialog(0x7F)
	Sleep(1000)
	Dialog(0x86)
	Sleep(1000)
	Dialog(0x8D)
	Sleep(1000)
EndFunc

;~ Send user back to Labyrinth after completing quest
Func TeleportBackToLabyrinthQuestComplete($Reaper)
	Info('Teleporting back to Labyrinth')
	Sleep(1000)
	GoToNPC($Reaper)
	Sleep(1000)
	Dialog(0x86)
	Sleep(1000)
	Dialog(0x8D)
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

	Info('Taking ''Clear the Chamber'' Quest')
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
	Local $optionsForgottenVale = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsForgottenVale.Item('fightRange') = $RANGE_EARSHOT * 1.2
	$optionsForgottenVale.Item('flagHeroesOnFight') = False
	$optionsForgottenVale.Item('doNotLoot') = False
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

Func WrathfulSpirits($Reaper)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_WRATHFULSPIRITS Then
		Info('Skipping ''Wrathful Spirits'' Quest as per settings')
		TeleportBackToLabyrinthQuestSkip($Reaper)
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsForgottenVale = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsForgottenVale.Item('fightRange') = $RANGE_EARSHOT
	$optionsForgottenVale.Item('flagHeroesOnFight') = False
	$optionsForgottenVale.Item('doNotLoot') = False
	TakeQuest($Reaper, $ID_QUEST_WRATHFUL_SPIRITS, 0x806E01, 0x806E03)
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_WRATHFUL_SPIRITS) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_WRATHFUL_SPIRITS])
			ExitLoop
		Else
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
		EndIf
	WEnd
	If Not IsPlayerOrPartyAlive() Then
		Info('Quest Failed: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_WRATHFUL_SPIRITS])
		Return $FAIL
	EndIf
	TakeQuestReward($Reaper, $ID_QUEST_WRATHFUL_SPIRITS, 0x806E07)
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
	TeleportBackToLabyrinthQuestComplete($Reaper)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc

Func ClearTheFrozenWastes()
	Local $optionsFrozenWastes = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsFrozenWastes.Item('fightRange') = $RANGE_EARSHOT
	$optionsFrozenWastes.Item('flagHeroesOnFight') = True
	$optionsFrozenWastes.Item('doNotLoot') = False
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
	MoveAggroAndKill(7722, 16315, '', $optionsFrozenWastes)
	MoveAggroAndKill(8881, 17134, '', $optionsFrozenWastes)
	MoveAggroAndKill(9142, 16760, '', $optionsFrozenWastes)
	Info('Killing Smite mob 2')
	MoveAggroAndKill(10193, 15872, '', $optionsFrozenWastes)
	MoveAggroAndKill(11159, 15195, '', $optionsFrozenWastes)
	MoveAggroAndKill(12473, 15153, '', $optionsFrozenWastes)
	Info('Killing Smite mob 3')
	MoveAggroAndKill(13973, 17130, '', $optionsFrozenWastes)
	MoveAggroAndKill(13920, 19641, '', $optionsFrozenWastes)
	MoveAggroAndKill(12576, 20212, '', $optionsFrozenWastes)
	MoveAggroAndKill(11829, 20188, '', $optionsFrozenWastes)
	MoveAggroAndKill(11829, 20188, '', $optionsFrozenWastes)
	Info('Killing Smite mob 4')
	MoveAggroAndKill(11125, 20565, '', $optionsFrozenWastes)
	MoveAggroAndKill(9660, 21593, '', $optionsFrozenWastes)
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

Func ServantsOfGrenth($Reaper)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_SERVANTSOFGRENTH Then
		Info('Skipping ''Servants of Grenth'' Quest as per settings')
		TeleportBackToLabyrinthQuestSkip($Reaper)
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsFrozenWastes = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsFrozenWastes.Item('fightRange') = $RANGE_EARSHOT * 1.5
	$optionsFrozenWastes.Item('flagHeroesOnFight') = False
	$optionsFrozenWastes.Item('doNotLoot') = True
	Info('Setting heroes up for quest')
	CommandHero(1, 2010, 19451)
	CommandHero(2, 2426, 19814)
	CommandHero(3, 2737, 19452)
	CommandHero(4, 2536, 19257)
	CommandHero(5, 2163, 19257)
	CommandHero(6, 2362, 19090)
	CommandHero(7, 2373, 19447)
	RandomSleep(16000)
	TakeQuest($Reaper, $ID_QUEST_SERVANTS_OF_GRENTH, 0x806601, 0x806603)
	RandomSleep(1000)
	MoveTo(2200, 19668)
	MoveAggroAndKill(2200, 19668, '', $optionsFrozenWastes)
	Info('Killing waves of Dryders and Skeletons')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_SERVANTS_OF_GRENTH) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_SERVANTS_OF_GRENTH])
			ExitLoop
		Else
			MoveAggroAndKill(2807, 19907, '', $optionsFrozenWastes)
			RandomSleep(250)
			MoveAggroAndKill(2200, 19668, '', $optionsFrozenWastes)
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
	TakeQuestReward($Reaper, $ID_QUEST_SERVANTS_OF_GRENTH, 0x806607)
	TeleportBackToLabyrinthQuestComplete($Reaper)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc

Func ClearTheChaosPlanes()
	Local $optionsChaosPlanes = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsChaosPlanes.Item('fightRange') = $RANGE_EARSHOT * 1.5
	$optionsChaosPlanes.Item('flagHeroesOnFight') = False
	$optionsChaosPlanes.Item('doNotLoot') = False
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
	MoveAggroAndKill(-3447, 4719)
	MoveAggroAndKill(-4559, 4954)
	MoveAggroAndKill(-5223, 4703)
	MoveAggroAndKill(-6031, 3642)
	MoveAggroAndKill(-6098, 2699)
	MoveAggroAndKill(-5639, 1794)
	MoveAggroAndKill(-6147, 745)
	MoveAggroAndKill(-5639, 1794)
	MoveAggroAndKill(-6098, 2699)
	MoveAggroAndKill(-6031, 3642)
	MoveAggroAndKill(-5223, 4703)
	MoveAggroAndKill(-4559, 4954)
	MoveAggroAndKill(-3447, 4719)
	MoveAggroAndKill(-3063, 4219)
	MoveAggroAndKill(-3432, 945)
	MoveAggroAndKill(-2711, -90)
	MoveAggroAndKill(-663, -535)
	Info('Moving to worms')
	MoveAggroAndKillSafeTraps(412, 1324)
	Info('Clear Traps for Heroes')
	CommandAll(412, 1324)
	MoveTo(1358, 2087)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(1835, 2562)
	MoveAggroAndKillSafeTraps(2522, 2801)
	Info('Clear Traps for Heroes')
	CommandAll(2522, 2801)
	MoveTo(3640, 2353)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(3640, 2353)
	Info('Killing Worm Mob 1')
	MoveAggroAndKillSafeTraps(3295, 1343)
	MoveAggroAndKillSafeTraps(4075, 1205)
	MoveAggroAndKillSafeTraps(4792, 1990)
	Info('Killing Worm Mob 2')
	MoveAggroAndKillSafeTraps(4840, 1220)
	Info('Clear Traps for Heroes')
	CommandAll(4840, 1220)
	MoveTo(4808, 550)
	RandomSleep(5000)
	CancelAll()
	Info('Killing Worm Mob 3')
	MoveAggroAndKillSafeTraps(5643, 618)
	MoveAggroAndKillSafeTraps(6585, 1508)
	Info('kill charged blackness')
	MoveAggroAndKillSafeTraps(7277, 2079)
	MoveAggroAndKillSafeTraps(7919, 578)
	Info('Clear Traps for Heroes')
	CommandAll(7919, 578)
	MoveTo(8021, -275)
	RandomSleep(5000)
	CancelAll()
	Info('Killing Worm Mob 4')
	MoveAggroAndKillSafeTraps(8477, -626)
	MoveAggroAndKillSafeTraps(8706, -1135)
	; popup
	MoveAggroAndKillSafeTraps(8456, -1396)
	MoveAggroAndKillSafeTraps(8210, -2189)
	MoveAggroAndKillSafeTraps(8114, -3608)
	MoveAggroAndKillSafeTraps(7934, -4267)
	MoveAggroAndKillSafeTraps(8781, -4834)
	MoveAggroAndKillSafeTraps(8186, -6531)
	MoveAggroAndKillSafeTraps(8040, -7296)
	; kill mobs
	MoveAggroAndKillSafeTraps(7966, -7743)
	MoveAggroAndKillSafeTraps(8484, -8004)
	; kill mobs
	Info('Clear Traps for Heroes')
	CommandAll(7798, -7798)
	MoveTo(8873, -8096)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKill(9747, -8488)
	MoveAggroAndKill(9621, -9465)
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
	MoveAggroAndKill(12852, -9597)
	MoveAggroAndKill(13227, -9181)
	Info('Killing...')
	MoveAggroAndKill(13192, -9027)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(13102, -9902)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(12702, -9263)
	MoveAggroAndKill(11573, -8295)
	MoveAggroAndKill(11150, -8305)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(11850, -8248)
	MoveAggroAndKill(13077, -7583)
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
	Info('Moving to spot 5')
	MoveAggroAndKill(7322, -12220)
	MoveAggroAndKill(6825, -13247)
	MoveAggroAndKill(7392, -14467)
	MoveAggroAndKill(6896, -15201)
	MoveAggroAndKill(5986, -14869)
	Info('Killing Skeletons Mob')
	MoveAggroAndKill(6971, -16245)
	MoveAggroAndKill(6519, -17280)
	MoveAggroAndKill(5980, -17888)
	Info('Moving to spot 6')
	MoveAggroAndKill(4806, -17454)
	MoveAggroAndKill(5980, -17888)
	MoveAggroAndKill(3839, -18881)
	MoveAggroAndKill(3074, -19617)
	Info('Moving to spot 7')
	MoveAggroAndKill(2421, -17792)
	MoveAggroAndKill(2268, -15530)
	MoveAggroAndKill(2168, -14641)
	Info('Moving to spot 8')
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
	Info('Moving to Monument to clear Terrorweb Dryders')
	MoveAggroAndKill(10373, -18882)
	MoveAggroAndKill(10662, -18028)
	RandomSleep(10000)
	Info('Kill Mindblade Spawns')
	$optionsChaosPlanes.Item('doNotLoot') = True
	MoveAggroAndKill(10373, -18882, '', $optionsChaosPlanes)
	RandomSleep(10000)
	MoveAggroAndKill(11440, -17168, '', $optionsChaosPlanes)
	MoveAggroAndKill(12564, -17553, '', $optionsChaosPlanes)
	Info('Moving to Reaper to protect')
	MoveAggroAndKill(11306, -17893, '', $optionsChaosPlanes)
	RandomSleep(5000)
	Info('Kill Dream Final Rider')
	MoveAggroAndKill(12564, -17553, '', $optionsChaosPlanes)
	RandomSleep(5000)
	MoveAggroAndKill(13766, -16605, '', $optionsChaosPlanes)
	Info('Moving to Reaper to protect')
	MoveAggroAndKill(12564, -17553, '', $optionsChaosPlanes) ; issue spot
	MoveAggroAndKill(11306, -17893, '', $optionsChaosPlanes)
	RandomSleep(10000)
	Info('Kill Mindblade Spawns')
	MoveAggroAndKill(12564, -17553, '', $optionsChaosPlanes)
	MoveAggroAndKill(13766, -16605, '', $optionsChaosPlanes)
	Info('Moving to Reaper to protect')
	MoveAggroAndKill(12564, -17553, '', $optionsChaosPlanes)
	MoveAggroAndKill(11306, -17893, '', $optionsChaosPlanes)
	RandomSleep(5000)
	Info('Kill Mindblade Spawns')
	MoveAggroAndKill(10373, -18882, '', $optionsChaosPlanes)
	RandomSleep(5000)
	Info('Moving to Reaper to protect')
	MoveAggroAndKill(11306, -17893, '', $optionsChaosPlanes)
	Info('Waiting 30s as final safety measure')
	RandomSleep(30000)
	Info('Picking up Loot')
	MoveAggroAndKill(12564, -17553)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(11306, -17893)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(10373, -18882)
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveAggroAndKill(11306, -17893)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc


Func TheFourHorsemen($Reaper)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_THEFOURHORSEMEN Then
		Info('Skipping ''The Four Horsemen'' Quest as per settings')
		TeleportBackToLabyrinthQuestSkip($Reaper)
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	;Local $optionsChaosPlanes = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	;$optionsChaosPlanes.Item('fightRange') = $RANGE_EARSHOT * 1.5
	;$optionsChaosPlanes.Item('flagHeroesOnFight') = False
	;$optionsChaosPlanes.Item('doNotLoot') = False
	;GoToNPC($Reaper)
	;RandomSleep(1000)
	;Dialog(0x7F) ; The Four Horsemen = 0x806A03
	;RandomSleep(1000)
	;Info('Taking ''The Four Horsemen'' Quest')
	;Dialog(0x86) ; Accept The Four Horsemen Quest = 0x806A01
	;RandomSleep(1000)
	;Dialog(0x8D) ; Remove when quest is implemented
	;RandomSleep(1000) ; Remove when quest is implemented
	;TeleportBackToLabyrinthQuestComplete($Reaper)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc

Func ClearSpawningPools($Reaper)
	Local $optionsSpawningPools = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsSpawningPools.Item('fightRange') = $RANGE_EARSHOT
	$optionsSpawningPools.Item('flagHeroesOnFight') = True
	$optionsSpawningPools.Item('doNotLoot') = False
	TeleportBackToChaosPlains($Reaper)
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
	$optionsSpawningPools.Item('doNotLoot') = True
	MoveAggroAndKill(-8466, -19867, '', $optionsSpawningPools)
	Info('Move to protect Reaper')
	MoveAggroAndKill(-7102, -19484, '', $optionsSpawningPools)
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

Func TerrorwebQueen($Reaper)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_TERRORWEBQUEEN Then
		Info('Skipping ''Terrorweb Queen'' Quest as per settings')
		TeleportBackToLabyrinthQuestSkip($Reaper)
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsSpawningPools = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsSpawningPools.Item('fightRange') = $RANGE_EARSHOT
	$optionsSpawningPools.Item('flagHeroesOnFight') = True
	$optionsSpawningPools.Item('doNotLoot') = False
	TakeQuest($Reaper, $ID_QUEST_TERRORWEB_QUEEN, 0x806B01, 0x806B03)
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
	TakeQuestReward($Reaper, $ID_QUEST_TERRORWEB_QUEEN, 0x806B07)
	TeleportBackToLabyrinthQuestComplete($Reaper)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc

Func ClearBonePits($Reaper)
	Local $optionsBonePits = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsBonePits.Item('fightRange') = $RANGE_EARSHOT * 1.25
	$optionsBonePits.Item('flagHeroesOnFight') = False
	$optionsBonePits.Item('doNotLoot') = False
	TeleportBackToChaosPlains($Reaper)
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
	MoveAggroAndKill(10331, -63)
	MoveAggroAndKill(11141, 87)
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

Func ImprisonedSpirits($Reaper)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_IMPRISONEDSPIRITS Then
		Info('Skipping ''Imprisoned Spirits'' Quest as per settings')
		TeleportBackToLabyrinthQuestSkip($Reaper)
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsBonePits = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsBonePits.Item('fightRange') = $RANGE_EARSHOT
	$optionsBonePits.Item('flagHeroesOnFight') = False
	$optionsBonePits.Item('doNotLoot') = True
	Info('Setting heroes up for quest')
	CommandHero(1, 12182, 3976)
	CommandHero(2, 12183, 3656)
	CommandHero(3, 12519, 3393)
	CommandHero(4, 12876, 4124)
	CommandHero(5, 12537, 4009)
	CommandHero(6, 12787, 3645)  
	CommandHero(7, 12526, 4567)
	RandomSleep(30000)
	TakeQuest($Reaper, $ID_QUEST_IMPRISONED_SPIRITS, 0x806901, 0x806903)
	MoveTo(12714, 4288)
	MoveAggroAndKill(12832, 4436, '', $optionsBonePits)
	Info('Killing waves of Dryders and Skeletons')
	While IsPlayerOrPartyAlive()
		If IsQuestReward($ID_QUEST_IMPRISONED_SPIRITS) Then
			Info('Quest Successful: ' & $QUEST_NAMES_FROM_IDS[$ID_QUEST_IMPRISONED_SPIRITS])
			ExitLoop
		Else
			MoveAggroAndKill(12711, 3339, '', $optionsBonePits)
			RandomSleep(250)
			MoveAggroAndKill(12579, 2997, '', $optionsBonePits)
			RandomSleep(250)
			MoveAggroAndKill(12832, 3339, '', $optionsBonePits)
			RandomSleep(250)
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
	TakeQuestReward($Reaper, $ID_QUEST_IMPRISONED_SPIRITS, 0x806907)
	TeleportBackToLabyrinthQuestComplete($Reaper)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc

Func ClearTwinSerpentMountains()
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_DEMONASSASSIN Then
		Info('Skipping ''Twin Serpent Mounts'' Area as per settings')
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsTwinSerpentMountains = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsTwinSerpentMountains.Item('fightRange') = $RANGE_EARSHOT * 0.9
	$optionsTwinSerpentMountains.Item('flagHeroesOnFight') = False
	$optionsTwinSerpentMountains.Item('doNotLoot') = False
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
	MoveAggroAndKill(123, 3678)
	MoveAggroAndKill(412, 1324)
	MoveAggroAndKill(1835, 2562)
	MoveAggroAndKill(2522, 2801)
	MoveAggroAndKill(3640, 2353)
	MoveAggroAndKill(3295, 1343)
	MoveAggroAndKill(4075, 1205)
	MoveAggroAndKill(4792, 1990)
	MoveAggroAndKill(4840, 1220)
	MoveAggroAndKill(5643, 618)
	MoveAggroAndKill(6585, 1508)
	MoveAggroAndKill(7277, 2079)
	MoveAggroAndKill(7919, 578)
	MoveAggroAndKill(8477, -626)
	MoveAggroAndKill(8706, -1135)
	; alternate path here
	MoveAggroAndKill(8456, -1396)
	MoveAggroAndKill(8210, -2189)
	MoveAggroAndKill(8114, -3608)
	MoveAggroAndKill(7934, -4267)
	MoveAggroAndKill(8781, -4834)
	MoveAggroAndKill(8186, -6531)
	MoveAggroAndKillSafeTraps(8040, -7296)
	Info('Moving to Spot 1')
	MoveAggroAndKillSafeTraps(6213, -7740)
	MoveAggroAndKillSafeTraps(8040, -7296)
	MoveAggroAndKillSafeTraps(5119, -7900)
	Info('Clear Traps for Heroes')
	CommandAll(5119, -7900)
	MoveTo(4200, -7937)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(3473, -7719)
	Info('Clear Traps for Heroes')
	CommandAll(3473, -7719)
	MoveTo(2724, -7823)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Spot 2')
	MoveAggroAndKillSafeTraps(2512, -10559)
	MoveAggroAndKillSafeTraps(1313, -9579)
	Info('Clear Traps for Heroes')
	CommandAll(1313, -9579)
	MoveTo(787, -9145)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(201, -9372)
	Info('Clear Traps for Heroes')
	CommandAll(201, -9372)
	MoveTo(-962, -8786)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Spot 3')
	MoveAggroAndKillSafeTraps(-2691, -8649)
	MoveAggroAndKillSafeTraps(-2879, -8338)
	MoveAggroAndKillSafeTraps(-2369, -7705)
	Info('Moving to Spot 4')
	MoveAggroAndKillSafeTraps(-3250, -6733)
	MoveAggroAndKillSafeTraps(-4298, -5503)
	Info('Moving to Spot 5')
	MoveAggroAndKillSafeTraps(-3901, -5809)
	MoveAggroAndKillSafeTraps(-4530, -5823)
	MoveAggroAndKillSafeTraps(-3901, -5809)
	MoveAggroAndKillSafeTraps(-4281, -5058)
	Info('Clear Traps for Heroes') 
	CommandAll(-4281, -5058)
	MoveTo(-5032, -4363) 
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Spot 6')
	MoveAggroAndKillSafeTraps(-5334, -4614)
	Info('Clear Traps for Heroes')
	CommandAll(-5334, -4614)
	MoveTo(-5866, -4621)
	RandomSleep(5000)
	CancelAll()
	MoveAggroAndKillSafeTraps(-6421, -6062)
	MoveAggroAndKillSafeTraps(-7086, -6240)
	Info('Clear Traps for Heroes')
	CommandAll(-7086, -6240)
	MoveTo(-7418, -5871)
	RandomSleep(5000)
	CancelAll()
	Info('Moving to Monument to clear Terrorweb Dryders')
	MoveAggroAndKillSafeTraps(-7418, -5871)
	MoveAggroAndKillSafeTraps(-7319, -5329)
	MoveAggroAndKillSafeTraps(-7307, -4677)
	MoveAggroAndKillSafeTraps(-7941, -4463)
	MoveAggroAndKillSafeTraps(-8164, -4860)
	MoveAggroAndKillSafeTraps(-7941, -4463)
	MoveAggroAndKillSafeTraps(-7401, -4192)
	MoveAggroAndKillSafeTraps(-7941, -4463)
	MoveAggroAndKillSafeTraps(-8220, -5202)
	
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc


Func DemonAssassin($Reaper)
	If Not $ATTEMPT_REAPER_QUESTS Or Not $ENABLE_DEMONASSASSIN Then
		Info('Skipping ''Demon Assassin'' Quest as per settings')
		TeleportBackToLabyrinthQuestSkip($Reaper)
		Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
	EndIf
	Local $optionsTwinSerpentMountains = CloneDictMap($UNDERWORLD_FIGHT_OPTIONS)
	$optionsTwinSerpentMountains.Item('fightRange') = $RANGE_EARSHOT * 1.5
	$optionsTwinSerpentMountains.Item('flagHeroesOnFight') = False
	$optionsTwinSerpentMountains.Item('doNotLoot') = True
	Info('Setting heroes up for quest')
	CommandHero(1, -4629, -5282)
	CommandHero(2, -4928, -5373)
	CommandHero(3, -4731, -5816)
	CommandHero(4, -4792, -6052)
	CommandHero(5, -4898, -5730)
	CommandHero(6, -5288, -5621)  
	CommandHero(7, -5165, -6047)
	RandomSleep(16000)
	TakeQuest($Reaper, $ID_QUEST_DEMON_ASSASSIN, 0x806801, 0x806803)
	MoveTo(-4742, -5531)
	Info('Killing the Slayer')
	For $i = 1 To 6
		MoveAggroAndKill(-4629, -5282, '', $optionsTwinSerpentMountains)
		RandomSleep(250)
		MoveAggroAndKill(-4745, -5535, '', $optionsTwinSerpentMountains)
		If $i < 6 Then RandomSleep(5000)
	Next
	Info('Waiting for the waves of Dryders')
	RandomSleep(45000)
	Info('Killing Dryders')
	For $i = 1 To 8
		MoveAggroAndKill(-4629, -5282, '', $optionsTwinSerpentMountains)
		RandomSleep(250)
		MoveAggroAndKill(-4748, -5538, '', $optionsTwinSerpentMountains)
		If $i < 8 Then RandomSleep(5000)
	Next
	Info('Picking up Loot')
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT * 1.5)
	MoveTo(-4742, -5531)
	CancelAllHeroes()
	RandomSleep(250)
	Info('Parking Heroes out of loot range for chest.')
	CommandAll(-2141, -7958)
	MoveTo(8220, 5202)
	MoveTo(8305, 5515)
	; Loot Chest
	Sleep(1000)
	Info('Looting chest')
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	CancelAll()
	TakeQuestReward($Reaper, $ID_QUEST_DEMON_ASSASSIN, 0x806807)
	TeleportBackToLabyrinthQuestComplete($Reaper)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL

EndFunc
