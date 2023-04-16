Screenchecks:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "image_folder")
{
	If !FileExist("img\Recognition ("poe_height "p)\GUI\")
	{
		LLK_ToolTip("the folder does not exist", 2)
		Return
	}
	Run, explore img\Recognition (%poe_height%p)\GUI\
	Return
}
If (A_GuiControl = "enable_pixelchecks")
{
	IniWrite, %enable_pixelchecks%, ini\config.ini, Settings, background pixel-checks
	gamescreen := (enable_pixelchecks = 0) ? 0 : gamescreen
	clone_frames_pixelcheck_enable := enable_pixelchecks
	IniWrite, % enable_pixelchecks, ini\clone frames.ini, Settings, enable pixel-check
	map_info_pixelcheck_enable := enable_pixelchecks
	IniWrite, % enable_pixelchecks, ini\map info.ini, Settings, enable pixel-check
	Return
}
If (A_GuiControl = "enable_blackbar_compensation")
{
	If enable_blackbar_compensation
	{
		pixel_gamescreen_offset := Format("{:0.0f}", (poe_width_initial - (poe_height_initial / (5/12))) / 2)
		;scan-method (proof-of-concept, not required right now) in case something changes in the future: measures the width of black bars on uber-UltraWide resolutions, instead of calculating it
		/*
		pHaystack_blackbars := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
		Loop, % Gdip_GetImageHeight(pHaystack_blackbars)
		{
			If (A_Index = 1)
				black_bars_widths := ""
			black_bars_x := 0
			ToolTip, % "scanning: " A_Index "/" poe_height
			While (Gdip_GetPixelColor(pHaystack_blackbars, black_bars_x , A_Index - 1, 3) = "0x000000")
				black_bars_x += 1
			black_bars_widths .= black_bars_x ","
		}
		Loop, Parse, black_bars_widths, `,
		{
			If (A_LoopField = "")
				continue
			If (LLK_SubStrCount(black_bars_widths, A_LoopField, ",", 1) >= poe_height/2)
			{
				pixel_gamescreen_offset := A_LoopField
				break
			}
		}
		If (pixel_gamescreen_offset = "")
		{
			MsgBox, Scan inconclusive. Please try again and make sure to follow the instructions closely.
			enable_blackbar_compensation := 0
			GuiControl, settings_menu:, enable_blackbar_compensation, 0
			Gdip_DisposeImage(pHaystack_blackbars)
			ToolTip
			Return
		}
		*/
		IniWrite, % pixel_gamescreen_offset, ini\config.ini, Settings, gamescreen-check offset
		;Gdip_DisposeImage(pHaystack_blackbars)
	}
	IniWrite, % enable_blackbar_compensation, ini\config.ini, Settings, black-bar compensation
	IniWrite, % settings_menu_section, ini\config.ini, Versions, reload settings
	;ToolTip
	Reload
	ExitApp
	Return
}

If InStr(A_GuiControl, "_calibrate")
{
	If InStr(A_GuiControl, "_pixel")
	{
		parse := StrReplace(A_GuiControl, "_pixel_calibrate")
		LLK_PixelRecalibrate(StrReplace(A_GuiControl, "_pixel_calibrate"))
		;GoSub, Settings_menu
		;sleep, 100
		;While !WinExist("ahk_id " hwnd_settings_menu)
		;	sleep, 100
		LLK_ToolTip("success")
		GuiControl, settings_menu: +cWhite, %parse%_help
		GuiControl, settings_menu: movedraw, %parse%_help
		LLK_ScreenChecksValid()
	}
	Else
	{
		Clipboard := ""
		KeyWait, LButton
		gui_force_hide := 1
		SendInput, #+{s}
		WinWaitNotActive, ahk_group poe_window
		Sleep, 1000
		WinWaitActive, ahk_group poe_ahk_window
		pClipboard := Gdip_CreateBitmapFromClipboard()
		If (pClipboard < 0)
		{
			gui_force_hide := 0
			While !WinExist("ahk_id " hwnd_settings_menu)
				sleep, 10
			LLK_ToolTip("screen-cap failed")
			Return
		}
		Else
		{
			imagecheck_parse := StrReplace(A_GuiControl, "_image_calibrate")
			Gdip_SaveBitmapToFile(pClipboard, "img\Recognition (" poe_height "p)\GUI\" imagecheck_parse ".bmp", 100)
			imagechecks_coords_%imagecheck_parse% := ""
			IniWrite, % "", ini\screen checks (%poe_height%p).ini, % imagecheck_parse, last coordinates
			Gdip_DisposeImage(pClipboard)
			If (imagecheck_parse != "betrayal")
				GuiControl, settings_menu: +cRed, imagecheck_help_%imagecheck_parse%
			Else GuiControl, settings_menu: +cWhite, imagecheck_help_%imagecheck_parse% ;betrayal doesn't explicitly need a test since it doesn't have fixed coordinates (i.e. the presence of a screen-capped image is sufficient)
			GuiControl, settings_menu: movedraw, imagecheck_help_%imagecheck_parse%
			LLK_ScreenChecksValid()
		}
		gui_force_hide := 0
	}
	Return
}
Else
{
	If InStr(A_GuiControl, "_pixel")
	{
		parse := StrReplace(A_GuiControl, "_pixel_test")
		If LLK_PixelSearch(parse)
			LLK_ToolTip("test positive")
		Else LLK_ToolTip("test negative")
	}
	Else
	{
		If (LLK_ImageSearch(StrReplace(A_GuiControl, "_image_test")) > 0)
		{
			LLK_ToolTip("test positive")
			GuiControl, settings_menu: +cWhite, % "imagecheck_help_" StrReplace(A_GuiControl, "_image_test")
			GuiControl, settings_menu: movedraw, % "imagecheck_help_" StrReplace(A_GuiControl, "_image_test")
			LLK_ScreenChecksValid()
		}
		Else LLK_ToolTip("test negative")
	}
}
Return

Init_screenchecks:
pixelchecks_enabled := "gamescreen,inventory", pixelchecks_list := "gamescreen,inventory", gamescreen := 0

Loop, Parse, imagechecks_list_copy, `,, `,
{
	IniRead, imagechecks_coords_%A_LoopField%, ini\screen checks (%poe_height%p).ini, %A_LoopField%, last coordinates, % A_Space
	imagecheck_%A_LoopField%_missing := !FileExist("img\Recognition ("poe_height "p)\GUI\"A_LoopField ".bmp") ! ? 1 : 0
}

IniRead, pixel_gamescreen_x1, data\Resolutions.ini, %poe_height%p, gamescreen x-coordinate 1, % A_Space
IniRead, pixel_gamescreen_y1, data\Resolutions.ini, %poe_height%p, gamescreen y-coordinate 1, % A_Space
IniRead, pixel_gamescreen_color1, ini\screen checks (%poe_height%p).ini, gamescreen, color 1, % A_Space

Loop 3
	IniRead, pixel_inventory_color%A_Index%, ini\screen checks (%poe_height%p).ini, inventory, color %A_Index%, %A_Space%

IniRead, enable_blackbar_compensation, ini\config.ini, Settings, black-bar compensation, 0
IniRead, pixel_gamescreen_offset, ini\config.ini, Settings, gamescreen-check offset, 0
enable_blackbar_compensation := (poe_height_initial / poe_width_initial < (5/12)) ? enable_blackbar_compensation : 0

If enable_blackbar_compensation && (pixel_gamescreen_offset != 0)
{
	xScreenOffSet := xScreenOffSet_initial + pixel_gamescreen_offset
	poe_width := poe_width_initial - pixel_gamescreen_offset*2
}

If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
	clone_frames_pixelcheck_enable := 0
Return

LLK_ImageSearch(name := "")
{
	global
	Loop, Parse, imagechecks_list, `,, %A_Space%
		%A_Loopfield% := 0
	pHaystack_ImageSearch := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop, Parse, % (name = "") ? imagechecks_list : name, `,, %A_Space%
	{
		If (settings_enable_%A_LoopField% = 0) || (A_LoopField = "skilltree" && !settings_enable_levelingtracker) || (A_LoopField = "stash" && (!settings_enable_maptracker || !enable_loottracker))
			continue
		If (A_Gui = "settings_menu") && (A_LoopField != "betrayal")
			imagesearch_x1 := 0, imagesearch_y1 := 0, imagesearch_x2 := 0, imagesearch_y2 := 0
		Else If (A_LoopField = "betrayal")
			imagesearch_x1 := 0, imagesearch_y1 := 0, imagesearch_x2 := poe_width/2, imagesearch_y2 := poe_height/8
			;imagesearch_x1 := enable_blackbar_compensation ? pixel_gamescreen_offset : 0, imagesearch_y1 := 0, imagesearch_x2 := enable_blackbar_compensation ? poe_width*(3/16) + pixel_gamescreen_offset : poe_width*(3/16), imagesearch_y2 := poe_height/8
		Else If !imagechecks_coords_%A_LoopField%
			continue
		Else
		{
			Loop, Parse, imagechecks_coords_%A_LoopField%, `,
			{
				Switch A_Index
				{
					Case 1:
						imagesearch_x1 := A_LoopField
					Case 2:
						imagesearch_y1 := A_LoopField
					Case 3:
						imagesearch_x2 := A_LoopField
					Case 4:
						imagesearch_y2 := A_LoopField
				}
			}
		}
		
		If !FileExist("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp")
			continue
		pNeedle_ImageSearch := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp")
		If (Gdip_ImageSearch(pHaystack_ImageSearch, pNeedle_ImageSearch, LIST, imagesearch_x1, imagesearch_y1, imagesearch_x2, imagesearch_y2, imagesearch_variation,, 1, 1) > 0)
		{
			%A_Loopfield% := 1
			If (A_LoopField != "betrayal") && !InStr(imagechecks_coords_%A_LoopField%, LIST)
			{
				Gdip_GetImageDimension(pNeedle_ImageSearch, width, height)
				imagechecks_coords_%A_LoopField% := LIST "," SubStr(LIST, 1, InStr(LIST, ",") - 1) + Format("{:0.0f}", width) "," SubStr(LIST, InStr(LIST, ",") + 1) + Format("{:0.0f}", height) ;SubStr(imagechecks_coords_%A_LoopField%, InStr(imagechecks_coords_%A_LoopField%, ",",,, 2) + 1)
				IniWrite, % imagechecks_coords_%A_LoopField%, ini\screen checks (%poe_height%p).ini, %A_LoopField%, last coordinates
			}
			Gdip_DisposeImage(pNeedle_ImageSearch)
			Gdip_DisposeImage(pHaystack_ImageSearch)
			Return 1
		}
		Else Gdip_DisposeImage(pNeedle_ImageSearch)
	}
	Gdip_DisposeImage(pHaystack_ImageSearch)
	Return 0
}

LLK_PixelRecalibrate(name)
{
	global
	Switch name
	{
		Case "gamescreen":
			loopcount := 1
		Case "inventory":
			loopcount := 3
	}
	Loop %loopcount%
	{
		PixelGetColor, pixel_%name%_color%A_Index%, % xScreenOffset + poe_width - 1 - pixel_%name%_x%A_Index%, % yScreenOffset + pixel_%name%_y%A_Index%, RGB
		IniWrite, % pixel_%name%_color%A_Index%, ini\screen checks (%poe_height%p).ini, %name%, color %A_Index%
	}
}

LLK_PixelSearch(name)
{
	global
	local loopcount, pixel_check := 1
	Switch name
	{
		Case "gamescreen":
			loopcount := 1
		Case "inventory":
			loopcount := 3
	}
	
	Loop %loopcount%
	{
		If (pixel_%name%_color%A_Index% = "ERROR") || (pixel_%name%_color%A_Index% = "")
		{
			pixel_check := 0
			break
		}
		PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + poe_width - 1 - pixel_%name%_x%A_Index%, yScreenOffSet + pixel_%name%_y%A_Index%, xScreenOffSet + poe_width - 1 - pixel_%name%_x%A_Index%, yScreenOffSet + pixel_%name%_y%A_Index%, % pixel_%name%_color%A_Index%, %pixelsearch_variation%, Fast RGB
		pixel_check -= ErrorLevel
		If !pixel_check
			break
	}
	%name% := pixel_check ? 1 : 0 ;global variable that is checked in MainLoop
	Return (%name%)
}