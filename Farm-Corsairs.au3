#CS
#################################
#								#
#	Corsairs Bot 				#
#								#
#################################
Author: Night
#CE

#include-once
#RequireAdmin
#NoTrayIcon

#include "GWA2_Headers.au3"
#include "GWA2.au3"
#include "Utils.au3"

; Possible improvements : 

Opt("MustDeclareVars", 1)

Local Const $CorsairsBotVersion = "0.4"

; ==== Constantes ====
Local Const $RACorsairsFarmerSkillbar = "OgcSc5PTHQj1rg3lhOIQCH4O"
Local Const $CorsairsFarmInformations = "For best results, have :" & @CRLF _
	& "- 16 in Expertise" & @CRLF _
	& "- 12 in Shadow Arts" & @CRLF _
	& "- A shield with the inscription 'Through Thick and Thin' (+10 armor against Piercing damage)" & @CRLF _
	& "- A spear +5 energy +5 armor or +20% enchantment duration" & @CRLF _
	& "- Sentry or Blessed insignias on all the armor pieces" & @CRLF _
	& "- A superior vigor rune" & @CRLF _
	& "- Dunkoro"
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain)  is better than UseSkillEx(1))
Local Const $Corsairs_DwarvenStability = 1
Local Const $Corsairs_ShadowOfHaste = 2
Local Const $Corsairs_ShroudOfDistress = 3
Local Const $Corsairs_TogetherAsOne = 4
;Local Const $Corsairs_ShadowSanctuary = 5
Local Const $Corsairs_MentalBlock = 5
Local Const $Corsairs_HeartOfShadow = 6
Local Const $Corsairs_WhirlingDefense = 7
Local Const $Corsairs_DeathsCharge = 8

; Hero Build
Local Const $Corsairs_MakeHaste = 1

#Region GUI
Local $CORSAIRS_FARM_SETUP = False


;~ Main method to farm Corsairs
Func CorsairsFarm($STATUS)
	If $STATUS <> "RUNNING" Then Return 2

	If (((CountSlots() < 5) AND (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED))) Then
		Out("Inventory full, pausing.")
		Return 2
	EndIf

	If $STATUS <> "RUNNING" Then Return 2

	If Not $CORSAIRS_FARM_SETUP Then 
		SetupCorsairsFarm()
		$CORSAIRS_FARM_SETUP = True
	EndIf

	If $STATUS <> "RUNNING" Then Return 2

	Return CorsairsFarmLoop()
EndFunc


Func SetupCorsairsFarm()
	Out("Setting up farm")
	If GetMapID() <> $ID_Moddok_Crevice Then
		DistrictTravel($ID_Moddok_Crevice, $ID_EUROPE, $ID_FRENCH)
	EndIf
	SwitchMode($ID_HARD_MODE)
	AddHero($ID_Dunkoro)
	Out("Preparations complete")
EndFunc


;~ Farm loop
Func CorsairsFarmLoop()
	If Not $RenderingEnabled Then ClearMemory()
	Out("Entering mission")
	GoToNPC(GetNearestNPCToCoords(-13875, -12800))
	RndSleep(250)
	Dialog(0x00000084)
	RndSleep(500)
	WaitMapLoading($ID_Moddok_Crevice)
	UseHeroSkill(1, $Corsairs_MakeHaste, -2)
	RndSleep(250)
	CommandHero(1, -13750, -10150)

	MoveTo(-9050, -7000)
	Local $Captain_Bohseda = GetNearestNPCToCoords(-9850, -7250)
	UseSkillEx($Corsairs_HeartOfShadow, $Captain_Bohseda)
	RndSleep(250)
	MoveTo(-8020, -6500)
	MoveTo(-7400, -4750)
	UseSkillEx($Corsairs_TogetherAsOne)
	RndSleep(100)
	UseSkillEx($Corsairs_ShroudOfDistress)
	RndSleep(100)
	UseSkillEx($Corsairs_MentalBlock)
	RndSleep(100)
	MoveTo(-7300, -4500)
	
	MoveTo(-8100, -6550)
	DefendAgainstCorsairs()
	UseSkillEx($Corsairs_DwarvenStability)
	RndSleep(100)
	UseSkillEx($Corsairs_ShadowOfHaste)
	WaitForEnemies()
	
	MoveTo(-8450, -6750)
	WaitForEnemies()
	
	MoveTo(-8650, -6850)
	WaitForEnemies()
	
	MoveTo(-8850, -6950)
	WaitForEnemies()
	
	UseSkillEx($Corsairs_HeartOfShadow, GetNearestEnemyToAgent(-2))
	WaitForEnemies()

	MoveTo(-9400,-7100)
	WaitForEnemies()

	MoveTo(-9600,-7150)
	WaitForEnemies()

	MoveTo(-9850,-7100)
	UseSkillEx($Corsairs_DwarvenStability)
	WaitForEnemies()
	
	MoveTo(-9800,-7250)
	GoNPC($Captain_Bohseda)
	RndSleep(250)
	WaitForEnemies()
	Dialog(0x00000085)
	RndSleep(1500)
	UseSkillEx($Corsairs_WhirlingDefense)
	RndSleep(100)

	For $i = 0 To 13
		DefendAgainstCorsairs(False)
		If $i > 3 Then Attack(GetNearestEnemyToAgent(-2))
		RndSleep(1000)
	Next
	
	Local $target = GetNearestEnemyToCoords(-8915, -6915)
	UseSkillEx($Corsairs_DeathsCharge, $target)
	RndSleep(100)

	Local $counter = 0
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	While Not GetIsDead(-2) And $foesCount > 0 And $counter < 22
		DefendAgainstCorsairs(False)
		Attack(GetNearestEnemyToAgent(-2))
		RndSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	WEnd

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		Out("Looting")
		PickUpItems(DefendAgainstCorsairs)
	EndIf

	BackToModdokCreviceOutpost()
EndFunc


Func DefendAgainstCorsairs($useShadowSanctuary = True)
	If IsRecharged($Corsairs_TogetherAsOne) Then
		UseSkillEx($Corsairs_TogetherAsOne)
		RndSleep(GetPing() + 100)
	EndIf
;	If $useShadowSanctuary And IsRecharged($Corsairs_ShadowSanctuary) Then
;		UseSkillEx($Corsairs_ShadowSanctuary)
;		RndSleep(GetPing() + 100)
;	EndIf
	If IsRecharged($Corsairs_MentalBlock) And GetEffectTimeRemaining(GetEffect($ID_Mental_Block)) == 0 Then
		UseSkillEx($Corsairs_MentalBlock)
		RndSleep(GetPing() + 100)
	EndIf
	If IsRecharged($Corsairs_ShroudOfDistress) Then
		UseSkillEx($Corsairs_ShroudOfDistress)
		RndSleep(GetPing() + 100)
	EndIf
EndFunc


Func BackToModdokCreviceOutpost()
	Out("Porting to Moddok Crevice (city)")
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Moddok_Crevice, 10000, 2000)
EndFunc


Func WaitForEnemies()
	RndSleep(250)
	While EnemiesGettingTooFar()
		DefendAgainstCorsairs()
		RndSleep(250)
	WEnd
EndFunc

Func EnemiesGettingTooFar()
	Local $aggroedFoes = CountFoesInRangeOfAgent(-2, $RANGE_SPIRIT)
	Local $inRangeFoes = CountFoesInRangeOfAgent(-2, 1150)
	If $inRangeFoes == $aggroedFoes Then
		Return False
	Else
		Return True
	EndIf
EndFunc