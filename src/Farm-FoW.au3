; Author: Kronos ?
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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $FoWFarmerSkillbar = ''
Global Const $FoWFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'XXmn average in NM' & @CRLF _
	& 'YYmn  average in HM with consets (automatically used if HM is on)'

Global $FOW_FARM_SETUP = False
Global $FoWDeathsCount = 0
Global Const $ID_FoW_Quest = 0x000
Global Const $ID_Quest_WailingLord = 0xCC

Global Const $Shard_Wolf_PlayerNumber = 2835

Global Const $ID_FoW_Unholy_Texts = 2619
Global $aggroRange = $RANGE_SPELLCAST + 500


;~ Main method to farm FoW
Func FoWFarm($STATUS)
	If Not $FOW_FARM_SETUP Then
		SetupFoWFarm()
		$FOW_FARM_SETUP = True
	EndIf

	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Temple_of_the_Ages Then DistrictTravel($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	Info('Making way to Balthazar statue')
	MoveTo(-2500, 18700)
	SendChat('/kneel', '')
	RndSleep(3000)
	GoToNPC(GetNearestNPCToCoords(-2500, 18700))
	RndSleep(250)
	Dialog(0x85)
	RndSleep(500)
	Dialog(0x86)
	RndSleep(500)
	WaitMapLoading($ID_Fissure_of_Woe)

	If $STATUS <> 'RUNNING' Then Return 2

	Return FoWFarmLoop()
EndFunc


;~ FoW farm setup
Func SetupFoWFarm()
	Info('Setting up farm')
	; Make group
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func FoWFarmLoop()
	AdlibRegister('FoWGroupIsAlive', 10000)
	$FoWDeathsCount = 0
	If IsHardmodeEnabled() Then UseConset()

	If TowerOfCourage() Then Return 1
	If TheGreatBattleField() Then Return 1
	If TheTempleOfWar() Then Return 1
	If TheSpiderCave_and_FissureShore() Then Return 1
	If LakeOfFire() Then Return 1
	If TowerOfStrengh() Then Return 1
	If BurningForest() Then Return 1
	If ForestOfTheWailingLord() Then Return 1
	If GriffonRun() Then Return 1
	If TempleLoot() Then Return 1


	TowerOfCourage()
	Info('Tower of Courage cleared')
	TheGreatBattleField()
	Info('Temple quest retrieved')
	TheSpiderCave_and_FissureShore()
	Info('Temple Restored')
	LakeOfFire()
	Info('Lake of Fire cleared')
	TowerOfStrengh()
	Info('Tower of Strengh cleared')
	BurningForest()
	Info('Burning Forest cleared')
	ForestOfTheWailingLord()
	Info('Forest of Wailing Lords cleared')
	GriffonRun()
	Info('Done, GG')
	TempleLoot()
	Info('Looted, gratz on the obby edge')

	AdlibUnRegister('FoWGroupIsAlive')
	Return 0
EndFunc


Func TowerOfCourage()
	Info('Pre-clearing area to make Rastigan safe')
	SafeMoveAggroAndKill(-21261, 1060, '1', $aggroRange)
	SafeMoveAggroAndKill(-19266, 1118, '2', $aggroRange)
	SafeMoveAggroAndKill(-21085, 1792, '3', $aggroRange)
	SafeMoveAggroAndKill(-21713, -2885, '4', $aggroRange)
	SafeMoveAggroAndKill(-22075, -5615, '5', $aggroRange)
	SafeMoveAggroAndKill(-19324, -5789, '6', $aggroRange)
	SafeMoveAggroAndKill(-18812, -3996, '7', $aggroRange)
	SafeMoveAggroAndKill(-16318, -4998, '8', $aggroRange)
	RndSleep(20000)

	Info('Rastigan should start moving around now, clearing tower ahead')
	SafeMoveAggroAndKill(-17847, -3248, '1', $aggroRange)
	SafeMoveAggroAndKill(-14401, -3309, '2', $aggroRange) 
	SafeMoveAggroAndKill(-13577, -939, '3', $aggroRange)
	SafeMoveAggroAndKill(-16031, 203, '4', $aggroRange)
	SafeMoveAggroAndKill(-13577, -939, '5', $aggroRange)
	SafeMoveAggroAndKill(-14424, -2690, '6', $aggroRange)
	RndSleep(15000)
	SafeMoveAggroAndKill(-14680, -2472, '10', $aggroRange)

	Info('Getting Shadow Army quest and reward')
	MoveTo(-15706, -1730)
	GoToNPC(GetNearestNPCToCoords(-15764, -1691))
	RndSleep(500)
	Dialog(0x80D401)
	RndSleep(500)
	GoToNPC(GetNearestNPCToCoords(-15764, -1691))
	RndSleep(500)
	Dialog(0x80D407)
	RndSleep(500)	
	
	Info('Getting The Wailing Lord quest and reward')
	GoToNPC(GetNearestNPCToCoords(-15764, -1691))
	RndSleep(500)
	Dialog(0x80CC01)
	RndSleep(500)
EndFunc

Func TheGreatBattleField()
	Info('Heading to forgeman')
	SafeMoveAggroAndKill(-9490, -5948, '1', $aggroRange)
	SafeMoveAggroAndKill(-6303, 1666, '2', $aggroRange)
	SafeMoveAggroAndKill(-4710, 2890, '3', $aggroRange)
	Sleep(1000)
	SafeMoveAggroAndKill(-5003, 10033, '4', $aggroRange)
	SafeMoveAggroAndKill(-6961, 11398, '5', $aggroRange)

	Info('Getting the Army of Darkness quest')
	MoveTo(-7326, 11892)
	GoToNPC(GetNearestNPCToCoords(-7382, 11942))
	RndSleep(500)
	Dialog(0x80CB01)
	RndSleep(500)
	
	Info('Getting Unholy Texts')
	SafeMoveAggroAndKill(-1804, 14416, '1', $aggroRange)
	SafeMoveAggroAndKill(1463, 16582, '2', $aggroRange)
	SafeMoveAggroAndKill(2805, 15873, '3', $aggroRange)
	SafeMoveAggroAndKill(2378, 14647, '4', $aggroRange)

	PickUpUnholyTexts()
	MoveTo(2122, 16524)
	SafeMoveAggroAndKill(-3678, 13423, '5', $aggroRange)
	SafeMoveAggroAndKill(-6737, 11223, '6', $aggroRange)

	MoveTo(-7326, 11892)
	GoToNPC(GetNearestNPCToCoords(-7382, 11942))
	RndSleep(500)
	Dialog(0x80CB07)
	RndSleep(500)
	
	Info('Getting the Eternal Forgemaster quest')
	MoveTo(-7378, 11674)
	GoToNPC(GetNearestNPCToCoords(-7450, 11706))
	RndSleep(500)
	Dialog(0x80D101)
	RndSleep(500)	

	Info('Heading to Forge')
	SafeMoveAggroAndKill(-4401, 10872, '1', $aggroRange)
	SafeMoveAggroAndKill(684, 7574, '2', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(2765, 7854, '3', $aggroRange)
	SafeMoveAggroAndKill(684, 7574, '4', $aggroRange)
	SafeMoveAggroAndKill(1402, 6146, '5', $aggroRange)

EndFunc

Func TheTempleOfWar()
	Info('Clearing area')
	SafeMoveAggroAndKill(1762, 2116, '1', $aggroRange)
	SafeMoveAggroAndKill(4272, 820, '2', $aggroRange)
	SafeMoveAggroAndKill(3984, -1359, '3', $aggroRange)
	SafeMoveAggroAndKill(2448, -2735, '4', $aggroRange)
	SafeMoveAggroAndKill(1012, -2624, '5', $aggroRange)
	SafeMoveAggroAndKill(-610, -1548, '6', $aggroRange)
	SafeMoveAggroAndKill(-425, 772, '7', $aggroRange)

	Info('Clearing center')
	MoveTo(293, 1303)
	SafeMoveAggroAndKill(1052, 524, '1', $aggroRange)
	SafeMoveAggroAndKill(2026, 258, '2', $aggroRange)
	SafeMoveAggroAndKill(2501, -338, '3', $aggroRange)

	Info('Getting the Temple of War quest reward')
	MoveTo(1845, -142)
	GoToNPC(GetNearestNPCToCoords(1840, -179))
	RndSleep(500)
	Dialog(0x80D107)
	RndSleep(500)

	Info('Getting the Defend the Temple of War quest')
	MoveTo(1845, -142)
	GoToNPC(GetNearestNPCToCoords(1840, -179))
	RndSleep(500)
	Dialog(0x80CA01)
	RndSleep(500)

	Info('Waiting it out, might optimise later')
	Sleep(480000)
	
	Info('Getting the Defend the Temple of War quest reward')
	MoveTo(1845, -142)
	GoToNPC(GetNearestNPCToCoords(1840, -179))
	RndSleep(500)
	Dialog(0x80CA07)
	RndSleep(500)	
	
	Info('Getting the Restore the Temple of War quest')
	GoToNPC(GetNearestNPCToCoords(1840, -179))
	RndSleep(500)
	Dialog(0x80CF03)
	RndSleep(500)	
	Dialog(0x80CF01)
	RndSleep(500)	

	Info('Getting the Khobay the Betrayer quest')
	GoToNPC(GetNearestNPCToCoords(1840, -179))
	RndSleep(500)
	Dialog(0x80E003)
	RndSleep(500)	
	Dialog(0x80E001)
	RndSleep(500)		

	Info('Getting the Tower of Strengh quest')
	MoveTo(199, -1910)
	GoToNPC(GetNearestNPCToCoords(156, -1960))
	RndSleep(500)
	Dialog(0x80D301)
	RndSleep(500)	
	
EndFunc

Func TheSpiderCave_and_FissureShore()
	Info('Heading to take The Hunt quest')
	SafeMoveAggroAndKill(1821, -3660, '1', $aggroRange)
	SafeMoveAggroAndKill(1770, -6908, '2', $aggroRange)
	Sleep(30000)
	SafeMoveAggroAndKill(2802, -9718, '3', $aggroRange)
	SafeMoveAggroAndKill(1846, -12060, '4', $aggroRange)
	SafeMoveAggroAndKill(1081, -13489, '5', $aggroRange)
	
	Info('Getting The Hunt quest')
	MoveTo(2946, -14801)
	GoToNPC(GetNearestNPCToCoords(3014, -14849))
	RndSleep(500)
	Dialog(0x80D001)
	RndSleep(500)	
	
	ShardWolfKill()

	Info('Clearing cave')
	SafeMoveAggroAndKill(1416, -11621, '1', $aggroRange)
	SafeMoveAggroAndKill(-929, -9422, '2', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(-2541, -8467, '3', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(-3995, -9375, '4', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(-6131, -11375, '5', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(-7792, -13385, '6', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(-8429, -15776, '7', $aggroRange)
	Sleep(20000)
	SafeMoveAggroAndKill(-8643, -17308, '5', $aggroRange)
	Sleep(60000)
	
	MoveTo(-9987, -18496)
	MoveTo(-12877, -18004)

	ShardWolfKill()
	
	Info('Going back')
	SafeMoveAggroAndKill(-8788, -18225, '1', $aggroRange)
	SafeMoveAggroAndKill(-8542, -16188, '2', $aggroRange)
	
	MoveTo(-6721, -11747)
	MoveTo(-1592, -8775)
	MoveTo(974, -11166)

EndFunc

Func LakeOfFire()
	Info('Khobay murder time')
	SafeMoveAggroAndKill(4499, -9790, '1', $aggroRange)
	SafeMoveAggroAndKill(7346, -11267, '2', $aggroRange)
	SafeMoveAggroAndKill(9631, -8525, '3', $aggroRange)
	SafeMoveAggroAndKill(20447, -8116, '4', $aggroRange)
	SafeMoveAggroAndKill(20716, -12441, '5', $aggroRange)
	SafeMoveAggroAndKill(18274, -14007, '6', $aggroRange)
	;SafeMoveAggroAndKill(19595, -15322, '7', $aggroRange)

EndFunc

Func TowerOfStrengh()
	Info('Clearing area of Tower of Strengh')
	MoveTo(18274, -14007)
	MoveTo(20716, -12441)
	SafeMoveAggroAndKill(20447, -8116, '1', $aggroRange)
	SafeMoveAggroAndKill(9631, -8525, '2', $aggroRange)
	SafeMoveAggroAndKill(11516, -4620, '3', $aggroRange)
	SafeMoveAggroAndKill(15023, -3120, '4', $aggroRange)
	SafeMoveAggroAndKill(15777, -319, '5', $aggroRange)
	
	Info('Going to trigger pnj')
	SafeMoveAggroAndKill(15341, -1369, '1', $aggroRange)
	SafeMoveAggroAndKill(10307, -5857, '2', $aggroRange)
	SafeMoveAggroAndKill(6451, -11191, '3', $aggroRange)
	SafeMoveAggroAndKill(1627, -7176, '4', $aggroRange)
	
	Info('And back to tower')
	SafeMoveAggroAndKill(6451, -11191, '1', $aggroRange)
	SafeMoveAggroAndKill(10307, -5857, '2', $aggroRange)
	SafeMoveAggroAndKill(15341, -1369, '3', $aggroRange)
	SafeMoveAggroAndKill(16754, -1744, '4', $aggroRange)

EndFunc

Func BurningForest()
	Info('Heading to Burning Forest')
	SafeMoveAggroAndKill(15188, -1088, '1', $aggroRange)
	SafeMoveAggroAndKill(17412, 3322, '2', $aggroRange)
	SafeMoveAggroAndKill(14111, 3991, '3', $aggroRange)
	SafeMoveAggroAndKill(12105, 6748, '4', $aggroRange)
	
	Info('Getting the Slaveds of Menzies quest')
	MoveTo(12061, 6577)
	GoToNPC(GetNearestNPCToCoords(12041, 6507))
	RndSleep(500)
	Dialog(0x80CE01)
	RndSleep(500)		
	
	Info('clearing Burning Forest')
	SafeMoveAggroAndKill(14890, 9187, '1', $aggroRange)
	SafeMoveAggroAndKill(20298, 9375, '2', $aggroRange)
	SafeMoveAggroAndKill(20351, 11949, '3', $aggroRange)
	SafeMoveAggroAndKill(20357, 13569, '4', $aggroRange)
	SafeMoveAggroAndKill(22155, 14014, '5', $aggroRange)

	ShardWolfKill()

	SafeMoveAggroAndKill(22366, 16131, '6', $aggroRange)
	SafeMoveAggroAndKill(20706, 15827, '7', $aggroRange)
	SafeMoveAggroAndKill(15998, 9247, '8', $aggroRange)

	Info('Heading to Forest of the Wailing Lords')
	SafeMoveAggroAndKill(9197, 12506, '1', $aggroRange)
	SafeMoveAggroAndKill(1652, 12339, '2', $aggroRange)

	ShardWolfKill()

	SafeMoveAggroAndKill(-10714, 6290, '3', $aggroRange)
	
EndFunc

Func ForestOfTheWailingLord()
	Info('Clearing forest')
	SafeMoveAggroAndKill(-17449, 9757, '1', $aggroRange)
	SafeMoveAggroAndKill(-20200, 9524, '2', $aggroRange)
	SafeMoveAggroAndKill(-20744, 12161, '3', $aggroRange)
	SafeMoveAggroAndKill(-18192, 15066, '4', $aggroRange)
	SafeMoveAggroAndKill(-15860, 13097, '5', $aggroRange)

	ShardWolfKill()

	SafeMoveAggroAndKill(-20185, 13965, '6', $aggroRange)
	
	Info('Safely pulling')
	CommandHero(1, -20167, 13585)
	CommandHero(2, -19882, 14020)
	CommandHero(3, -20384, 13480)
	CommandHero(4, -19863, 14269)
	CommandHero(5, -20018, 13797)
	CommandHero(6, -19759, 13784)
	CommandHero(7, -19923, 13580)
	
	Local $questState = 1
	While $questState <> 3
		MoveTo(-21068, 14640)
		MoveTo(-20488, 14182)

		$questState = DllStructGetData(GetQuestByID($ID_Quest_WailingLord), 'LogState')
		Sleep(30000)
	WEnd
	
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
	CancelHero(4)
	CancelHero(5)
	CancelHero(6)
	CancelHero(7)

	Info('Getting The Griffon quest')
	MoveTo(-21567, 15010)
	GoToNPC(GetNearestNPCToCoords(-21628, 15056))
	RndSleep(500)
	Dialog(0x80CD01)
	RndSleep(500)	

EndFunc

Func GriffonRun()
	Info('Preclearing area')
	SafeMoveAggroAndKill(-16904, 9813, '1', $aggroRange)
	SafeMoveAggroAndKill(-7357, 5041, '2', $aggroRange)
	SafeMoveAggroAndKill(-6761, -4260, '3', $aggroRange)
	SafeMoveAggroAndKill(-9634, -5868, '4', $aggroRange)
	SafeMoveAggroAndKill(-13824, -2768, '5', $aggroRange)
	SafeMoveAggroAndKill(-17876, -3615, '6', $aggroRange)

	ShardWolfKill()
	
	Info('Going to grab them')
	SafeMoveAggroAndKill(-13824, -2768, '1', $aggroRange)
	SafeMoveAggroAndKill(-9634, -5868, '2', $aggroRange)
	SafeMoveAggroAndKill(-6761, -4260, '3', $aggroRange)
	SafeMoveAggroAndKill(-7357, 5041, '4', $aggroRange)
	SafeMoveAggroAndKill(-18205, 9378, '5', $aggroRange)
	
	MoveTo(-22136, 10208)
	MoveTo(-7357, 5041)
	MoveTo(-6761, -4260)
	MoveTo(-9634, -5868)
	MoveTo(-15951, -1902)

EndFunc

Func TempleLoot()
	MoveTo(-6957, -5548)
	MoveTo(-6410, 2020)
	MoveTo(1584, 7083)
	MoveTo(1695, 2168)
	MoveTo(259, 1286)
	MoveTo(1551, 63)
	
	Info('Opening chest')
	MoveTo(1833, 371)
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()
	;doubled to secure looting
	MoveTo(1833, 371)
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()	
	
EndFunc


;~ Did run fail ?
Func FoWIsFailure()
	If ($FoWDeathsCount > 5) Then
		AdlibUnregister('FoWGroupIsAlive')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the groupIsAlive variable, this function is run on a fixed timer
Func FoWGroupIsAlive()
	$FoWDeathsCount += IsGroupAlive() ? 0 : 1
EndFunc



;~ Function present only to store useful tidbits to use in other places
Func UselessFunction()
	; TIDBIT get a quest
	Info('Get quest')
	MoveTo(, )
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x0)
	RndSleep(500)
	; Quest validation doubled to secure bot
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x0)
	RndSleep(500)



	; TIDBIT move and kill stuff
	While $FoWDeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 6078, 4483, 1250)
		UseMoraleConsumableIfNeeded()
		SafeMoveAggroAndKill(17619, 2687, 'Moving near duo', $aggroRange)
		SafeMoveAggroAndKill(18168, 4788, 'Killing one from duo', $aggroRange)
		SafeMoveAggroAndKill(18880, 7749, 'Triggering beacon 1', $aggroRange)
		SafeMoveAggroAndKill(13080, 7822, 'Moving towards nettles cave', $aggroRange)
		SafeMoveAggroAndKill(9946, 6963, 'Nettles cave', $aggroRange)
		SafeMoveAggroAndKill(6078, 4483, 'Nettles cave exit group', $aggroRange)
	WEnd



	; TIDBIT interact with items on the floor
	RndSleep(500)
	PickUpItems()
	Info('Open dungeon door')
	ClearTarget()
	Sleep(GetPing() + 500)
	Moveto(17888, -6243)
	ActionInteract()
	Sleep(GetPing() + 500)



	; TIDBIT waiting on a quest to terminate
	Local $questState = 1
	While $FoWDeathsCount < 6 And $questState <> 3
		$questState = DllStructGetData(GetQuestByID($ID_FoW_Quest), 'LogState')
		Sleep(1000)
	WEnd
	If FoWIsFailure() Then Return 1
EndFunc

;~ Pick up the Unholy Texts
Func PickUpUnholyTexts()
	Local $agent
	Local $item
	Local $deadlock
	For $i = 1 To GetMaxAgents()
		$agent = GetAgentByID($i)
		If (DllStructGetData($agent, 'Type') <> 0x400) Then ContinueLoop
		$item = GetItemByAgentID($i)
		If (DllStructGetData(($item), 'ModelID') == $ID_FoW_Unholy_Texts) Then
			Info('Unholy Texts: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			$deadlock = TimerInit()
			While GetAgentExists($i)
				RndSleep(500)
				If GetIsDead() Then Return
				If TimerDiff($deadlock) > 20000 Then
					Error('Could not get Unholy Texts at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
					Return False
				EndIf
			WEnd
			Return True
		EndIf
	Next
	Return False
EndFunc

;target wolf
Func IsShardWolf($agent)
    Return DllStructGetData($agent, 'PlayerNumber') == $Shard_Wolf_PlayerNumber
EndFunc

Func ShardWolfKill()
    Local $agents = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS, IsShardWolf)
    ; Shard Wolf found
    If $agents[0] > 0 Then
        Local $shardWolf = $agents[1]
        MoveAggroAndKill(DllStructGetData($shardWolf, 'X'), DllStructGetData($shardWolf, 'Y'))
    EndIf
EndFunc