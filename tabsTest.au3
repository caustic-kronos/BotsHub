 #include <GUIConstantsEx.au3>
 #Include <GuiButton.au3>
 #include <GuiTab.au3>
 
 Global $hBuiltIn_Buttons[3]
 Global $hUDF_Buttons[3]
 
 $hGUI = GUICreate("Built-In Tab Example", 500, 500)
 
 $hTab = _GUICtrlTab_Create($hGUI, 10, 10, 480, 480)
 GUISetState()
 
 ; Add tabs
 _GUICtrlTab_InsertItem($hTab, 0, "Tab 0")
 _GUICtrlTab_InsertItem($hTab, 1, "Tab 1")
 _GUICtrlTab_InsertItem($hTab, 2, "Tab 2")
 
 ; Create the Built-in and UDF buttons
 For $i = 0 To 2
     $hBuiltIn_Buttons[$i] = GUICtrlCreateButton("Button " & $i, 20 + ($i * 100), 40 + ($i * 50), 80, 30)
     $hUDF_Buttons[$i] = _GUICtrlButton_Create($hGUI, "UDF " & $i, 20 + ($i * 100), 80 + ($i * 50),80, 30)
 Next
 
 ; Hide the controls so only the one on the first tab is visible
 GUICtrlSetState($hBuiltIn_Buttons[1], $GUI_HIDE)
 GUICtrlSetState($hBuiltIn_Buttons[2], $GUI_HIDE)
 ControlHide($hGUI, "", $hUDF_Buttons[1])
 ControlHide($hGUI, "", $hUDF_Buttons[2])
 
 GUISetState()
 
 ; This is the current active tab
 $iLastTab = 0
 
 While 1
     Switch GUIGetMsg()
         Case $GUI_EVENT_CLOSE
             Exit
     EndSwitch
 
     ; Check which Tab is active
     $iCurrTab = _GUICtrlTab_GetCurFocus($hTab)
     ; If the Tab has changed
     If $iCurrTab <> $iLastTab Then
         ; Store the value for future comparisons
         $iLastTab = $iCurrTab
         ; Show/Hide controls as required
         Switch $iCurrTab
             Case 0
                 GUICtrlSetState($hBuiltIn_Buttons[1], $GUI_HIDE)
                 GUICtrlSetState($hBuiltIn_Buttons[2], $GUI_HIDE)
                 GUICtrlSetState($hBuiltIn_Buttons[0], $GUI_SHOW)
                 ControlHide($hGUI, "", $hUDF_Buttons[1])
                 ControlHide($hGUI, "", $hUDF_Buttons[2])
                 ControlShow($hGUI, "", $hUDF_Buttons[0])
             Case 1
                 GUICtrlSetState($hBuiltIn_Buttons[0], $GUI_HIDE)
                 GUICtrlSetState($hBuiltIn_Buttons[2], $GUI_HIDE)
                 GUICtrlSetState($hBuiltIn_Buttons[1], $GUI_SHOW)
                 ControlHide($hGUI, "", $hUDF_Buttons[0])
                 ControlHide($hGUI, "", $hUDF_Buttons[2])
                 ControlShow($hGUI, "", $hUDF_Buttons[1])
            Case 2
                 GUICtrlSetState($hBuiltIn_Buttons[0], $GUI_HIDE)
                 GUICtrlSetState($hBuiltIn_Buttons[1], $GUI_HIDE)
                 GUICtrlSetState($hBuiltIn_Buttons[2], $GUI_SHOW)
                 ControlHide($hGUI, "", $hUDF_Buttons[0])
                 ControlHide($hGUI, "", $hUDF_Buttons[1])
                 ControlShow($hGUI, "", $hUDF_Buttons[2])
         EndSwitch
     EndIf
 WEnd