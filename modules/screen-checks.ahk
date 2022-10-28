Screenchecks:
If (click = 2)
{
	If InStr(A_GuiControl, "_pixel")
	{
		LLK_PixelRecalibrate(StrReplace(A_GuiControl, "_pixel"))
		GoSub, Settings_menu
		sleep, 100
		While !WinExist("ahk_id " hwnd_settings_menu)
			sleep, 100
		LLK_ToolTip("success")
	}
	Else
	{
		Clipboard := ""
		SendInput, #+{s}
		Sleep, 1000
		If WinExist("ahk_id " hwnd_settings_menu)
			WinWaitActive, ahk_id %hwnd_settings_menu%
		Else WinWaitActive, ahk_group poe_window
		If (Gdip_CreateBitmapFromClipboard() < 0)
		{
			LLK_ToolTip("screen-cap failed")
			Return
		}
		Else Gdip_SaveBitmapToFile(Gdip_CreateBitmapFromClipboard(), "img\Recognition (" poe_height "p)\GUI\" StrReplace(A_GuiControl, "_image") ".bmp", 100)
		GoSub, Settings_menu
	}
	Return
}
Else
{
	If InStr(A_GuiControl, "_pixel")
	{
		If LLK_PixelSearch(StrReplace(A_GuiControl, "_pixel"))
			LLK_ToolTip("test positive")
		Else LLK_ToolTip("test negative")
	}
	Else
	{
		If (LLK_ImageSearch(StrReplace(A_GuiControl, "_image")) > 0)
			LLK_ToolTip("test positive")
		Else LLK_ToolTip("test negative")
	}
}
Return

Screenchecks_gamescreen:
total_pixelcheck_enable := clone_frames_pixelcheck_enable + map_info_pixelcheck_enable
If (total_pixelcheck_enable = 0)
	pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
Else pixelchecks_enabled := InStr(pixelchecks_enabled, "gamescreen") ? pixelchecks_enabled : pixelchecks_enabled "gamescreen,"
Return

Screenchecks_settings_apply:
Gui, settings_menu: Submit, NoHide
If InStr(A_GuiControl, "disable_imagecheck")
{
	IniWrite, % %A_GuiControl%, ini\screen checks (%poe_height%p).ini, % StrReplace(A_GuiControl, "disable_imagecheck_"), disable
	FileDelete, % "img\Recognition (" poe_height "p)\GUI\" StrReplace(A_GuiControl, "disable_imagecheck_") ".bmp"
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "image_folder")
{
	Run, explore img\Recognition (%poe_height%p)\GUI\
	Return
}
If (A_GuiControl = "enable_pixelchecks")
	IniWrite, %enable_pixelchecks%, ini\config.ini, Settings, background pixel-checks
If (enable_pixelchecks = 0)
{
	gamescreen := 0
	clone_frames_pixelcheck_enable := 0
	IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
	map_info_pixelcheck_enable := 0
	IniWrite, 0, ini\map info.ini, Settings, enable pixel-check
}
Else
{
	clone_frames_pixelcheck_enable := 1
	IniWrite, 1, ini\clone frames.ini, Settings, enable pixel-check
	map_info_pixelcheck_enable := 1
	IniWrite, 1, ini\map info.ini, Settings, enable pixel-check
}
Return

Init_screenchecks:
Sort, pixelchecks_list, D`,
Loop, Parse, pixelchecks_list, `,, `,
	IniRead, disable_pixelcheck_%A_Loopfield%, ini\screen checks (%poe_height%p).ini, %A_Loopfield%, disable, 0


Sort, imagechecks_list, D`,
Loop, Parse, imagechecks_list, `,, `,
{
	IniRead, disable_imagecheck_%A_Loopfield%, ini\screen checks (%poe_height%p).ini, %A_Loopfield%, disable, 0
	IniRead, imagechecks_coords_%A_LoopField%, ini\screen checks (%poe_height%p).ini, %A_LoopField%, last coordinates, % imagechecks_coords_%A_LoopField%
}

IniRead, pixel_gamescreen_x1, data\Resolutions.ini, %poe_height%p, gamescreen x-coordinate 1
IniRead, pixel_gamescreen_y1, data\Resolutions.ini, %poe_height%p, gamescreen y-coordinate 1
IniRead, pixel_gamescreen_color1, ini\screen checks (%poe_height%p).ini, gamescreen, color 1

If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
{
	clone_frames_pixelcheck_enable := 0
	map_info_pixelcheck_enable := 0
	pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
}
Return

LLK_ImageSearch(name := "")
{
	global
	Loop, Parse, imagechecks_list, `,, `,
		%A_Loopfield% := 0
	pHaystack_ImageSearch := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop, Parse, % (name = "") ? imagechecks_list : name, `,
	{
		If (A_Gui = "settings_menu")
			imagesearch_x1 := 0, imagesearch_y1 := 0, imagesearch_x2 := 0, imagesearch_y2 := 0
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
			If !InStr(imagechecks_coords_%A_LoopField%, LIST)
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
	Return 0
	
	/*
	If (name = "")
	{
		Loop, Parse, imagechecks_list, `,, `,
		{
			imagesearch_x1 := 0
			imagesearch_y1 := 0
			imagesearch_x2 := 0
			imagesearch_y2 := 0
			If !FileExist("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp")
				continue
			If (A_Loopfield = "bestiary" || A_Loopfield = "gwennen" || A_Loopfield = "stash" || A_Loopfield = "vendor")
			{
				imagesearch_x2 := poe_width//2
				imagesearch_y2 := poe_height//2
			}
			Else If (A_Loopfield = "betrayal")
			{
				imagesearch_y1 := poe_height//2
				imagesearch_x2 := poe_width//2
			}
			pNeedle_ImageSearch := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp")
			If (Gdip_ImageSearch(pHaystack_ImageSearch, pNeedle_ImageSearch, LIST, imagesearch_x1, imagesearch_y1, imagesearch_x2, imagesearch_y2, imagesearch_variation,, 1, 1) > 0)
			{
				%A_Loopfield% := 1
				Gdip_DisposeImage(pNeedle_ImageSearch)
				ToolTip, % A_TickCount - start,,, 2
				break
			}
			Else Gdip_DisposeImage(pNeedle_ImageSearch)
		}
	}
	Else
	{
		imagesearch_x1 := 0
		imagesearch_y1 := 0
		imagesearch_x2 := 0
		imagesearch_y2 := 0
		If (name = "bestiary" || name = "gwennen" || name = "stash" || name = "vendor")
		{
			imagesearch_x2 := poe_width//2
			imagesearch_y2 := poe_height//2
		}
		Else If (name = "betrayal")
		{
			imagesearch_y1 := poe_height//2
			imagesearch_x2 := poe_width//2
		}
		pNeedle_ImageSearch := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\GUI\" name ".bmp")
		If (Gdip_ImageSearch(pHaystack_ImageSearch, pNeedle_ImageSearch, LIST, imagesearch_x1,imagesearch_y1, imagesearch_x2, imagesearch_y2, imagesearch_variation,, 1, 1) > 0)
		{
			Gdip_DisposeImage(pNeedle_ImageSearch)
			Gdip_DisposeImage(pHaystack_ImageSearch)
			Return 1
		}
		Else
		{
			Gdip_DisposeImage(pNeedle_ImageSearch)
			Gdip_DisposeImage(pHaystack_ImageSearch)
			Return 0
		}
	}
	Gdip_DisposeImage(pHaystack_ImageSearch)
	*/
}

LLK_PixelRecalibrate(name) ;needs (re)work in case more pixelchecks get integrated
{
	global
	loopcount := InStr(name, "gamescreen") ? 1 : 2
	Loop %loopcount%
	{
		If InStr(name, "gamescreen")
			PixelGetColor, pixel_%name%_color%A_Index%, % xScreenOffset + poe_width - pixel_%name%_x%A_Index%, % yScreenOffset + pixel_%name%_y%A_Index%, RGB
		Else PixelGetColor, pixel_%name%_color%A_Index%, % xScreenOffset + pixel_%name%_x%A_Index%, % yScreenoffset + pixel_%name%_y%A_Index%, RGB
		IniWrite, % pixel_%name%_color%A_Index%, ini\screen checks (%poe_height%p).ini, %name%, color %A_Index%
	}
}

LLK_PixelSearch(name)
{
	global
	If InStr(name, "gamescreen")
		PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + poe_width - pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, xScreenOffSet + poe_width - pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, pixel_%name%_color1, %pixelsearch_variation%, Fast RGB
	Else PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, xScreenOffSet + pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, pixel_%name%_color1, %pixelsearch_variation%, Fast RGB
	If (ErrorLevel = 0) && !InStr(name, "gamescreen")
		PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + pixel_%name%_x2, yScreenOffSet + pixel_%name%_y2, xScreenOffSet + pixel_%name%_x2, yScreenOffSet + pixel_%name%_y2, pixel_%name%_color2, %pixelsearch_variation%, Fast RGB
	%name% := (ErrorLevel=0) ? 1 : 0
	value_pixel := %name%
	Return value_pixel
}