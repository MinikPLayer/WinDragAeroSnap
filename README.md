# WinDragAeroSnap
Simple AutoHotKey v2 script to drag and resize Windows using Win+Mouse with Aero Snap support.

## Usage
[Download](https://github.com/MinikPLayer/WinDrag/releases/latest) and run the latest executable file from the Releases section.
Script will automatically activate after running the executable.

## Available functionality
* **Win + LMB drag** - Move window.
  - When dragging a window to the screen edges Aero snap will be automatically activated. (W.I.P. - can be a little buggy).
* **Win + RMB drag** - Resize window.
* **Win + MMB double click** - Close window.
* **Win + LMB double click** - Maximize / Restore window.
* **Win + RMB double click** - Minimize window.

## Installation
After running the executable find it's tray icon. Right click -> Install will register the program on startup. 

**Warning** 

Install registers the current executable as a startup app. Moving the .exe to another location will stop the autostart from working. To reapply the installation rerun the Install function from the tray menu after copying the executable to a new location.


## Uninstallation
Select Uninstall from the tray menu.


## Current limitations
* Aero snap sometimes doesn't show window recomendations for the other half. It works fine for explorer, but doesn't work for other apps.
* Multi-monitor setup is not tested. Please post an issue if it's important for you.
* When run without admin rights app is not able to modify Admin windows (including Task Manager).

## To-Do
* Resize snapping to another windows and screen borders.
* Resizing when Aero Snapped doesn't resize another snapped windows.
