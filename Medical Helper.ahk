global ScriptVersion, ScriptVersion = "1.0.0" ; Версия данного скрипта
global UrlServerInfo, UrlServerInfo = "https://raw.githubusercontent.com/ChandelureCosta/Medical-Helper-New/master/LST_Version.ini" ; Ссылка на файл с версией, ссылкой на файл, описанием, и лог изменений
FileCreateDir, %A_MyDocuments%\GTA San Andreas User Files\SAMP\Medical Helper
ScriptDir = %A_MyDocuments%\GTA San Andreas User Files\SAMP\Medical Helper

Utf8ToAnsi(ByRef Utf8String, CodePage = 1251)
{
    If (NumGet(Utf8String) & 0xFFFFFF) = 0xBFBBEF
        BOM = 3
    Else
        BOM = 0

    UniSize := DllCall("MultiByteToWideChar", "UInt", 65001, "UInt", 0
                    , "UInt", &Utf8String + BOM, "Int", -1
                    , "Int", 0, "Int", 0)
    VarSetCapacity(UniBuf, UniSize * 2)
    DllCall("MultiByteToWideChar", "UInt", 65001, "UInt", 0
                    , "UInt", &Utf8String + BOM, "Int", -1
                    , "UInt", &UniBuf, "Int", UniSize)

    AnsiSize := DllCall("WideCharToMultiByte", "UInt", CodePage, "UInt", 0
                    , "UInt", &UniBuf, "Int", -1
                    , "Int", 0, "Int", 0
                    , "Int", 0, "Int", 0)
    VarSetCapacity(AnsiString, AnsiSize)
    DllCall("WideCharToMultiByte", "UInt", CodePage, "UInt", 0
                    , "UInt", &UniBuf, "Int", -1
                    , "Str", AnsiString, "Int", AnsiSize
                    , "Int", 0, "Int", 0)
    Return AnsiString
}

ConnectedToInternet(flag=0x40) ; интернет коннектор статус сети
{
Return DllCall("Wininet.dll\InternetGetConnectedState", "Str", flag,"Int",0)
}

if ConnectedToInternet() ; есть подключение к сети
{
SplashTextOn, , 60, Менеджер обновлений, Проверка обновления`n------------------------`nОжидайте
Sleep, 1000
URLDownloadToFile, %UrlServerInfo%, %ScriptDir%/LST_Version.ini
FileRead, find404, %ScriptDir%/LST_Version.ini ; проверяем файл на строку 404
IfInString, find404, 404
{
    FileServer := False ; файл настроек не верный
}
else
{
    FileServer := True ; файл настроек верный
    IniRead, f_LastVersion, %ScriptDir%/LST_Version.ini, Script, Last_Version
    IniRead, f_LastDescription, %ScriptDir%/LST_Version.ini, Script, Last_Description
    IniRead, f_LastChangLog, %ScriptDir%/LST_Version.ini, Script, Last_Changlog
    If (f_LastChangLog != Null) ; если ссылка на файл лога не пуста
    {
  URLDownloadToFile, %f_LastChangLog%, %ScriptDir%/Chatlog.txt ; скачиваем файл лога
  FileRead, f_ChatlogText, %ScriptDir%/Chatlog.txt ; читаем файл лога
  conv_MsgChangLog := Utf8ToAnsi(f_ChatlogText) ; конвертируем кодировку
  If (conv_MsgChangLog == "ERROR") ; если файл пустой
  {
   FormChatLogLoad := ; записываем пустоту в форму
  }
  else
  {
   FormChatLogLoad := conv_MsgChangLog ; записываем текст с файла   в форму
  }
    }
}
if (FileServer == False) ; если в файле есть 404
{
    SplashTextOn, , 60, Менеджер обновлений, Ошибка подключения`n------------------------`nНет связи с сервером
    sleep, 2000
    SplashTextoff
    goto, Script
}
else if (f_LastVersion > ScriptVersion and f_LastVersion != Null) ; версия больше и последняя версия не равна пустоте
{
    SplashTextOn, , 60, Менеджер обновлений,  Ожидайте`n------------------------`nОбнаружена версия %f_LastVersion%
    sleep, 2000
    SplashTextoff
    IniRead, f_LastChangLog, %ScriptDir%/LST_Version.ini, Script, Last_Changlog
  ; удаляем иконку с формы
  Gui +LastFound
  DllCall("uxtheme\SetWindowThemeAttribute", "ptr", WinExist()
  , "int", 1, "int64*", 6 | 6<<32, "uint", 8)
  
  ; загружаем форму
  Gui, Update:Color, FFFFFF
  Gui, Update:-MinimizeBox
  Gui, Update:Add, TreeView, x240 y375 w240 h84, 
  Gui, Update:Add, Edit, x10 y10 w480 h240 ReadOnly, %FormChatLogLoad%
  Gui, Update:Add, Button, x90 y260 w125 h30 gUpdate, Обновить
  Gui, Update:Add, Button, x285 y260 w125 h30 gUpdateGuiClose, Отмена
  Gui, Update:Show, w500 h300, Доступно обновление %ScriptVersion% до %f_LastVersion%
  return
    }
}
else ; нет доступа к интернету
{
    MsgBox, 48, Менеджер обновлений, Доступ к интернету не обнаружен`n-----------------------------------------`n ;Проверьте своё интернет соединение
    goto, Script
}

; запускаем обновление по тыку кнопки обновить
Update:
IniRead, f_LastDownload, %ScriptDir%/LST_Version.ini, Script, Last_Download
IniRead, f_FileName, %ScriptDir%/LST_Version.ini, Script, Last_Name
msgbox, 1, Обновление до %f_LastVersion%, Хотите ли Вы обновиться?
IfMsgBox, OK
{
    SplashTextOn, , 60 ,Менеджер обновлений, Ожидайте`n------------------------`n ;Обновляем до %f_LastVersion%
    sleep, 1000
    SplashTextOn, , 60,Менеджер обновлений, Ожидайте`n------------------------`n ;Скачиваем обновление
    URLDownloadToFile, %f_LastDownload%, %ScriptDir%/%f_FileName%
    sleep, 1000
    SplashTextOn, , 60,Менеджер обновлений, Ожидайте`n------------------------`n ;Запускаем скрипт
    sleep, 3000
    run, %ScriptDir%/%f_FileName%
    ExitApp
  
}
IfMsgBox, CANCEL
{
    Gui, Update:Destroy ; удаляем форму обновления
    goto, Script
}
return

UpdateGuiClose:
Gui, Update:Destroy
goto, Script
return

; ваш скрипт
Script:
MsgBox, Скрипт МЕДИКЛА %ScriptVersion% запущен.2418124
ExitApp