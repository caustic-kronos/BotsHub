#include-once

#include "GWA2_ID.au3"

; TODO : once all modstructs have been identified, write them in GWA2_ID and replace them here

Func IsPerfectShield($aItem) 											; Need to add -5(20%)
	Local $ModStruct = GetModStruct($aItem)
	; Universal mods
	Local $Plus30 = StringInStr($ModStruct, "1E4823", 0, 1)				; Mod struct for +30 (shield only?)
	Local $Minus3Hex = StringInStr($ModStruct, "3009820", 0, 1)			; Mod struct for -3wHex (shield only?)
	Local $Minus2Stance = StringInStr($ModStruct, "200A820", 0, 1)		; Mod Struct for -2Stance
	Local $Minus2Ench = StringInStr($ModStruct, "2008820", 0, 1)		; Mod struct for -2Ench
	Local $Plus45Stance = StringInStr($ModStruct, "02D8823", 0, 1)		; For +45Stance
	Local $Plus45Ench = StringInStr($ModStruct, "02D6823", 0, 1)		; Mod struct for +40ench
	Local $Plus44Ench = StringInStr($ModStruct, "02C6823", 0, 1)		; For +44/+10Demons
	Local $Minus520 = StringInStr($ModStruct, "5147820", 0, 1)			; For -5(20%)
	; +1 20% Mods
	Local $PlusDomination = StringInStr($ModStruct, "0218240", 0, 1)	; +1 Dom 20%
	Local $PlusDivine = StringInStr($ModStruct, "1018240", 0, 1)		; +1 Divine 20%
	Local $PlusSmite = StringInStr($ModStruct, "0E18240", 0, 1)			; +1 Smite 20%
	Local $PlusHealing = StringInStr($ModStruct, "0D18240", 0, 1)		; +1 Heal 20%
	Local $PlusProt = StringInStr($ModStruct, "0F18240", 0, 1)			; +1 Prot 20%
	Local $PlusFire = StringInStr($ModStruct, "0A18240", 0, 1)			; +1 Fire 20%
	Local $PlusWater = StringInStr($ModStruct, "0B18240", 0, 1)			; +1 Water 20%
	Local $PlusAir = StringInStr($ModStruct, "0818240", 0, 1)			; +1 Air 20%
	Local $PlusEarth = StringInStr($ModStruct, "0918240", 0, 1)			; +1 Earth 20%
	Local $PlusDeath = StringInStr($ModStruct, "0518240", 0, 1)			; +1 Death 20%
	Local $PlusBlood = StringInStr($ModStruct, "0418240", 0, 1)			; +1 Blood 20%
	; +10vs Mods
	Local $PlusDemons = StringInStr($ModStruct, "A0848210", 0, 1)		; +10vs Demons
	Local $PlusPiercing = StringInStr($ModStruct, "A0118210", 0, 1)		; +10vs Piercing
	Local $PlusDragons = StringInStr($ModStruct, "A0948210", 0, 1)		; +10vs Dragons
	Local $PlusLightning = StringInStr($ModStruct, "A0418210", 0, 1)	; +10vs Lightning
	Local $PlusVsEarth = StringInStr($ModStruct, "A0B18210", 0, 1)		; +10vs Earth
	Local $PlusPlants = StringInStr($ModStruct, "A0348210", 0, 1)		; +10vs Plants
	Local $PlusCold = StringInStr($ModStruct, "A0318210", 0, 1)			; +10 vs Cold
	Local $PlusUndead = StringInStr($ModStruct, "A0048210", 0, 1)		; +10vs Undead
	Local $PlusSlashing = StringInStr($ModStruct, "A0218210", 0, 1)		; +10vs Slashing
	Local $PlusTengu = StringInStr($ModStruct, "A0748210", 0, 1)		; +10vs Tengu
	Local $PlusVsFire = StringInStr($ModStruct, "A0518210", 0, 1)		; +10vs Fire

	If $Plus30 > 0 Then
		If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
			Return True
		ElseIf $PlusDomination > 0 Or $PlusDivine > 0 Or $PlusSmite > 0 Or $PlusHealing > 0 Or $PlusProt > 0 Or $PlusFire > 0 Or $PlusWater > 0 Or $PlusAir > 0 Or $PlusEarth > 0 Or $PlusDeath > 0 Or $PlusBlood > 0 Then
			Return True
		ElseIf $Minus2Stance > 0 Or $Minus2Ench > 0 Or $Minus520 > 0 Or $Minus3Hex > 0 Then
			Return True
		Else
			Return False
		EndIf
	EndIf
	If $Plus45Ench > 0 Then
		If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
			Return True
		ElseIf $Minus2Ench > 0 Then
			Return True
		ElseIf $PlusDomination > 0 Or $PlusDivine > 0 Or $PlusSmite > 0 Or $PlusHealing > 0 Or $PlusProt > 0 Or $PlusFire > 0 Or $PlusWater > 0 Or $PlusAir > 0 Or $PlusEarth > 0 Or $PlusDeath > 0 Or $PlusBlood > 0 Then
			Return True
		Else
			Return False
		EndIf
	EndIf
	If $Minus2Ench > 0 Then
		If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
			Return True
		EndIf
	EndIf
	If $Plus44Ench > 0 Then
		If $PlusDemons > 0 Then
			Return True
		EndIf
	EndIf
	If $Plus45Stance > 0 Then
		If $Minus2Stance > 0 Then
			Return True
		EndIf
	EndIf
	Return False
