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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :
; - Update movements to be depending on raptors positions to make sure almost all raptors are aggroed (especially boss group)
; - Make rubberbanding function using foes positions (if foes are mostly not around you then you're rubberbanding)
; - Add heroes and use Edge of Extinction ? A bit unnecessary, will do if bored
; - Optimise first cast of MoP to be made on first target that enters aggro (might be making farm worse : right now MoP is cast quite late which is good)
; - Use pumpkin pie slices ? Reduce cast time and increase attack speed reducing chances to be interrupted during MoP or Whirlwind


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $WNRaptorsFarmerSkillbar = 'OQQUc4oQt6SWC0kqM5F9Fja7grFA'
Global Const $DNRaptorsFarmerSkillbar = 'OQQTcYqVXySgmUlJvovYUbHctAA'	;Doesn't work, dervish just takes too much damage
Global Const $PRunnerHeroSkillbar = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $RaptorsFarmInformations = 'For best results, have :' & @CRLF _
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
Global $RAPTORS_FARM_SETUP = False

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain) is better than UseSkillEx(1))
Global Const $Raptors_MarkOfPain		= 1
Global Const $Raptors_IAmUnstoppable	= 2
Global Const $Raptors_ProtectorsDefense = 3
Global Const $Raptors_WaryStance		= 4
Global Const $Raptors_HundredBlades		= 5
Global Const $Raptors_SoldiersDefense	= 6
Global Const $Raptors_WhirlwindAttack	= 7
Global Const $Raptors_ShieldBash		= 8

Global Const $Raptors_SignetOfMysticSpeed	= 2
Global Const $Raptors_MirageCloak			= 3
Global Const $Raptors_VowOfStrength			= 4
Global Const $Raptors_ArmorOfSanctity		= 5
Global Const $Raptors_DustCloak				= 6
Global Const $Raptors_PiousFury				= 7
Global Const $Raptors_EremitesAttack		= 8

; Hero Build
Global Const $Raptors_VocalWasSogolon	= 1
Global Const $Raptors_Incoming			= 2
Global Const $Raptors_FallBack			= 3
Global Const $Raptors_EnduringHarmony	= 4
Global Const $Raptors_MakeHaste			= 5
Global Const $Raptors_StandYourGround	= 6
Global Const $Raptors_CantTouchThis		= 7
Global Const $Raptors_BladeturnRefrain	= 8

Global $RaptorsPlayerProfession = $ID_Warrior ; global variable to remember player's profession

Global $RaptorsMoveOptions = CloneDictMap($Default_MoveDefend_Options)
$RaptorsMoveOptions.Item('defendFunction')			= Null ; not using any defense skills during movement to preserve energy
$RaptorsMoveOptions.Item('moveTimeOut')				= 3 * 60 * 1000
$RaptorsMoveOptions.Item('randomFactor')			= 10
$RaptorsMoveOptions.Item('hosSkillSlot')			= 0
$RaptorsMoveOptions.Item('deathChargeSkillSlot')	= 0
$RaptorsMoveOptions.Item('openChests')				= False


;~ Main method to farm Raptors
Func RaptorsFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $RAPTORS_FARM_SETUP And SetupRaptorsFarm() == $FAIL Then Return $PAUSE

	GoToRivenEarth()
	Local $result = RaptorsFarmLoop()
	ReturnBackToOutpost($ID_Rata_Sum)
	Return $result
EndFunc


