#CS ===========================================================================
#################################
#								#
#	Raptor Bot
#								#
#################################
; Author: Rattiev
; Based on : Vaettir Bot by gigi
; Modified by: Night, Gahais
; Raptor farm in Riven Earth based on below article:
https://gwpvx.fandom.com/wiki/Build:W/N_Raptor_Farmer
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

; Possible improvements :
; - Update movements to be depending on raptors positions to make sure almost all raptors are aggroed (especially boss group)
; - Make rubberbanding function using foes positions (if foes are mostly not around you then you're rubberbanding)
; - Add heroes and use Edge of Extinction ? A bit unnecessary, will do if bored
; - Optimise first cast of MoP to be made on first target that enters aggro (might be making farm worse : right now MoP is cast quite late which is good)
; - Use pumpkin pie slices ? Reduce cast time and increase attack speed reducing chances to be interrupted during MoP or Whirlwind


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $WN_RAPTORS_FARMER_SKILLBAR = 'OQQUc4oQt6SWC0kqM5F9Fja7grFA'
;Doesn't work, dervish just takes too much damage
Global Const $DN_RAPTORS_FARMER_SKILLBAR = 'OQQTcYqVXySgmUlJvovYUbHctAA'
Global Const $P_RUNNER_HERO_SKILLBAR = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $RAPTORS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 12 in curses' & @CRLF _
	& '- 12+ in tactics' & @CRLF _
	& '- 9+ in swordsmanship (enough to use your sword)'& @CRLF _
	& '- A Tactics shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A sword of Shelter, prefix and inscription do not matter' & @CRLF _
	& '- Knight insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- A superior Absorption rune' & @CRLF _
	& '- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership' & @CRLF _
	& '		and all of his skills locked' & @CRLF _
	& ' ' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:W/N_Raptor_Farmer' & @CRLF
; Average duration ~ 1m10s ~ First run is 1m30s with setup
Global Const $RAPTORS_FARM_DURATION = (1 * 60 + 20) * 1000

; You can select which paragon hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
Global Const $RAPTORS_HERO_PARTY_ID = $ID_GENERAL_MORGAHN
;Global Const $RAPTORS_HERO_PARTY_ID = $ID_KEIRAN_THACKERAY
;Global Const $RAPTORS_HERO_PARTY_ID = $ID_HAYDA
Global Const $RAPTORS_HERO_INDEX = 1

; Skill numbers declared to make the code WAY more readable (UseSkillEx($RAPTORS_MARK_OF_PAIN) is better than UseSkillEx(1))
Global Const $RAPTORS_MARK_OF_PAIN				= 1
Global Const $RAPTORS_I_AM_UNSTOPPABLE			= 2
Global Const $RAPTORS_PROTECTORS_DEFENSE		= 3
Global Const $RAPTORS_WARY_STANCE				= 4
Global Const $RAPTORS_HUNDRED_BLADES			= 5
Global Const $RAPTORS_SOLDIERS_DEFENSE			= 6
Global Const $RAPTORS_WHIRLWIND_ATTACK			= 7
Global Const $RAPTORS_SHIELD_BASH				= 8

Global Const $RAPTORS_SIGNET_OF_MYSTIC_SPEED	= 2
Global Const $RAPTORS_MIRAGE_CLOAK				= 3
Global Const $RAPTORS_VOW_OF_STRENGTH			= 4
Global Const $RAPTORS_ARMOR_OF_SANCTITY			= 5
Global Const $RAPTORS_DUST_CLOAK				= 6
Global Const $RAPTORS_PIOUS_FURY				= 7
Global Const $RAPTORS_EREMITES_ATTACK			= 8

; Hero Build
Global Const $RAPTORS_VOCAL_WAS_SOGOLON	= 1
Global Const $RAPTORS_INCOMING			= 2
Global Const $RAPTORS_FALLBACK			= 3
Global Const $RAPTORS_ENDURING_HARMONY	= 4
Global Const $RAPTORS_MAKE_HASTE		= 5
Global Const $RAPTORS_STAND_YOUR_GROUND	= 6
Global Const $RAPTORS_CANT_TOUCH_THIS	= 7
Global Const $RAPTORS_BLADETURN_REFRAIN	= 8

Global $raptors_move_options = CloneDictMap($Default_MoveDefend_Options)
$raptors_move_options.Item('defendFunction')			= Null
$raptors_move_options.Item('moveTimeOut')				= 3 * 60 * 1000
$raptors_move_options.Item('randomFactor')			= 10
$raptors_move_options.Item('hosSkillSlot')			= 0
$raptors_move_options.Item('deathChargeSkillSlot')	= 0
$raptors_move_options.Item('openChests')				= False

Global $raptors_farm_setup = False
Global $raptors_player_profession = $ID_WARRIOR

;~ Main method to farm Raptors
Func RaptorsFarm()
	If Not $raptors_farm_setup And SetupRaptorsFarm() == $FAIL Then Return $PAUSE

	GoToRivenEarth()
	Local $result = RaptorsFarmLoop()
	ReturnBackToOutpost($ID_RATA_SUM)
	Return $result
EndFunc


;~ Setup the Raptor farm for faster farm
Func SetupRaptorsFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_RATA_SUM, $district_name) == $FAIL Then Return $FAIL
	SetDisplayedTitle($ID_ASURA_TITLE)
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerRaptorsFarm() == $FAIL Then Return $FAIL
	If SetupTeamRaptorsFarm() == $FAIL Then Return $FAIL
	GoToRivenEarth()
	MoveTo(-25800, -4150)
	Move(-26309, -4112)
	RandomSleep(1000)
	WaitMapLoading($ID_RATA_SUM, 10000, 2000)
	$raptors_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerRaptorsFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_WARRIOR
			$raptors_player_profession = $ID_WARRIOR
			LoadSkillTemplate($WN_RAPTORS_FARMER_SKILLBAR)
		Case $ID_DERVISH
			$raptors_player_profession = $ID_DERVISH
			LoadSkillTemplate($DN_RAPTORS_FARMER_SKILLBAR)
		Case Else
			Warn('Should run this farm as warrior or dervish (though dervish build doesn''t seem to work)')
			Return $FAIL
	EndSwitch
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamRaptorsFarm()
	Info('Setting up team')
	RandomSleep(500)
	LeaveParty()
	RandomSleep(500)
	AddHero($RAPTORS_HERO_PARTY_ID)
	RandomSleep(250)
	LoadSkillTemplate($P_RUNNER_HERO_SKILLBAR, $RAPTORS_HERO_INDEX)
	RandomSleep(250)
	DisableAllHeroSkills($RAPTORS_HERO_INDEX)
	RandomSleep(500)
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Riven Earth
Func GoToRivenEarth()
	TravelToOutpost($ID_RATA_SUM, $district_name)
	While GetMapID() <> $ID_RIVEN_EARTH
		Info('Moving to Riven Earth')
		MoveTo(19700, 16800)
		Move(20084, 16854)
		RandomSleep(1000)
		WaitMapLoading($ID_RIVEN_EARTH, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func RaptorsFarmLoop()
	If GetMapID() <> $ID_RIVEN_EARTH Then Return $FAIL

	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_VOCAL_WAS_SOGOLON)
	RandomSleep(1200)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_INCOMING)
	GetRaptorsAsuraBlessing()
	MoveToBaseOfCave()
	Info('Moving Hero away')
	CommandAll(-25309, -4212)
	If AggroRaptors() == $FAIL Then Return $FAIL
	If KillRaptors() == $FAIL Then Return $FAIL
	RandomSleep(1000)
	If IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(RaptorsDefend)
			RandomSleep(100)
		Next
	EndIf

	Return CheckFarmResult()