EndFunc

Func IsPerfectStaff($aItem)
	Local $ModStruct = GetModStruct($aItem)
	Local $A = GetItemAttribute($aItem)
	; Ele mods
	Local $Fire20Casting = StringInStr($ModStruct, "0A141822", 0, 1)		; Mod struct for 20% fire
	Local $Water20Casting = StringInStr($ModStruct, "0B141822", 0, 1)		; Mod struct for 20% water
	Local $Air20Casting = StringInStr($ModStruct, "08141822", 0, 1)			; Mod struct for 20% air
	Local $Earth20Casting = StringInStr($ModStruct, "09141822", 0, 1)		; Mod struct for 20% earth
	Local $Energy20Casting = StringInStr($ModStruct, "0C141822", 0, 1)		; Mod struct for 20% energy storage
	; Monk mods
	Local $Smite20Casting = StringInStr($ModStruct, "0E141822", 0, 1)		; Mod struct for 20% smite
	Local $Divine20Casting = StringInStr($ModStruct, "10141822", 0, 1)		; Mod struct for 20% divine
	Local $Healing20Casting = StringInStr($ModStruct, "0D141822", 0, 1)		; Mod struct for 20% healing
	Local $Protection20Casting = StringInStr($ModStruct, "0F141822", 0, 1)	; Mod struct for 20% protection
	; Rit mods
	Local $Channeling20Casting = StringInStr($ModStruct, "22141822", 0, 1)	; Mod struct for 20% channeling
	Local $Restoration20Casting = StringInStr($ModStruct, "21141822", 0, 1)	; Mod struct for 20% restoration
	; Mes mods
	Local $Domination20Casting = StringInStr($ModStruct, "02141822", 0, 1)	; Mod struct for 20% domination
	; Necro mods
	Local $Death20Casting = StringInStr($ModStruct, "05141822", 0, 1)		; Mod struct for 20% death
	Local $Blood20Casting = StringInStr($ModStruct, "04141822", 0, 1)		; Mod struct for 20% blood

	Switch $A
	Case 2; Domination
		If $Domination20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 4; Blood
		If $Blood20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 5; Death
		If $Death20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 8; Air
		If $Air20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 9; Earth
		If $Earth20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 10; Fire
		If $Fire20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 11; Water
		If $Water20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 12; Energy Storage
		If $Air20Casting > 0 Or $Earth20Casting > 0 Or $Fire20Casting > 0 Or $Water20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 13; Healing
		If $Healing20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 14; Smiting
		If $Smite20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 15; Protection
		If $Protection20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 16; Divine
		If $Healing20Casting > 0 Or $Protection20Casting > 0 Or $Divine20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 33; Restoration
		If $Restoration20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	Case 34; Channeling
		If $Channeling20Casting > 0 Then
			Return True
		Else
			Return False
		EndIf
	EndSwitch
	Return False
