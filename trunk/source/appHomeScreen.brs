'********************************************************************
'**  PlayOn Video Player Application - Home Screen
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application -- Home Screen
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'*****************************************************************


'******************************************************
'** Perform any startup/initialization stuff prior to 
'** initially showing the screen.  
'******************************************************
Function preShowHomeScreen(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "preShowHomeScreen", true) = false return -1
    if validateParam(breadA, "roString", "preShowHomeScreen", true) = false return -1
	
	m.TopNode = CreateObject("roArray", 100, true)
	
    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

    screen.SetListStyle("flat-category")
	screen.SetListDisplayMode("photo-fit")
    return screen

End Function


'******************************************************
'** Display the home screen and wait for events from 
'** the screen. The screen will show retreiving while
'** we find the servers and parse the feeds
'******************************************************
Function showHomeScreen(screen) As Integer

	boolStr = RegRead("AutoSelect")
	AutoSelectOn = strtobool(boolStr)

	boolStr = RegRead("ServerCache")
	ServerCacheOn = strtobool(boolStr)
	
	focusItem = 0

    if validateParam(screen, "roPosterScreen", "showHomeScreen") = false return -1

	serverListComplete = false

    if initTopLevelList(ServerCacheOn) then
		if m.conn.ServerCount(m.conn) > 0 then
			serverListComplete = true
		end if
	
		if serverListComplete = false then
			initTopLevelList(false)
		end if
	end if

	Dbg("showHomeScreen: server count = " + tostr(m.conn.ServerCount(m.conn)))
	if m.conn.ServerCount(m.conn) = 0 then
		Dbg("showHomeScreen: no PlayOn server, exit")
		showNoPlayOnPCScreen()
		'return -1
	else if AutoSelectOn = true then
		lastServerFound = false
		item = 0
		for each server in m.TopNode
			if server.IP = m.conn.LastServer()
				lastServerFound = true
				Dbg("showHomeScreen: located last PlayOn server, go directly to poster screen")
				focusItem = item
				displayCategoryPosterScreen(server)
			end if
			
			item = item + 1
		end for

		if m.conn.ServerCount(m.conn) = 1 and lastServerFound = false then
			Dbg("showHomeScreen: only one PlayOn server, go directly to poster screen")
			server = m.TopNode[0]
			if server.RenderFunction = invalid then
				focusItem = 0
				displayCategoryPosterScreen(server)
			end if
			'return 0
		end if
	end if
	
	screen.SetContentList(m.TopNode)
	screen.SetFocusedListItem(focusItem)

	while true
		msg = wait(0, screen.GetMessagePort())
		if type(msg) = "roPosterScreenEvent" then
			print "showHomeScreen | msg = "; msg.GetMessage() " | index = "; msg.GetIndex()
			if msg.isListFocused() then
				Dbg("showHomeScreen: list focused | index = ", msg.GetIndex())
				Dbg("showHomeScreen: category = ", m.curCategory)
			else if msg.isListItemSelected() then
				Dbg("showHomeScreen: list item selected, index = ", msg.GetIndex())
				category = m.TopNode[msg.GetIndex()]
				if category.RenderFunction <> invalid then
					if category.RenderFunction(category) = true then
						screen.SetContentList(m.TopNode)
						screen.SetFocusedListItem(0)
					end if
				else
					displayCategoryPosterScreen(category)
				end if
			else if msg.isScreenClosed() then
				Dbg("showPosterScreen: Screen Closed")
				return -1
			end if
		end If
	end while

    return 0

End Function


'**********************************************************
'** When a poster on the home screen is selected, we call
'** this function passing an associative array with the 
'** data for the selected show.  This data should be 
'** sufficient for the show detail (springboard) to display
'**********************************************************
Function displayCategoryPosterScreen(category As Object) As Boolean

    if validateParam(category, "roAssociativeArray", "displayCategoryPosterScreen") = false return -1

	m.conn.SetServerIP(category.IP)

    screen = preShowPosterScreen(category.Title, "")
    showPosterScreen(screen, m.conn, category)

    return false
End Function

'************************************************************
'** initialize the server list.
'************************************************************
Function initTopLevelList(fastLoad As Boolean) As Boolean

	waitobj = ShowPleaseWait("Finding Available PlayOn Computers", "     Initializing connection...")
    m.conn = InitServerConnections()

	if fastLoad = true then
		if m.conn.ServerList().Count() = 0  then
			fastLoad = false
		end if
	end if

	if fastLoad = true then
		m.TopNode = m.conn.LoadServerList(m.conn)
	else
		waitobj = ShowPleaseWait("Finding Available PlayOn Computers", "     Searching...")
		m.TopNode = m.conn.LoadServers(m.conn)
	end if
	
	'Add Settings Screen
	settings = init_container_item()
	settings.Title = "Settings"
	settings.ShortDescriptionLine1 = settings.Title
	settings.SDPosterUrl = "file://pkg:/images/icon-settings-sd.png"
	settings.HDPosterUrl = "file://pkg:/images/icon-settings-hd.png"
	settings.RenderFunction = appSettings
	m.TopNode.Push(settings)
	
	'Add Info Screen
	info = init_container_item()
	info.Title = "Information"
	info.ShortDescriptionLine1 = info.Title
	info.SDPosterUrl = "file://pkg:/images/icon-info-sd.png"
	info.HDPosterUrl = "file://pkg:/images/icon-info-hd.png"
	info.RenderFunction = showInfo
	m.TopNode.Push(info)
	
	return fastLoad
	
