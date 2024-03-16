#CS
#################################
#								#
#	Dragon Moss Bot				#
#								#
#################################
Author: Night
#CE

#include-once
#RequireAdmin
#NoTrayIcon

#include 'GWA2_Headers.au3'
#include 'GWA2.au3'
#include 'Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $DragonMossBotVersion = '0.1'

; ==== Constantes ====
Local Const $RADragonMossFarmerSkillbar = 'OgcTcZ88Z6u844AiHRnJuE3R4AA'
Local Const $DragonMossFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Wilderness Survival' & @CRLF _
	& '- A shield with the inscription "Riders on the storm" (+10 armor against Lightning damage)' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain)  is better than UseSkillEx(1))
Local Const $DM_DwarvenStability = 1
Local Const $DM_StormChaser = 2
Local Const $DM_ShroudOfDistress = 3
Local Const $DM_DeadlyParadox = 4
Local Const $DM_ShadowForm = 5
Local Const $DM_MentalBlock = 6
Local Const $DM_DeathsCharge = 7
Local Const $DM_WhirlingDefense = 8

Local $DM_FARM_SETUP = False

;~ Main method to farm Dragon Moss
Func DragonMossFarm($STATUS)
	If Not $DM_FARM_SETUP Then
		SetupDragonMossFarm()
		$DM_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return DragonMossFarmLoop()
EndFunc


Func SetupDragonMossFarm()
	Out('Setting up farm')
	If GetMapID() <> $ID_Saint_Anjekas_Shrine Then
		DistrictTravel($ID_Saint_Anjekas_Shrine, $ID_EUROPE, $ID_FRENCH)
	EndIf
	SwitchMode($ID_HARD_MODE)
	LeaveGroup()
	Out('Entering Drazach Thicket')
	MoveTo(-11400, -22650)
	MoveTo(-11000, -24000)
	WaitMapLoading($ID_Drazach_Thicket, 10000, 2000)
	MoveTo(-11100, 19700)
	MoveTo(-11300, 19900)
	WaitMapLoading($ID_Saint_Anjekas_Shrine, 10000, 2000)
	Out('Preparations complete')
EndFunc


;~ Farm loop
Func DragonMossFarmLoop()
	If Not $RenderingEnabled Then ClearMemory()
	Out('Entering Drazach Thicket')
	MoveTo(-11400, -22650)
	MoveTo(-11000, -24000)
	WaitMapLoading($ID_Drazach_Thicket, 10000, 2000)
	UseSkillEx($DM_DwarvenStability)
	RndSleep(100)
	UseSkillEx($DM_StormChaser)
	RndSleep(100)
	MoveTo(-8400, 18450)
	;Can talk to get benediction here
	
	;Move to spot before aggro
	MoveTo(-6500, 17200)
	UseSkillEx($DM_ShroudOfDistress)
	RndSleep(100)
	UseSkillEx($DM_DeadlyParadox)
	RndSleep(100)
	UseSkillEx($DM_ShadowForm)
	RndSleep(100)
	;Aggro
	MoveTo(-5500, 15800, 0, UseIMSWhenAvailable)
	MoveTo(-5000, 15000, 0, UseIMSWhenAvailable)
	MoveTo(-6150, 18000, 0, UseIMSWhenAvailable)
	RndSleep(2000)
	;Safety
	MoveTo(-6900, 19000)
	UseSkillEx($DM_DeadlyParadox)
	RndSleep(100)
	UseSkillEx($DM_ShadowForm)
	RndSleep(100)
	UseSkillEx($DM_DwarvenStability)
	RndSleep(100)
	If GetIsDead(-2) Then
		BackToSaintAnjekaOutpost()
		Return 1
	EndIf
	RndSleep(1000)
	;Killing
	Local $target = GetNearestEnemyToAgent(-2)
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_ADJACENT)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	While IsRecharged($DM_DeathsCharge) And Not GetIsDead(-2)
		UseSkillEx($DM_DeathsCharge, $target)
		RndSleep(200)
	WEnd
	While IsRecharged($DM_WhirlingDefense) And Not GetIsDead(-2)
		UseSkillEx($DM_WhirlingDefense)
		RndSleep(200)
	WEnd
	
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	Local $counter = 0
	While Not GetIsDead(-2) And $foesCount > 0 And $counter < 16
		If IsRecharged($DM_ShadowForm) Then UseSkillEx($DM_ShadowForm)
		RndSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	WEnd

	If GetIsDead(-2) Then
		BackToSaintAnjekaOutpost()
		Return 1
	EndIf

	RndSleep(1000)

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		Out('Looting')
		PickUpItems()
	EndIf

	BackToSaintAnjekaOutpost()
	Return 0
EndFunc


Func UseIMSWhenAvailable()
	If IsRecharged($DM_StormChaser) Then UseSkillEx($DM_StormChaser)
EndFunc


Func BackToSaintAnjekaOutpost()
	Out('Porting to Saint Anjekas Shrine')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Saint_Anjekas_Shrine, 10000, 2000)
EndFunc