EndFunc

Func IsPerfectCaster($aItem)
	Local $ModStruct = GetModStruct($aItem)
	Local $A = GetItemAttribute($aItem)
	; Universal mods
	Local $PlusFive = StringInStr($ModStruct, "5320823", 0, 1)				; Mod struct for +5^50
	Local $PlusFiveEnch = StringInStr($ModStruct, "500F822", 0, 1)			; Mod struct for +5^enchantment
	Local $10Cast = StringInStr($ModStruct, "A0822", 0, 1)					; Mod struct for 10% cast
	Local $10Recharge = StringInStr($ModStruct, "AA823", 0, 1)				; Mod struct for 10% recharge
	; Ele mods
	Local $Fire20Casting = StringInStr($ModStruct, "0A141822", 0, 1)		; Mod struct for 20% fire
	Local $Fire20Recharge = StringInStr($ModStruct, "0A149823", 0, 1)
	Local $Water20Casting = StringInStr($ModStruct, "0B141822", 0, 1)		; Mod struct for 20% water
	Local $Water20Recharge = StringInStr($ModStruct, "0B149823", 0, 1)
	Local $Air20Casting = StringInStr($ModStruct, "08141822", 0, 1)			; Mod struct for 20% air
	Local $Air20Recharge = StringInStr($ModStruct, "08149823", 0, 1)
	Local $Earth20Casting = StringInStr($ModStruct, "09141822", 0, 1)		; Mod struct for 20% earth
	Local $Earth20Recharge = StringInStr($ModStruct, "09149823", 0, 1)
	Local $Energy20Casting = StringInStr($ModStruct, "0C141822", 0, 1)		; Mod struct for 20% energy storage
	Local $Energy20Recharge = StringInStr($ModStruct, "0C149823", 0, 1)
	; Monk mods
	Local $Smiting20Casting = StringInStr($ModStruct, "0E141822", 0, 1)		; Mod struct for 20% smite
	Local $Smiting20Recharge = StringInStr($ModStruct, "0E149823", 0, 1)
	Local $Divine20Casting = StringInStr($ModStruct, "10141822", 0, 1)		; Mod struct for 20% divine
	Local $Divine20Recharge = StringInStr($ModStruct, "10149823", 0, 1)
	Local $Healing20Casting = StringInStr($ModStruct, "0D141822", 0, 1)		; Mod struct for 20% healing
	Local $Healing20Recharge = StringInStr($ModStruct, "0D149823", 0, 1)
	Local $Protection20Casting = StringInStr($ModStruct, "0F141822", 0, 1)	; Mod struct for 20% protection
	Local $Protection20Recharge = StringInStr($ModStruct, "0F149823", 0, 1)
	; Rit mods
	Local $Channeling20Casting = StringInStr($ModStruct, "22141822", 0, 1)	; Mod struct for 20% channeling
	Local $Channeling20Recharge = StringInStr($ModStruct, "22149823", 0, 1)
	Local $Restoration20Casting = StringInStr($ModStruct, "21141822", 0, 1)	; Mod struct for 20% restoration
	Local $Restoration20Recharge = StringInStr($ModStruct, "21149823", 0, 1)
	; Mes mods
	Local $Domination20Casting = StringInStr($ModStruct, "02141822", 0, 1)	; Mod struct for 20% domination
	Local $Domination20Recharge = StringInStr($ModStruct, "02149823", 0, 1)	; Mod struct for 20% domination recharge
	; Necro mods
	Local $Death20Casting = StringInStr($ModStruct, "05141822", 0, 1)		; Mod struct for 20% death
	Local $Death20Recharge = StringInStr($ModStruct, "05149823", 0, 1)
	Local $Blood20Recharge = StringInStr($ModStruct, "04149823", 0, 1)		; Mod struct for 20% blood
	Local $Blood20Casting = StringInStr($ModStruct, "04141822", 0, 1)

	Switch $A
	Case 2; Domination
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Domination20Casting > 0 Or $Domination20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Domination20Recharge > 0 Or $Domination20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Domination20Recharge > 0 Then
			If $Domination20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 4; Blood
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Blood20Casting > 0 Or $Blood20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Blood20Recharge > 0 Or $Blood20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Blood20Recharge > 0 Then
			If $Blood20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 5; Death
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Death20Casting > 0 Or $Death20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Death20Recharge > 0 Or $Death20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Death20Recharge > 0 Then
			If $Death20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 8; Air
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Air20Casting > 0 Or $Air20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Air20Recharge > 0 Or $Air20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Air20Recharge > 0 Then
			If $Air20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 9; Earth
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Earth20Casting > 0 Or $Earth20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Earth20Recharge > 0 Or $Earth20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Earth20Recharge > 0 Then
			If $Earth20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 10; Fire
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Fire20Casting > 0 Or $Fire20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Fire20Recharge > 0 Or $Fire20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Fire20Recharge > 0 Then
			If $Fire20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 11; Water
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Water20Casting > 0 Or $Water20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Water20Recharge > 0 Or $Water20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Water20Recharge > 0 Then
			If $Water20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 12; Energy Storage
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Energy20Casting > 0 Or $Energy20Recharge > 0 Or $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Energy20Recharge > 0 Or $Energy20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Or $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Energy20Recharge > 0 Then
			If $Energy20Casting > 0 Then
				Return True
			EndIf
		EndIf
		If $10Cast > 0 Or $10Recharge > 0 Then
			If $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 13; Healing
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Healing20Casting > 0 Or $Healing20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Healing20Recharge > 0 Or $Healing20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Healing20Recharge > 0 Then
			If $Healing20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 14; Smiting
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Smiting20Recharge > 0 Or $Smiting20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Smiting20Recharge > 0 Then
			If $Smiting20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 15; Protection
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Protection20Recharge > 0 Or $Protection20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Protection20Recharge > 0 Then
			If $Protection20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	Case 16; Divine
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Divine20Casting > 0 Or $Divine20Recharge > 0 Or $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Divine20Recharge > 0 Or $Divine20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Or $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Divine20Recharge > 0 Then
			If $Divine20Casting > 0 Then
				Return True
			EndIf
		EndIf
		If $10Cast > 0 Or $10Recharge > 0 Then
			If $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	; Restoration
	Case 33
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Restoration20Casting > 0 Or $Restoration20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Restoration20Recharge > 0 Or $Restoration20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Restoration20Recharge > 0 Then
			If $Restoration20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	; Channeling
	Case 34
		If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
			If $Channeling20Casting > 0 Or $Channeling20Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Channeling20Recharge > 0 Or $Channeling20Casting > 0 Then
			If $10Cast > 0 Or $10Recharge > 0 Then
				Return True
			EndIf
		EndIf
		If $Channeling20Recharge > 0 Then
			If $Channeling20Casting > 0 Then
				Return True
			EndIf
		EndIf
		Return False
	EndSwitch
	Return False
