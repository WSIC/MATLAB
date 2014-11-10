AutoItSetOption("SendKeyDelay",15)
AutoItSetOption("SendKeyDownDelay",15)

Global $pause = False

HotKeySet("{PAUSE}","_pause")

For $i = 1 To 30
MouseClick("left",691,222); new recon
Sleep(1000)
MouseClick("left",223,201); operator
Sleep(400);
Send("{DOWN}{DOWN}{ENTER}"); jonathand
Sleep(100);
MouseClick("left",217,412); Isotope
Sleep(100)
Send("F{ENTER}"); fluorine
Sleep(100);
MouseClick("left",175,442); injected act
Sleep(100)
Send("1"); 1 mbq
Sleep(500)
MouseClick("left",397,597); Next
Sleep(1000)
MouseClick("left",409,207); Filepath
Send("+{HOME}");
Sleep(100)
Send("/home/visitor/ImgData/OriginalData/Jonathan_Disselhorst/Mouse2_Frames/Frame0" & StringFormat("%02i",$i) & ".lst")
Sleep(1000)
MouseClick("left",397,597); Next
Sleep(1000)
MouseClick("left",236,417); img dimensions
Sleep(400);
Send("{DOWN}{ENTER}"); 256 x 256
Sleep(500)
MouseClick("left",397,597); Next
Sleep(1000)
MouseClick("left",24,197); Click norm correction
Sleep(500)
MouseClick("left",293,257); Click Edit box.
Sleep(500)
Send("/home/visitor/ImgData/GUIPETReconExe/Norm/BPET_InMR_woCoil_Ge2012_36hrs_small.nrm")
Sleep(500)
MouseClick("left",397,597); Next
Sleep(1000)
MouseClick("left",397,597); Qeue it!
Sleep(2000)
Next



Func _pause()
    $pause = Not $pause
    If $pause Then
        While 1
            Sleep(100)
        Wend
    EndIf
EndFunc