EndFunc


;~ Get Asura blessing only if title is not maxed yet
Func GetRaptorsAsuraBlessing()
	Local $Asura = GetAsuraTitle()
	If $Asura < 160000 Then
		Info('Getting asura title blessing')
		GoNearestNPCToCoords(-20000, 3000)
		Sleep(1000)
		Dialog(0x84)
		Sleep(1000)
	EndIf
	RandomSleep(350)
EndFunc


;~ Move to the entrance of the raptors cave
Func MoveToBaseOfCave()
	If IsPlayerDead() Then Return $FAIL
	Info('Moving to Cave')
	Move(-22015, -7502)
	RandomSleep(7000)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_FALLBACK)
	RandomSleep(500)
	If ($raptors_player_profession == $ID_WARRIOR) Then UseSkillEx($RAPTORS_I_AM_UNSTOPPABLE)
	Moveto(-21333, -8384)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_ENDURING_HARMONY, GetMyAgent())
	If ($raptors_player_profession == $ID_DERVISH) Then UseSkillEx($RAPTORS_SIGNET_OF_MYSTIC_SPEED, GetMyAgent())
	RandomSleep(1800)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_MAKE_HASTE, GetMyAgent())
	RandomSleep(50)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_STAND_YOUR_GROUND)
	RandomSleep(50)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_CANT_TOUCH_THIS)
	RandomSleep(50)
	UseHeroSkill($RAPTORS_HERO_INDEX, $RAPTORS_BLADETURN_REFRAIN, GetMyAgent())
	Move(-20930, -9480, 40)
