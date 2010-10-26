'********************************************************************
'**  PlayOn Video Player Application - General Dialogs
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application - General Dialogs 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'******************************************************
'Show basic message dialog without buttons
'*******************************************************
Function ShowPleaseWait(title As dynamic, text As dynamic) As Object
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    port = CreateObject("roMessagePort")
    dialog = invalid

    'the OneLineDialog renders a single line of text better
    'than the MessageDialog.
    if text = ""
        dialog = CreateObject("roOneLineDialog")
    else
        dialog = CreateObject("roMessageDialog")
        dialog.SetText(text)
    endif

    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.ShowBusyAnimation()
    dialog.Show()
    return dialog
End Function

'******************************************************
'Show error dialog with OK button
'******************************************************
Sub ShowErrorDialog(text As dynamic, title=invalid as dynamic)
    if not isstr(text) text = "Unspecified error"
    if not isstr(title) title = ""
    ShowDialog1Button(title, text, "Done")
End Sub

'******************************************************
'Show 1 button dialog
'Return: nothing
'******************************************************
Sub ShowDialog1Button(title As dynamic, text As dynamic, but1 As String)
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    Dbg("ShowDialog1Button: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                Dbg("ShowDialog1Button: screen closed")
                return
            else if dlgMsg.isButtonPressed()
                Dbg("ShowDialog1Button: button pressed = ", dlgMsg.GetIndex())
                return
            endif
        endif
    end while
End Sub

'******************************************************
'Show 2 button dialog
'Return: 0=first button or screen closed, 1=second button
'******************************************************
Function ShowDialog2Buttons(title As dynamic, text As dynamic, but1 As String, but2 As String) As Integer
    if not isstr(title) title = ""
    if not isstr(text) text = ""

    Dbg("ShowDialog1Button: ", title + " - " + text)

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(0, but1)
    dialog.AddButton(1, but2)
    dialog.Show()

    while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
            if dlgMsg.isScreenClosed()
                Dbg("ShowDialog1Button: screen closed")
                dialog = invalid
                return 0
            else if dlgMsg.isButtonPressed()
                Dbg("ShowDialog1Button: button pressed = ", dlgMsg.GetIndex())
                dialog = invalid
                return dlgMsg.GetIndex()
            endif
        endif
    end while
End Function


'******************************************************
'Show a requires firmware update screen
'******************************************************
Sub showRequiresUpdateScreen()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("Roku software update required")
    screen.AddParagraph("In order to use the PlayOn channel, you must update the software on your Roku player to 2.6 or higher.  To update your software:")
    screen.AddParagraph("1.  Select " + chr(34) + "settings" + chr(34) + " from the Roku home screen.")
    screen.AddParagraph("2.  Select " + chr(34) + "player info." + chr(34))
    screen.AddParagraph("3.  Select " + chr(34) + "check for update." + chr(34))
    screen.AddParagraph("4.  Select " + chr(34) + "yes." + chr(34))
    screen.AddParagraph("5. Once your Roku player has finished updating to 2.6, you may use the PlayOn channel.") 
    screen.AddButton(1, "back")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                Dbg("showRequiresUpdateScreen: screen closed")
            else if msg.isButtonPressed()
                Dbg("showRequiresUpdateScreen: button pressed = ", msg.GetIndex())
            else
                Dbg("showRequiresUpdateScreen: unknown event = ", msg.GetType())
            endif
            exit while                
        endif
    end while
End Sub

Function showInfoScreen(buttonText As String)
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

	file = NewHttp("file://pkg:/manifest")
	rsp = file.GetToStringWithRetry()
	
	major = ExtractStrFromMatch(rsp, "major_version=(.+)\n", 1)
	minor = ExtractStrFromMatch(rsp, "minor_version=(.+)\n", 1)
	build = ExtractStrFromMatch(rsp, "build_version=(.+)\n", 1)
	
    screen.SetTitle("Information")
    screen.AddHeaderText("Software Version: " + major + "." + minor + "." + build)
    screen.AddParagraph("PlayOn is a software program that runs on your Windows PC, giving you access to a wide range of Internet content on your TV -- Hulu, Netflix, YouTube, Amazon VOD, and many others.  Go to www.playon.tv to download and install the PlayOn software on your Windows PC.")
    screen.AddParagraph("This Roku application provides direct access to PlayOn's popular media content through your television.")
    screen.AddButton(1, buttonText)
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
               Dbg("showInfoScreen: screen closed")
            else if msg.isButtonPressed()
                Dbg("showInfoScreen: button pressed = ", msg.GetIndex())
				
                if msg.GetIndex() = 1
					Dbg("showDetailScreen: Back button pressed")
					exit while
                endif
            else
                Dbg("showInfoScreen: unknown event = ", msg.GetType())
            endif
        endif
    end while
	
	return false
End Function
