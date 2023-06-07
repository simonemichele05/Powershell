import winreg
import os
import shutil

file_path = r'C:\Users\Admin\Desktop\PowerShell\esegui_avvio.vbs'

startup_folder = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')

key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r'Software\Microsoft\Windows\CurrentVersion\Run', 0, winreg.KEY_SET_VALUE)
winreg.SetValueEx(key, 'Script di Avvio Personalizzato', 0, winreg.REG_SZ, file_path)
winreg.CloseKey(key)

script_name = os.path.basename(file_path)
startup_script_path = os.path.join(startup_folder, script_name)
shutil.copyfile(file_path, startup_script_path)