EndFunc


;~ Aggro all raptors
Func AggroRaptors()
	If IsPlayerDead() Then Return $FAIL
	Info('Gathering Raptors')

	Move(-20695, -9900, 20)
	; Using the nearest to agent could result in targeting Angorodon if they are badly placed
	Local $target = GetNearestEnemyToCoords(-20042, -10251)

	If ($raptors_player_profession == $ID_WARRIOR) Then UseSkillEx($RAPTORS_SHIELD_BASH)

	Local $count = 0
	While IsPlayerAlive() And IsRecharged($RAPTORS_MARK_OF_PAIN) And $count < 200
		UseSkillEx($RAPTORS_MARK_OF_PAIN, $target)
		RandomSleep(50)
		$count += 1
	WEnd
	RandomSleep(250)

	If MoveAggroingRaptors(-20000, -10300) == $STUCK Then Return $FAIL
	If MoveAggroingRaptors(-19500, -11500) == $STUCK Then Return $FAIL
	If MoveAggroingRaptors(-20500, -12000) == $STUCK Then Return $FAIL
	If MoveAggroingRaptors(-21000, -12200) == $STUCK Then Return $FAIL
	If MoveAggroingRaptors(-21500, -12000) == $STUCK Then Return $FAIL
	If MoveAggroingRaptors(-22000, -12000) == $STUCK Then Return $FAIL
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If $raptors_player_profession == $ID_DERVISH Then UseSkillEx($RAPTORS_MIRAGE_CLOAK)
	If Not IsBossAggroed() And MoveAggroingRaptors(-22300, -12000) == $STUCK Then Return $FAIL
	If Not IsBossAggroed() And MoveAggroingRaptors(-22600, -12000) == $STUCK Then Return $FAIL
	If IsBossAggroed() Then
		If MoveAggroingRaptors(-22400, -12400) == $STUCK Then Return $FAIL
	Else
		If MoveAggroingRaptors(-23300, -12050) == $STUCK Then Return $FAIL
	EndIf
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Move to (X,Y) while staying alive vs raptors
Func MoveAggroingRaptors($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $raptors_move_options)
EndFunc


;~ Get foe that is a boss - Null if no boss
Func GetBossFoe()
	Local $bossFoes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS, GetIsBoss)
	Return IsArray($bossFoes) And UBound($bossFoes) > 0 ? $bossFoes[0] : Null
EndFunc