;~ Setup the Raptor farm for faster farm
Func SetupRaptorsFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_Rata_Sum, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	SetDisplayedTitle($ID_Asura_Title)
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerRaptorsFarm() == $FAIL Then Return $FAIL
	If SetupTeamRaptorsFarm() == $FAIL Then Return $FAIL
	GoToRivenEarth()
	MoveTo(-25800, -4150)
	Move(-26309, -4112)
	RandomSleep(1000)
	WaitMapLoading($ID_Rata_Sum, 10000, 2000)
	$RAPTORS_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerRaptorsFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_Warrior
			$RaptorsPlayerProfession = $ID_Warrior
			LoadSkillTemplate($WNRaptorsFarmerSkillbar)
		Case $ID_Dervish
			$RaptorsPlayerProfession = $ID_Dervish
			LoadSkillTemplate($DNRaptorsFarmerSkillbar)
		Case Else
    		Warn('Should run this farm as warrior or dervish (though dervish build doesn''t seem to work)')
			Return $FAIL
	EndSwitch
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamRaptorsFarm()
	Info('Setting up team')
	Sleep(500 + GetPing())
	LeaveParty()
	AddHero($ID_General_Morgahn)
	Sleep(500 + GetPing())
	LoadSkillTemplate($PRunnerHeroSkillbar, 1)
	Sleep(250)
	DisableAllHeroSkills(1)
	Sleep(500 + GetPing())
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Riven Earth
Func GoToRivenEarth()
	TravelToOutpost($ID_Rata_Sum, $DISTRICT_NAME)
	While GetMapID() <> $ID_Riven_Earth
		Info('Moving to Riven Earth')
		MoveTo(19700, 16800)
		Move(20084, 16854)
		RandomSleep(1000)
		WaitMapLoading($ID_Riven_Earth, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func RaptorsFarmLoop()
	If GetMapID() <> $ID_Riven_Earth Then Return $FAIL

	UseHeroSkill(1, $Raptors_VocalWasSogolon)
	RandomSleep(1200)
	UseHeroSkill(1, $Raptors_Incoming)
	GetRaptorsAsuraBlessing()
	MoveToBaseOfCave()
	Info('Moving Hero away')
	CommandAll(-25309, -4212)
	If AggroRaptors() == $FAIL Then Return $FAIL
	If KillRaptors() == $FAIL Then Return $FAIL
	RandomSleep(1000)

	If IsPlayerDead() Then Return $FAIL
	Info('Looting')
	If IsPlayerAlive() Then PickUpItems(RaptorsDefend)
	RandomSleep(1000)
	If IsPlayerAlive() Then PickUpItems(RaptorsDefend)

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
	UseHeroSkill(1, $Raptors_FallBack)
	RandomSleep(500)
	If ($RaptorsPlayerProfession == $ID_Warrior) Then UseSkillEx($Raptors_IAmUnstoppable)
	Moveto(-21333, -8384)
	UseHeroSkill(1, $Raptors_EnduringHarmony, GetMyAgent())
	If ($RaptorsPlayerProfession == $ID_Dervish) Then UseSkillEx($Raptors_SignetOfMysticSpeed, GetMyAgent())
	RandomSleep(1800)
	UseHeroSkill(1, $Raptors_MakeHaste, GetMyAgent())
	RandomSleep(20)
	UseHeroSkill(1, $Raptors_StandYourGround)
	RandomSleep(20)
	UseHeroSkill(1, $Raptors_CantTouchThis)
	RandomSleep(20)
	UseHeroSkill(1, $Raptors_BladeturnRefrain, GetMyAgent())
	Move(-20930, -9480, 40)
EndFunc


;~ Aggro all raptors
Func AggroRaptors()
	If IsPlayerDead() Then Return $FAIL
	Info('Gathering Raptors')

	Move(-20695, -9900, 20)
	; Using the nearest to agent could result in targeting Angorodon if they are badly placed
	Local $target = GetNearestEnemyToCoords(-20042, -10251)

	If ($RaptorsPlayerProfession == $ID_Warrior) Then UseSkillEx($Raptors_ShieldBash)

	Local $count = 0
	While IsPlayerAlive() And IsRecharged($Raptors_MarkOfPain) And $count < 200
		UseSkillEx($Raptors_MarkOfPain, $target)
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
	If $RaptorsPlayerProfession == $ID_Dervish Then UseSkillEx($Raptors_MirageCloak)
	If Not IsBossAggroed() And MoveAggroingRaptors(-22300, -12000) == $STUCK Then Return $FAIL
	If Not IsBossAggroed() And MoveAggroingRaptors(-22600, -12000) == $STUCK Then Return $FAIL
	If IsBossAggroed() Then
		If MoveAggroingRaptors(-22400, -12400) == $STUCK Then Return $FAIL
	Else
		If MoveAggroingRaptors(-23300, -12050) == $STUCK Then Return $FAIL
	EndIf
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


;~ Move to (X,Y) while staying alive vs raptors
Func MoveAggroingRaptors($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $RaptorsMoveOptions)
EndFunc


;~ Get foe that is a boss - Null if no boss
Func GetBossFoe()
	Local $bossFoes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS, GetIsBoss)
	Return IsArray($bossFoes) And UBound($bossFoes) > 0 ? $bossFoes[0] : Null
EndFunc