EndFunc

Func IsRareRune($aItem)
	Local $ModStruct = GetModStruct($aItem)
	Local $SupVigor = StringInStr($ModStruct, "C202EA27", 0, 1)					; Mod struct for Superior vigor rune
	Local $WindWalker = StringInStr($ModStruct, "040430A5060518A7", 0, 1)		; Windwalker insignia
	Local $MinorMyst = StringInStr($ModStruct, "05033025012CE821", 0, 1)		; Minor Mysticism
	Local $SupEarthPrayers = StringInStr($ModStruct, "32BE82109033025", 0, 1)	; Superior earth prayers
	Local $Prodigy = StringInStr($ModStruct, "C60330A5000528A7", 0, 1)			; Prodigy insignia
	Local $SupDom = StringInStr($ModStruct, "30250302E821770", 0, 1)			; Superior Domination
	Local $Shamans = StringInStr($ModStruct, "080430A50005F8A", 0, 1)			; Shamans insignia
	
	If $SupVigor > 0 Or $WindWalker > 0 Or $MinorMyst > 0 Or $SupEarthPrayers > 0 Or $Prodigy > 0 Or $SupDom > 0 Or $Shamans > 0 Then
		Return True
	Else
		Return False
	EndIf
EndFunc

Func IsSpecialItem($aItem)
	Local $ModelID = DllStructGetData($aItem, "ModelID")
	Local $ExtraID = DllStructGetData($aItem, "ExtraID")
	
	Switch $ModelID
		; Special - ToT etc
		Case $ID_UNKNOWN_CONSUMABLE_1, $ID_Victory_Token, $ID_Wintersday_Gift, $ID_Wayfarer_Mark, $ID_Lunar_Token, $ID_Lunar_Tokens, $ID_ToT
			Return True
		; Lockpicks
		Case $ID_Lockpick
			Return True
		; Glacial Stones
		Case $ID_Glacial_Stone
			Return True
		; All Tomes
		Case $ID_Assassin_EliteTome, $ID_Mesmer_EliteTome, $ID_Necromancer_EliteTome, $ID_Elementalist_EliteTome, $ID_Monk_EliteTome, $ID_Warrior_EliteTome, $ID_Ranger_EliteTome, $ID_Dervish_EliteTome, $ID_Ritualist_EliteTome, _
			$ID_Paragon_EliteTome, $ID_Assassin_Tome, $ID_Mesmer_Tome, $ID_Necromancer_Tome, $ID_Elementalist_Tome, $ID_Monk_Tome, $ID_Warrior_Tome, $ID_Ranger_Tome, $ID_Dervish_Tome, $ID_Ritualist_Tome, $ID_Paragon_Tome
			Return True
		; Black & White Dye
		Case $ID_Dyes
			If $ExtraID = $ID_Black_Dye Or $ExtraID = $ID_White_Dye Then
				Return True
			Else
				Return False
			EndIf
		; Chalice & Rin Relics
		Case $ID_Diessa_Chalice, $ID_Golden_Rin_Relic
			Return True
		; Superb Charr Carving
		Case $ID_Superb_Charr_Carving
			Return True
		; Dark Remains
		Case $ID_Dark_Remains
			Return True
		; Underworld & FOW Scroll
		Case $ID_Passage_Scroll_UW, $ID_Passage_Scroll_FoW
			Return True
		; Dragon Root
		Case $ID_Dragon_Root
			Return True
		; War supplies
		Case $ID_War_Supplies
			Return True
		; Commendations
		Case $ID_Ministerial_Commendation
			Return True
	EndSwitch
	Return False
