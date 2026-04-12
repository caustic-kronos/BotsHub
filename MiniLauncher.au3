#RequireAdmin
#NoTrayIcon

Opt('MustDeclareVars', True)

#include-once
#include <GUIConstantsEx.au3>

Global Const $GLOBAL_GUI_WIDTH = 200
Global Const $GLOBAL_GUI_HEIGHT = 100

Local $guiHandle = GUICreate('Launcher', $GLOBAL_GUI_WIDTH, $GLOBAL_GUI_HEIGHT)
Local $labelHandle = GUICtrlCreateLabel('Master heartbeat: 0', 40, 20, 120, 30)
Local $infoHandle = GUICtrlCreateLabel('Info', 40, 40, 200, 30)
Local $buttonHandle = GUICtrlCreateButton('Start child.au3', 40, 60, 120, 30)

GUISetState(@SW_SHOW)

While True
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			Exit
		Case $buttonHandle
			Local $cmd = '"' & @AutoItExe & '" "' & @ScriptDir & '\BotsHub.au3" 0 0 "" Tests'
			MsgBox(0, 'Command', $cmd)
			Local $PID = Run($cmd)
			MsgBox(0, 'PID', $PID)
	EndSwitch
WEnd