End Function

'******************************************************
'Show a cannot find computer running PlayOn screen
'******************************************************
Function showNoPlayOnPCScreen()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.AddHeaderText("Cannot find a computer running PlayOn")
    screen.AddParagraph("In order to use the PlayOn channel, you must have a computer running the PlayOn software.  To install PlayOn software:")
    screen.AddParagraph("1. Download and install the PlayOn software on your Windows PC from " + chr(34) + "www.playon.tv" + chr(34) + ".")
    screen.AddParagraph("2. Turn on your Roku device, select the PlayOn channel, and watch online content directly on your television.")
    screen.AddParagraph("Make sure your Roku device has a network connection to the same router that your PlayOn PC is connected to, and has the latest PlayOn software update installed.")
	screen.AddParagraph("For more information about upgrading your PlayOn software and network troubleshooting, see " + chr(34) + "www.playon.tv/support" + chr(34) + ".") 
    screen.AddButton(1, "back")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
               Dbg("showNoPlayOnPCScreen: screen closed")
            else if msg.isButtonPressed()
                Dbg("showNoPlayOnPCScreen: button pressed = ", msg.GetIndex())
            else
                Dbg("showNoPlayOnPCScreen: unknown event = ", msg.GetType())
            endif
            exit while                
        endif
    end while
End Function

'******************************************************
'Application Settings screen
'******************************************************
Function appSettings(info As Object) As Boolean

	boolStr = RegRead("AutoSelect")
	AutoSelectOn = strtobool(boolStr)

	boolStr = RegRead("ServerCache")
	ServerCacheOn = strtobool(boolStr)

	boolStr = RegRead("IncreasedBuffering")
	IncreasedBufferingOn = strtobool(boolStr)

    port = CreateObject("roMessagePort")
	
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    screen.SetTitle("Settings")
	
    screen.AddHeaderText("Application Settings")
    screen.AddParagraph("Use the buttons below to change your application settings.")

	if AutoSelectOn = true then
		screen.AddButton(1, "Turn Off Auto-Select")
	else
		screen.AddButton(1, "Turn On Auto-Select")
	end if

	if ServerCacheOn = true then
		screen.AddButton(2, "Turn Off Server Caching")
	else
		screen.AddButton(2, "Turn On Server Caching")
	end if

	if IncreasedBufferingOn = true then
		screen.AddButton(3, "Reduce Video Buffering")
	else
		screen.AddButton(3, "Increase Video Buffering")
	end if

    screen.AddButton(4, "Locate PlayOn Servers")
    screen.AddButton(5, "Restore Settings To Default")
    screen.AddButton(6, "Back")
    
	screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
               Dbg("appSettings: screen closed")
            else if msg.isButtonPressed()
                Dbg("appSettings: button pressed = ", msg.GetIndex())

                if msg.GetIndex() = 1
					Dbg("showDetailScreen: Auto-Select button pressed")
					if AutoSelectOn = true then
						AutoSelectOn = false
					else
						AutoSelectOn = true
					end if
					
					boolStr = tostr(AutoSelectOn)
					RegWrite("AutoSelect", boolStr)

					exit while
                end if

                if msg.GetIndex() = 2
					Dbg("showDetailScreen: Server Caching button pressed")
					if ServerCacheOn = true then
						ServerCacheOn = false
					else
						ServerCacheOn = true
					end if
					
					boolStr = tostr(ServerCacheOn)
					RegWrite("ServerCache", boolStr)
					
					exit while
                endif

                if msg.GetIndex() = 3
					Dbg("showDetailScreen: Video Buffering button pressed")
					if IncreasedBufferingOn = true then
						IncreasedBufferingOn = false
					else
						IncreasedBufferingOn = true
					end if
					
					boolStr = tostr(IncreasedBufferingOn)
					RegWrite("IncreasedBuffering", boolStr)
					
					exit while
                endif

                if msg.GetIndex() = 4
					Dbg("showDetailScreen: Find PlayOn Servers button pressed")
					initTopLevelList(false)
					RegDelete("LastServerSelected")
					return true
                endif
				
                if msg.GetIndex() = 5
					Dbg("showDetailScreen: Restore Settings button pressed")

					RegDelete("FirstTimeInfo")
					RegDelete("AutoSelect")
					RegDelete("ServerCache")
					RegDelete("IncreasedBuffering")
					RegDelete("LastServerSelected")
					RegDeleteSection("PlayOnServerList")

					ShowDialog1Button("", "Settings have been restored", "Done")
					return true
                endif
				
                if msg.GetIndex() = 6
					Dbg("showDetailScreen: Back button pressed")
					return false
                endif
            else
                Dbg("appSettings: unknown event = ", msg.GetType())
            endif
        endif
    end while

	ShowDialog1Button("", "Settings have been saved", "Done")
	
	return false
End Function

'******************************************************
'Show Info screen
'******************************************************
Function showInfo(info As Object) As Boolean

	showInfoScreen("Back")
	
	return false 

	End Function
