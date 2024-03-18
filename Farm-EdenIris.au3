#CS
#################################
#								#
#	Eden Iris Bot 				#
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

Local Const $EdenIrisBotVersion = '0.4'

; ==== Constantes ====
Local Const $EdenIrisFarmInformations = 'Only thing needed for this farm is a character in Eden and Ashford Abbey unlocked.'

#Region GUI
Local $IRIS_FARM_SETUP = False

;~ Main method to farm Red Iris Flowers in Eden
Func EdenIrisFarm($STATUS)
	If GetMapID() <> $ID_Ashford_Abbey Then
		DistrictTravel($ID_Ashford_Abbey, $ID_EUROPE, $ID_FRENCH)
	EndIf
	
	If Not $IRIS_FARM_SETUP Then
		SetupEdenIrisFarm()
		$IRIS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return EdenIrisFarmLoop()
EndFunc


Func SetupEdenIrisFarm()
	Out('Setting up farm')
	MoveTo(-11600, -6250)
	Move(-11000, -6250)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	Move(-11600, -6250)
	RndSleep(1000)
	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
	Out('Resign preparation complete')
EndFunc

;~ Farm loop
Func EdenIrisFarmLoop()
	Move(-11000, -6250)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	If PickUpIris() Then
		Return ReturnToAshfordAbbey()
	EndIf
	Moveto(-11000, -7850)
	If PickUpIris() Then
		Return ReturnToAshfordAbbey()
	EndIf
	Moveto(-11200, -10500)
	If PickUpIris() Then
		Return ReturnToAshfordAbbey()
	EndIf
	Moveto(-10500, -13000)
	If PickUpIris() Then
		Return ReturnToAshfordAbbey()
	EndIf
	Return ReturnToAshfordAbbey()
EndFunc

;~ Loot only iris
Func PickUpIris()
	Local $lAgent
	Local $lItem
	Local $lDeadlock
	Local $success = True
	For $i = 1 To GetMaxAgents()
		$lAgent = GetAgentByID($i)
		If (DllStructGetData($lAgent, 'Type') <> 0x400) Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If (DllStructGetData(($lItem), 'ModelID') == $ID_Red_Iris_Flower) Then
			Out('Iris: ' & Round(DllStructGetData($lAgent, 'X')) & ', Y: ' & Round(DllStructGetData($lAgent, 'Y')))
			Local $loggingFile = FileOpen('logs/edeniris_farm.csv' , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
			FileWrite($loggingFile, Round(DllStructGetData($lAgent, 'X')) & ',' & Round(DllStructGetData($lAgent, 'Y')))
			PickUpItem($lItem)
			$lDeadlock = TimerInit()
			While GetAgentExists($i)
				RndSleep(500)
				If GetIsDead(-2) Then Return
				If TimerDiff($lDeadlock) > 20000 Then
					Out('Could not get iris at ' & DllStructGetData($lAgent, 'X') & ', ' & DllStructGetData($lAgent, 'Y'))
					$success = False
					ExitLoop
				EndIf
			WEnd
			If $success Then
				FileWrite($loggingFile, ',1' & @CRLF)
			Else
				FileWrite($loggingFile, ',0' & @CRLF)
			EndIf
			FileClose($loggingFile)
			Return True
		EndIf
	Next
	Return False
EndFunc

;~ Return to Ashford Abbey
Func ReturnToAshfordAbbey()
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
EndFunc