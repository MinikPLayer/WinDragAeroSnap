; Easy Window Dragging -- KDE style (based on the v1 script by Jonny) 
; https://www.autohotkey.com
; This script makes it much easier to move or resize a window: 1) Hold down
; the ALT key and LEFT-click anywhere inside a window to drag it to a new
; location; 2) Hold down ALT and RIGHT-click-drag anywhere inside a window
; to easily resize it; 3) Press ALT twice, but before releasing it the second
; time, left-click to minimize the window under the mouse cursor, right-click
; to maximize it, or middle-click to close it.

; The Double-Alt modifier is activated by pressing
; Alt twice, much like a double-click. Hold the second
; press down until you click.
;
; The shortcuts:
;  Alt + Left Button  : Drag to move a window.
;  Alt + Right Button : Drag to resize a window.
;  Double-Alt + Left Button   : Minimize a window.
;  Double-Alt + Right Button  : Maximize/Restore a window.
;  Double-Alt + Middle Button : Close a window.
;
; You can optionally release Alt after the first
; click rather than holding it down the whole time.

; This is the setting that runs smoothest on my
; system. Depending on your video card and cpu
; power, you may want to raise or lower this value.

#Requires AutoHotkey v2.0
#SingleInstance
Persistent

CoordMode "Mouse"
SetWinDelay 0

last_lbutton := A_TickCount
last_rbutton := A_TickCount
last_mbutton := A_TickCount

IsAdmin() {
    return A_IsAdmin
}

IsExe() {
    return A_IsCompiled
}

ExitFunc(*) {
    ExitApp()
}

IsInstalled(*) {
    ret := RunWait(A_WinDir '\System32\schtasks.exe /QUERY /TN "WinDrag"', , "Hide")
    return ret == 0
}

RunAsAdmin(param) {
    try {
        if IsExe()
            Run '*RunAs "' A_ScriptFullPath '" ' param
        else
            Run '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '" ' param
    }
    catch Error as e {
        MsgBox("Error: " e.Message)
    }
}

InstallFunc(*) {
    if IsInstalled() {
        ret := MsgBox("Task already installed. Do you want to reinstall?", "Install", 4 | 32)
        if ret == "No"
            return
    }
    
    if not IsAdmin() {
        RunAsAdmin('/I')
        return
    }

    target_path := A_ScriptFullPath
    if not IsExe() {
        target_path := A_AhkPath " " A_ScriptFullPath
    }
    target_path := '"' target_path '"'
    ret := RunWait(A_WinDir '\System32\schtasks.exe /CREATE /SC ONLOGON /TN "WinDrag" /DELAY 0000:05 /RL HIGHEST /F /TR ' target_path,, "Hide")
    if ret != 0 {
        MsgBox("Installation failed", "Install", 16)
    } else {
        is_installed := IsInstalled()
        if not is_installed {
            MsgBox("SCHTASKS completed, but task is not created.", "Install", 16)
        }
        else {
            MsgBox("Installation completed!", "Install", 64)
            InitTray() ; Recreate tray
        }
    }
}

UninstallFunc(*) {
    if not IsInstalled() {
        MsgBox("Task not installed", "Uninstall", 16)
        return
    }

    if not IsAdmin() {
        RunAsAdmin('/U')
        return
    }

    ret := RunWait(A_WinDir '\System32\schtasks.exe /DELETE /TN "WinDrag" /F', , "Hide")
    if ret != 0 {
        MsgBox("Uninstallation failed", "Uninstall", 16)
    } else {
        is_installed := IsInstalled()
        if is_installed {
            MsgBox("SCHTASKS completed, but task is not deleted.", "Uninstall", 16)
        }
        else {
            MsgBox("Uninstallation completed!", "Uninstall", 64)
            InitTray() ; Recreate tray
        }
    }
}

InitTray() {
    Tray := A_TrayMenu ; For convenience.
    Tray.Delete()
    if not IsExe() {
        Tray.AddStandard()
        Tray.Add()
    }

    if IsInstalled() {
        Tray.Add("Uninstall", UninstallFunc)
    }
    else {
        Tray.Add("Install", InstallFunc)
    }
    
    if IsExe() {
        Tray.Add("Exit", ExitFunc)
    }
}

Log(text){
	OutputDebug("AHK | " text)
}

IsDoubleClick(last) {
    current := A_TickCount
    Log("Current: " current ", Last: " last " | Diff: " (current - last))
    if (current - last < 400) {
        last := 0
        return true
    }

    return false
}

