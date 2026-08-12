Continue = 'Stop'
 = 'C:\Users\palle\Desktop\Godot_v4.4-stable_win64_console.exe'
 = 'C:\Users\palle\Documents\GitHub\AdaResearch'
 = 'C:\Users\palle\Documents\GitHub\AdaResearch\algorithms\tools\scene_warning_scan.log'
if (Test-Path ) { Remove-Item  }
 = Get-ChildItem -Path 'C:\Users\palle\Documents\GitHub\AdaResearch\algorithms' -Recurse -Filter *.tscn
foreach ( in ) {
     = .FullName.Substring(.Length + 1)
     =  -replace '\\','/'
     = .Split('/')
     = [System.IO.Path]::GetFileNameWithoutExtension(.Name)
     = False
    if ( -match '(_vr$|_VR$|VR$|Vr$)') {  = True }
    foreach ( in ) {
        if ( -match '(^vr$|^VR$)') {  = True; break }
    }
    if () { continue }
     = 'res://' + 
    Write-Host "Running "
     = &  --headless --quit --path   2>&1
     =  | Where-Object {
        ( -match 'WARNING' -or  -match 'ERROR') -and
        ( -notmatch 'OpenXR') -and
        ( -notmatch 'Attempt to register extension class') -and
        ( -notmatch 'AdaSceneManager') -and
        ( -notmatch 'GameManager') -and
        ( -notmatch 'Console:\s*\[') -and
        ( -notmatch 'MapProgressionManager') -and
        ( -notmatch 'SoundBankSingleton') -and
        ( -notmatch 'Singleton initialized')
    }
    if () {
        Add-Content  "===  ==="
         | ForEach-Object { Add-Content   }
        Add-Content  ""
    }
}
