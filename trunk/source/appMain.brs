'********************************************************************
'**  PlayOn Video Player Application - Main
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application - Main
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'********************************************************************


Sub Main()
    screenFacade = CreateObject("roPosterScreen")
    screenFacade.show()

    if not goodFirmwareVersion(2,6,0)
        showRequiresUpdateScreen()
        return
    endif
	
	boolStr = RegRead("FirstTimeInfo")
	if strtobool(boolStr) = false then
		showInfoScreen("Continue")
		RegWrite("FirstTimeInfo", "true")
	end if

    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    'prepare the screen for display and get ready to begin
    screen=preShowHomeScreen("", "")
	screen.show()
	
    if screen=invalid then
        Dbg("Main: unexpected error in preShowHomeScreen")
		ShowErrorDialog("Unable to initialize screen", "Fatal Error")
        return
    end if
	
    'set to go, time to get started
    showHomeScreen(screen)
	
    'exit the app gently so that the screen doesn't flash to black
    screenFacade.showMessage("")
    sleep(25)
End Sub


'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'** Theme attributes affect the branding of the application
'** and are artwork, colors and offsets specific to the app
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "38"
    theme.OverhangLogoSD  = "pkg:/images/PlayOn_logo_sd.png"

    theme.OverhangOffsetHD_X = "123"
    theme.OverhangOffsetHD_Y = "48"
    theme.OverhangLogoHD  = "pkg:/images/PlayOn_logo_hd.png"

    app.SetTheme(theme)

End Sub