;~ Returns true if the boss is aggroed, that is, if boss is in attack stance TypeMap == 0x1, not in idle stance TypeMap = 0x0
Func IsBossAggroed()
	Local $boss = GetBossFoe()
	Return BitAND(DllStructGetData($boss, 'TypeMap'), 0x1) == 1
EndFunc


;~ Defend skills to use when looting in case some mobs are still alive
Func RaptorsDefend()
	Switch $RaptorsPlayerProfession
		Case $ID_Warrior
			If GetEnergy() > 5 And IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
			If GetEnergy() > 5 And IsRecharged($Raptors_ShieldBash) Then UseSkillEx($Raptors_ShieldBash)
			If GetEnergy() > 5 And IsRecharged($Raptors_SoldiersDefense) Then
				UseSkillEx($Raptors_SoldiersDefense)
			ElseIf GetEnergy() > 10 And IsRecharged($Raptors_WaryStance) Then
				UseSkillEx($Raptors_WaryStance)
			EndIf
		Case $ID_Dervish
			If GetEnergy() > 6 And IsRecharged($Raptors_MirageCloak) Then UseSkillEx($Raptors_MirageCloak)
			If GetEnergy() > 3 And IsRecharged($Raptors_ArmorOfSanctity) Then UseSkillEx($Raptors_ArmorOfSanctity)
	EndSwitch
EndFunc


;~ Kill raptors
Func KillRaptors()
	Local $MoPTarget
	If IsPlayerDead() Then Return $FAIL
	Info('Clearing Raptors')

	Switch $RaptorsPlayerProfession
		Case $ID_Warrior
			If IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
			RandomSleep(20)
			UseSkillEx($Raptors_ProtectorsDefense)
			RandomSleep(20)
			UseSkillEx($Raptors_HundredBlades)
			RandomSleep(20)
			UseSkillEx($Raptors_WaryStance)
			RandomSleep(20)
		Case $ID_Dervish
			UseSkillEx($Raptors_VowOfStrength)
			RandomSleep(20)
			UseSkillEx($Raptors_ArmorOfSanctity)
			RandomSleep(20)
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

	If ($RaptorsPlayerProfession == $ID_Dervish) Then
		UseSkillEx($Raptors_DustCloak)
		RandomSleep(20)
		UseSkillEx($Raptors_PiousFury)
		RandomSleep(20)
	EndIf

	Debug('Waiting on MoP to be recharged and foes to be in range')
	Local $count = 0
	While IsPlayerAlive() And (Not IsRecharged($Raptors_MarkOfPain) Or Not RaptorsAreBalled()) And $count < 40
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
	While IsPlayerAlive() And IsRecharged($Raptors_MarkOfPain) And $count < 200 And TimerDiff($timer) < 10000
		UseSkillEx($Raptors_MarkOfPain, $MoPTarget)
		RandomSleep(50)
		$count += 1
	WEnd

	If ($RaptorsPlayerProfession == $ID_Warrior) Then
		If IsRecharged($Raptors_IAmUnstoppable) Then UseSkillEx($Raptors_IAmUnstoppable)
		UseSkillEx($Raptors_SoldiersDefense)
		RandomSleep(50)

		Debug('Using Whirlwind attack')
		$count = 0
		While IsPlayerAlive() And GetSkillbarSkillAdrenaline($Raptors_WhirlwindAttack) <> 130 And $count < 200
			RandomSleep(50)
			$count += 1
		WEnd

		Local $me = GetMyAgent()
		Info('Spiking ' & CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) & ' raptors')
		UseSkillEx($Raptors_ShieldBash)
		RandomSleep(20)
		Debug('Using Whirlwind attack a second time')
		While IsPlayerAlive() And CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 10 And GetSkillbarSkillAdrenaline($Raptors_WhirlwindAttack) == 130
			UseSkillEx($Raptors_WhirlwindAttack, GetNearestEnemyToAgent($me))
			RandomSleep(250)
			$me = GetMyAgent()
		WEnd
	Else
		Info('Spiking ' & CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) & ' raptors')
		While IsPlayerAlive() And CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 10
			UseSkillEx($Raptors_EremitesAttack, GetNearestEnemyToAgent($me))
			RandomSleep(250)
			$me = GetMyAgent()
		WEnd
	EndIf
	Return IsPlayerAlive()? $SUCCESS : $FAIL
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