Init() {
    for n, param in A_Args {
        if param == "-install" or param == "--install" or param == "/install" or param == "/I" {
            InstallFunc()
        }
        else if param == "-uninstall" or param == "--uninstall" or param == "/uninstall" or param == "/U" {
            UninstallFunc()
        }
        else {
            MsgBox("Invalid switch " param, "Invalid switch", 16)
            ExitApp()
        }
    }

    InitTray()
}

LWin & LButton::
    {
        global last_lbutton

        last := last_lbutton
        last_lbutton := A_TickCount
        if IsDoubleClick(last)
        {
            last_lbutton := 0
            MouseGetPos ,, &KDE_id
            WinActivate KDE_id ; Activate the window.
            ; Toggle between maximized and restored state.
            if WinGetMinMax(KDE_id)
                WinRestore KDE_id
            Else
                WinMaximize KDE_id
            return
        }

        ; Get the initial mouse position and window id, and
        ; abort if the window is maximized.
        MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id
        ; if WinGetMinMax(KDE_id)
        ;     WinRestore KDE_id

        ; Get the initial window position.
        WinGetPos &KDE_WinX1, &KDE_WinY1,,, KDE_id

        Loop
        {
            if !GetKeyState("LButton", "P") ; Break if button has been released.
                break

            MouseGetPos &KDE_X2, &KDE_Y2 ; Get the current mouse position.
            KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
            KDE_Y2 -= KDE_Y1
            KDE_WinX2 := (KDE_WinX1 + KDE_X2) ; Apply this offset to the window position.
            KDE_WinY2 := (KDE_WinY1 + KDE_Y2)

            if KDE_X2 != 0 and KDE_Y2 != 0 {
                if WinGetMinMax(KDE_id)
                    WinRestore KDE_id

                WinActivate KDE_id ; Activate the window.
                WinMove KDE_WinX2, KDE_WinY2,,, KDE_id ; Move the window to the new position.
            }
        }
    }

LWin & RButton::
    {
        global last_rbutton

        last := last_rbutton
        last_rbutton := A_TickCount

        if IsDoubleClick(last)
        {
            last_rbutton := 0
            MouseGetPos ,, &KDE_id
            ; This message is mostly equivalent to WinMinimize,
            ; but it avoids a bug with PSPad.
            PostMessage 0x0112, 0xf020,,, KDE_id
            return
        }

        ; Get the initial mouse position and window id, and
        ; abort if the window is maximized.
        MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id
        if WinGetMinMax(KDE_id)
            return

        ; Get the initial window position and size.
        WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinW, &KDE_WinH, KDE_id
        ; Define the window region the mouse is currently in.
        ; The four regions are Up and Left, Up and Right, Down and Left, Down and Right.
        if (KDE_X1 < KDE_WinX1 + KDE_WinW / 2) {
            KDE_WinLeft := 1
        }
        else {
            KDE_WinLeft := -1
        }
        if (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2){
            KDE_WinUp := 1
        }
        else {
            KDE_WinUp := -1
        }

        Loop
        {
            if !GetKeyState("RButton", "P") ; Break if button has been released.
                break
            MouseGetPos &KDE_X2, &KDE_Y2 ; Get the current mouse position.
            ; Get the current window position and size.
            WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinW, &KDE_WinH, KDE_id
            KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
            KDE_Y2 -= KDE_Y1
            ; Then, act according to the defined region.
            WinMove KDE_WinX1 + (KDE_WinLeft+1)/2*KDE_X2 ; X of resized window
            , KDE_WinY1 + (KDE_WinUp+1)/2*KDE_Y2 ; Y of resized window
            , KDE_WinW - KDE_WinLeft *KDE_X2 ; W of resized window
            , KDE_WinH - KDE_WinUp *KDE_Y2 ; H of resized window
            , KDE_id
            KDE_X1 := (KDE_X2 + KDE_X1) ; Reset the initial position for the next iteration.
            KDE_Y1 := (KDE_Y2 + KDE_Y1)
        }
    }

    ; "Alt + MButton" may be simpler, but I like an extra measure of security for
    ; an operation like this.
LWin & MButton::
    {
        global last_mbutton

        last := last_mbutton
        last_mbutton := A_TickCount

        if IsDoubleClick(last)
        {
            last_mbutton := 0
            MouseGetPos ,, &KDE_id
            WinClose KDE_id
            return
        }
    }


Init()