EndFunc

Func IsReq8Max($aItem)
	Local $Req = GetItemReq($aItem)
	Local $Attribute = GetItemAttribute($aItem)
	Local $Rarity = GetRarity($aItem)
	Local $Dmg = GetItemMaxDmg($aItem)
	
	Switch $Rarity
		Case $RARITY_Gold
			If $Req = 8 Then
				If $Attribute = 20 Or $Attribute = 21 Or $Attribute = 17 Then
					If $Dmg = 22 Or $Dmg = 16 Then
						Return True
					EndIf
				EndIf
			EndIf
		Case $RARITY_Blue
			If $Req = 8 Then
				If $Attribute = 20 Or $Attribute = 21 Or $Attribute = 17 Then
					If $Dmg = 22 Or $Dmg = 16 Then
						Return True
					EndIf
				EndIf
			EndIf
		Case $RARITY_Purple
			If $Req = 8 Then
				If $Attribute = 20 Or $Attribute = 21 Or $Attribute = 17 Then
					If $Dmg = 22 Or $Dmg = 16 Then
						Return True
					EndIf
				EndIf
			EndIf
	EndSwitch
	Return False
EndFunc


Func IsNiceMod($aItem)
	Local $ModStruct = GetModStruct($aItem)
	Local $t         = DllStructGetData($aItem, "Type")
	
	Local $ArmorAlways = StringInStr($ModStruct, "05000821", 0 ,1); Armor +5
	If $ArmorAlways > 0 And ($t = 36) Then; 26 is Staff Head or Wrapping
		Return True
		Return False
	EndIf
	
	Local $FuriousPrefix = StringInStr($ModStruct, "0A00B823", 0 ,1); Axe haft, Dagger Tang, Hammer Haft, Scythe Snathe, Spearhead, Sword Hilt
	If $FuriousPrefix > 0 And ($t = 36) Then
		Return True
		Return False
	EndIf
	
	Local $HealthAlways = StringInStr($ModStruct, "001E4823", 0 ,1); +30 Health
	If $HealthAlways > 0 And ($t = 24 Or $t = 27 Or $t = 36) Then; 12 is focus core, 26 can be Staff Head or Wrap
		Return True
		Return False
	EndIf
	
	Local $ofEnchanting = StringInStr($ModStruct, "1400B822", 0 ,1); +20% Enchantment Duration
	If $ofEnchanting > 0 And ($t = 26 Or $t = 36) Then; 26 is Staff Wrapping
		Return True
		Return False
	EndIf


	;; +10 armor vs type
	; Local $NotTheFace = StringInStr($ModStruct, "0A0018A1", 0 ,1); Armor +10 (vs Blunt damage)
	;     If $NotTheFace > 0 Then
	;         Return True
	;         Return False
	; EndIf
	; Local $LeafOnTheWind = StringInStr($ModStruct, "0A0318A1", 0 ,1); Armor +10 (vs Cold damage)
	;     If $LeafOnTheWind > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $LikeARollingStone = StringInStr($ModStruct, "0A0B18A1", 0 ,1); Armor +10 (vs Earth damage)
	;     If $LikeARollingStone > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $SleepNowInTheFire = StringInStr($ModStruct, "0A0518A1", 0 ,1); Armor +10 (vs Fire damage)
	;     If $SleepNowInTheFire > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $RidersOnTheStorm = StringInStr($ModStruct, "0A0418A1", 0 ,1); Armor +10 (vs Lightning damage)
	;     If $RidersOnTheStorm > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $ThroughThickAndThin = StringInStr($ModStruct, "0A0118A1", 0 ,1); Armor +10 (vs Piercing damage)
	;     If $ThroughThickAndThin > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $TheRiddleOfSteel = StringInStr($ModStruct, "0A0218A1", 0 ,1); Armor +10 (vs Slashing damage)
	;     If $TheRiddleOfSteel > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	
	
	; reduce blind dazed cripple -33%
	; Local $ICanSeeClearlyNow = StringInStr($ModStruct, "00015828", 0 ,1); Reduces Blind duration on you by 20%
	;     If $ICanSeeClearlyNow > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $SwiftAsTheWind = StringInStr($ModStruct, "00035828", 0 ,1); Reduces Crippled duration on you by 20%
	;     If $SwiftAsTheWind > 0 Then
	;         Return True
	;         Return False
	;     EndIf
	; Local $SoundnessOfMind = StringInStr($ModStruct, "00075828", 0 ,1); Reduces Dazed duration on you by 20%
	;     If $SoundnessOfMind > 0 Then
	;         Return True
	;         Return False
	;     EndIf


	; 40/40 mods
	Local $HCT20 = StringInStr($ModStruct, "00140828", 0 ,1); Halves casting time of spells of item's attribute (Chance: 20%)
		If $HCT20 > 0 And ($t = 12 Or $t = 22 Or $t = 26) Then; 12 is Focus core of aptitude, 22 is Inscription Aptitude Not Attitude, 26 is Inscription or Adept Staff head
			Return True
			Return False
		EndIf
	
	Local $HSR20 = StringInStr($ModStruct, "00142828", 0, 1); Halves skill recharge of spells (Chance: 20%)
		If $HSR20 > 0 And ($t = 12 Or $t = 22) Then; 12 is Forget Me Not, 22 is Wand Wrapping of Memory
			Return True
			Return False
		EndIf
	
	Return False
EndFunc