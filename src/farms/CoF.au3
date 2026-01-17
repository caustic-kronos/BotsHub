#CS ===========================================================================
; Authors: DeeperBlue, unknown
; Contributor: Gahais
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

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $D_COF_SKILLBAR = 'OgCjkqqLrSihdftXYijhOXhX0kA'
Global Const $COF_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- +1+3 Wind Prayers Rune' &@CRLF _
	& '- +1 Mystisicm Rune' & @CRLF _
	& '- +1 Scythe Mastery Runed' & @CRLF _
	& '- +50 HP Rune' & @CRLF _
	& '- +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias'& @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration) with a random inscription' & @CRLF _
	& '- This bot enters the Quest ''Temple of the Damned'', but bot doesn''t finish it' & @CRLF _
	& '- This bot farms Golden Rin Relics and Diessa Chalices and bones in the Cathedral of Flames' & @CRLF _
	& '- If you don''t have ''I Am Unstoppable'' skill then it is no problem, bot will still work, but the fail rate will increase slightly' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer' & @CRLF
Global Const $COF_FARM_DURATION = 5 * 60 * 1000


; === Dialogs ===
Global Const $QUEST_INIT_DIALOG = 0x832103
Global Const $QUEST_ACCEPT_DIALOG = 0x832101
Global Const $ENTER_INIT_DIALOG = 0x832105
Global Const $ENTER_ACCEPT_DIALOG = 0x88

Global Const $MODELID_MURAKAI_SERVANT	= 7069
Global Const $MODELID_CRYPT_GHOUL		= 7075
Global Const $MODELID_CRYPT_SLASHER		= 7077
Global Const $MODELID_CRYPT_WRAITH		= 7079
Global Const $MODELID_CRYPT_BANSHEE		= 7081
Global Const $MODELID_SHOCK_PHANTOM		= 7083
Global Const $MODELID_ASH_PHANTOM		= 7085

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SKILL_CONVICTION is better than UseSkillEx(1))
Global Const $COF_PIOUS_FURY				= 1
Global Const $COF_GRENTHS_AURA				= 2
Global Const $COF_VOW_OF_SILENCE			= 3
Global Const $COF_SIGNET_OF_MYSTIC_SPEED	= 4
Global Const $COF_CRIPPLING_VICTORY			= 5
Global Const $COF_REAP_IMPURITIES			= 6
Global Const $COF_VOW_OF_PIETY				= 7
Global Const $COF_I_AM_UNSTOPPABLE			= 8

Global $cof_farm_setup = False

;~ Main loop of the Cathedral of Flames farm
Func CoFFarm()
	If Not $cof_farm_setup And SetupCoFFarm() == $FAIL Then Return $PAUSE
	Sleep(10000)
	GoToCathedralOfFlames()
	Local $result = CoFFarmLoop()
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	Return $result
EndFunc


;~ Farm setup : going to the Doomlore Shrine
Func SetupCoFFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchToHardModeIfEnabled()
	If SetupPlayerCoFFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	GoToCathedralOfFlames()
	RandomSleep(2500)
	Move(-19300, -8250)
	RandomSleep(2500)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 2500)
	$cof_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerCoFFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_DERVISH Then
		LoadSkillTemplate($D_COF_SKILLBAR)
	Else
		Warn('Should run this farm as dervish')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Exit outpost to enter Cathedral of Flames mission
Func GoToCathedralOfFlames()
	TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)
	While GetMapID() <> $ID_CATHEDRAL_OF_FLAMES
		Info('Entering Cathedral of Flames')
		Local $Gron = GetNearestNPCToCoords(-19166, 17980)
		GoToNPC($Gron)
		If IsQuestNotFound($ID_QUEST_TEMPLE_OF_THE_DAMNED) Then
			TakeQuest($Gron, $ID_QUEST_TEMPLE_OF_THE_DAMNED, $QUEST_ACCEPT_DIALOG, $QUEST_INIT_DIALOG)
		Else
			Dialog($ENTER_INIT_DIALOG)
			RandomSleep(500)
			Dialog($ENTER_ACCEPT_DIALOG)
		EndIf
		WaitMapLoading($ID_CATHEDRAL_OF_FLAMES)
	WEnd
EndFunc


;~ Farm loop of Cathedral of Flames
Func CoFFarmLoop()
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-18250, -8595))
	Sleep(500)
	Dialog(0x84)
	Sleep(500)

	AggroAndPrepare()
	Info('Farming Cryptos')
	CleanCoFMobs()
	If IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems()
			RandomSleep(50)
		Next
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


Func AggroAndPrepare()
	MoveTo(-16850, -8930)
	UseSkillEx($COF_VOW_OF_PIETY)
	UseSkillEx($COF_GRENTHS_AURA)
	UseSkillEx($COF_VOW_OF_SILENCE)
	UseSkillEx($COF_SIGNET_OF_MYSTIC_SPEED)
	MoveTo(-15220, -8950)
	UseSkillEx($COF_I_AM_UNSTOPPABLE)
	Sleep(500)
EndFunc


;~ Ensure that Vow of Silence enchantment is active
Func CheckVoS()
	If IsRecharged($COF_VOW_OF_SILENCE) Then
		UseSkillEx($COF_PIOUS_FURY)
		UseSkillEx($COF_GRENTHS_AURA)
		UseSkillEx($COF_VOW_OF_SILENCE)
	EndIf
EndFunc


Func CleanCoFMobs()
	Local $target = Null
	CheckVoS()
	While IsPlayerAlive() And CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT, IsUndead) > 0
		CheckVoS()
		If GetSkillbarSkillAdrenaline($COF_CRIPPLING_VICTORY) >= 150 Then
			$target = GetNearestEnemyToAgent(GetMyAgent())
			ChangeTarget($target)
			UseSkillEx($COF_CRIPPLING_VICTORY)
			RandomSleep(800)
			CheckVoS()
		EndIf
		If GetSkillbarSkillAdrenaline($COF_REAP_IMPURITIES) >= 120 Then
			$target = GetNearestEnemyToAgent(GetMyAgent())
			UseSkillEx($COF_REAP_IMPURITIES)
			RandomSleep(800)
			CheckVoS()
		EndIf
		Sleep(100)
		$target = GetNearestEnemyToAgent(GetMyAgent())
		Attack($target)
	WEnd
	RandomSleep(200)
EndFunc


Func IsUndead($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return $modelID == $MODELID_MURAKAI_SERVANT Or $modelID == $MODELID_CRYPT_GHOUL _
		Or $modelID == $MODELID_CRYPT_SLASHER Or $modelID == $MODELID_CRYPT_WRAITH _
		Or $modelID == $MODELID_CRYPT_BANSHEE Or $modelID == $MODELID_SHOCK_PHANTOM _
		Or $modelID == $MODELID_ASH_PHANTOM
EndFunc