;~ Returns true if the boss is aggroed, that is, if boss is in attack stance TypeMap == 0x1, not in idle stance TypeMap = 0x0
Func IsBossAggroed()
	Local $boss = GetBossFoe()
	Return BitAND(DllStructGetData($boss, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE
EndFunc


;~ Defend skills to use when looting in case some mobs are still alive
Func RaptorsDefend()
	Switch $raptors_player_profession
		Case $ID_WARRIOR
			If GetEnergy() > 5 And IsRecharged($RAPTORS_I_AM_UNSTOPPABLE) Then UseSkillEx($RAPTORS_I_AM_UNSTOPPABLE)
			If GetEnergy() > 5 And IsRecharged($RAPTORS_SHIELD_BASH) Then UseSkillEx($RAPTORS_SHIELD_BASH)
			If GetEnergy() > 5 And IsRecharged($RAPTORS_SOLDIERS_DEFENSE) Then
				UseSkillEx($RAPTORS_SOLDIERS_DEFENSE)
			ElseIf GetEnergy() > 10 And IsRecharged($RAPTORS_WARY_STANCE) Then
				UseSkillEx($RAPTORS_WARY_STANCE)
			EndIf
		Case $ID_DERVISH
			If GetEnergy() > 6 And IsRecharged($RAPTORS_MIRAGE_CLOAK) Then UseSkillEx($RAPTORS_MIRAGE_CLOAK)
			If GetEnergy() > 3 And IsRecharged($RAPTORS_ARMOR_OF_SANCTITY) Then UseSkillEx($RAPTORS_ARMOR_OF_SANCTITY)
	EndSwitch
EndFunc


;~ Kill raptors
Func KillRaptors()
	Local $MoPTarget
	If IsPlayerDead() Then Return $FAIL
	Info('Clearing Raptors')

	Switch $raptors_player_profession
		Case $ID_WARRIOR
			If IsRecharged($RAPTORS_I_AM_UNSTOPPABLE) Then UseSkillEx($RAPTORS_I_AM_UNSTOPPABLE)
			RandomSleep(50)
			UseSkillEx($RAPTORS_PROTECTORS_DEFENSE)
			RandomSleep(50)
			UseSkillEx($RAPTORS_HUNDRED_BLADES)
			RandomSleep(50)
			UseSkillEx($RAPTORS_WARY_STANCE)
			RandomSleep(50)
		Case $ID_DERVISH
			UseSkillEx($RAPTORS_VOW_OF_STRENGTH)
			RandomSleep(50)
			UseSkillEx($RAPTORS_ARMOR_OF_SANCTITY)
			RandomSleep(50)
	EndSwitch

	Local $rekoff_boss = GetBossFoe()
	Local $me = GetMyAgent()
	If GetDistance($me, $rekoff_boss) > $RANGE_SPELLCAST Then
		$MoPTarget = GetNearestEnemyToAgent($me)
	Else
		$MoPTarget = GetNearestEnemyToAgent($rekoff_boss)
	EndIf

	If GetHasHex($MoPTarget) Then
		TargetNextEnemy()
		$MoPTarget = GetCurrentTarget()
	EndIf

	If ($raptors_player_profession == $ID_DERVISH) Then
		UseSkillEx($RAPTORS_DUST_CLOAK)
		RandomSleep(50)
		UseSkillEx($RAPTORS_PIOUS_FURY)
		RandomSleep(50)
	EndIf

	Debug('Waiting on MoP to be recharged and foes to be in range')
	Local $count = 0
	While IsPlayerAlive() And (Not IsRecharged($RAPTORS_MARK_OF_PAIN) Or Not RaptorsAreBalled()) And $count < 40
		Debug('Waiting ' & $count)
		RandomSleep(250)
		$count += 1
		If $count > 10 Then
			CheckAndSendStuckCommand()
		EndIf
	WEnd

	Debug('Using MoP')
	$count = 0
	Local $timer = TimerInit()
	; There is an issue here with infinite loop despite the count (wtf!) so added a timer as well
	While IsPlayerAlive() And IsRecharged($RAPTORS_MARK_OF_PAIN) And $count < 200 And TimerDiff($timer) < 10000
		UseSkillEx($RAPTORS_MARK_OF_PAIN, $MoPTarget)
		RandomSleep(50)
		$count += 1
	WEnd

	If ($raptors_player_profession == $ID_WARRIOR) Then
		If IsRecharged($RAPTORS_I_AM_UNSTOPPABLE) Then UseSkillEx($RAPTORS_I_AM_UNSTOPPABLE)
		UseSkillEx($RAPTORS_SOLDIERS_DEFENSE)
		RandomSleep(50)

		Debug('Using Whirlwind attack')
		$count = 0
		While IsPlayerAlive() And GetSkillbarSkillAdrenaline($RAPTORS_WHIRLWIND_ATTACK) <> 130 And $count < 200
			RandomSleep(50)
			$count += 1
		WEnd

		Local $me = GetMyAgent()
		Info('Spiking ' & CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) & ' raptors')
		UseSkillEx($RAPTORS_SHIELD_BASH)
		RandomSleep(50)
		Debug('Using Whirlwind attack a second time')
		While CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 10 And GetSkillbarSkillAdrenaline($RAPTORS_WHIRLWIND_ATTACK) == 130
			UseSkillEx($RAPTORS_WHIRLWIND_ATTACK, GetNearestEnemyToAgent($me))
			RandomSleep(250)
			$me = GetMyAgent()
			If IsPlayerDead() Then Return $FAIL
		WEnd
	Else
		Info('Spiking ' & CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) & ' raptors')
		While CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 10
			UseSkillEx($RAPTORS_EREMITES_ATTACK, GetNearestEnemyToAgent($me))
			RandomSleep(250)
			$me = GetMyAgent()
			If IsPlayerDead() Then Return $FAIL
		WEnd
	EndIf
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Mobs are sufficiently balled
Func RaptorsAreBalled()
	; Tolerance 2 : we accept that maximum 2 foes are still out of the ball
	Return CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA) >= CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) - 2
EndFunc


;~ Check whether or not the farm was successful
Func CheckFarmResult()
	If IsPlayerDead() Then
		Info('Character died')
		Return $FAIL
	EndIf

	Local $survivors = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	If $survivors > 1 Then
		Info($survivors & ' raptors survived')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc