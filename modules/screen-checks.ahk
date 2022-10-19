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