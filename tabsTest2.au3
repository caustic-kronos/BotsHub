#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#include <GUIScrollBars_Ex.au3>

Global $aChild[8], $aButton[8][5]

; Create GUI
$hGUI_Main = GUICreate("Test", 500, 500)

; Create tabs
$cTab = GUICtrlCreateTab(50, 30, 380, 300)
For $i = 0 To 7
    GUICtrlCreateTabItem("Tab " & $i)
Next
GUICtrlCreateTabItem("")

; Create child GUIs
For $i = 0 To 7
    $aChild[$i] = GUICreate("", 200, 150, 100, 100, $WS_POPUP, $WS_EX_MDICHILD, $hGUI_Main)
    GUISetBkColor(0xC4C4C4)

    ; Add controls
    For $j = 0 To 4
        $aButton[$i][$j] = GUICtrlCreateButton("Button " & $i & $j, 10, 10 + (50 * $j), 80, 30)
    Next

    ; Create scrollbars
    _GUIScrollBars_Generate($aChild[$i], 0, 240)

    GUISetState(@SW_HIDE, $aChild[0])
Next

; Show GUIs
GUISetState(@SW_SHOW, $aChild[0])
GUISetState(@SW_SHOW, $hGUI_Main)

; Set current tab value
$iLastTab = 0

While 1
    $nMsg = GUIGetMsg()

    If $nMsg Then ConsoleWrite($nMsg & @CRLF)

    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            Exit
        Case $cTab
            ; Check which tab is active
            $iCurrTab = GUICtrlRead($cTab)
            ; If the tab has changed
            If $iCurrTab <> $iLastTab Then
                ; Hide child GUIs
                GUISetState(@SW_HIDE, $aChild[$iLastTab])
                ; Show relevant GUI
                GUISetState(@SW_SHOW, $aChild[$iCurrTab])
                ; Set new current tab
                $iLastTab = $iCurrTab
            EndIf
        Case Else
            ; Look for a button
            For $i = 0 To 7
                For $j = 0 To 4
                    If $nMsg = $aButton[$i][$j] Then
                        MsgBox(0, "Pressed", "Button " & $i & $j)
                    EndIf
                Next
            Next
    EndSwitch
WEnd