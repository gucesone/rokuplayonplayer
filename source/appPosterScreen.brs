'********************************************************************
'**  PlayOn Video Player Application - Poster Screen
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application -- Poster Screen
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'******************************************************


'******************************************************
'** Perform any startup/initialization stuff prior to 
'** initially showing the screen.  
'******************************************************
Function preShowPosterScreen(breadA=invalid, breadB=invalid) As Object

    if validateParam(breadA, "roString", "preShowPosterScreen", true) = false return -1
    if validateParam(breadB, "roString", "preShowPosterScreen", true) = false return -1

    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
		screen.SetBreadcrumbEnabled(true)
	else
		screen.SetBreadcrumbEnabled(false)
    end if

    screen.SetListStyle("flat-category")
	screen.SetListDisplayMode("scale-to-fit")
    return screen

End Function

Function reuseShowPosterScreen(screen, breadA=invalid, breadB=invalid) As Object

    if validateParam(screen, "roPosterScreen", "showPosterScreen") = false return -1
    if validateParam(breadA, "roString", "preShowPosterScreen", true) = false return -1
    if validateParam(breadB, "roString", "preShowPosterScreen", true) = false return -1

    port=CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
		screen.SetBreadcrumbEnabled(true)
	else
		screen.SetBreadcrumbEnabled(false)
    end if

    screen.SetListStyle("arced-landscape")
	screen.SetListDisplayMode("photo-fit")
    return screen

End Function

'******************************************************
'** Display the home screen and wait for events from 
'** the screen. The screen will show retreiving while
'** we fetch and parse the feeds for the game posters
'******************************************************
Function showPosterScreen(screen As Object, conn As Object, category As Object) As Integer

    if validateParam(screen, "roPosterScreen", "showPosterScreen") = false return -1
    if validateParam(conn, "roAssociativeArray", "showPosterScreen") = false return -1
    if validateParam(category, "roAssociativeArray", "showPosterScreen") = false return -1

	m.conn        = conn
    m.curShow     = 0

	screen.Show()
	
	category.Children = m.conn.ParseVideoFeed(category.Feed, false)
	if category.Children <> invalid and category.Children.Count() > 0 then
		screen.SetContentList(category.Children)

		while true
			msg = wait(0, screen.GetMessagePort())
			if type(msg) = "roPosterScreenEvent" then
				Dbg("showPosterScreen: msg = ", msg.GetMessage())
				Dbg("showPosterScreen: index = ", msg.GetIndex())
				if msg.isListItemSelected() then
					m.curShow = msg.GetIndex()
					Dbg("showPosterScreen: list item selected, current show = ", m.curShow)
					m.curShow = displaySelectedChild(category, m.curShow)
					screen.SetFocusedListItem(m.curShow)
				else if msg.isScreenClosed() then
					Dbg("showPosterScreen: Screen Closed")
					return -1
				end if
			end If
		end while
	else
		ShowErrorDialog("The selected folder contains no media items", "Folder Empty")
	end if

End Function

'**********************************************************
'** When a poster on the home screen is selected, we call
'** this function passing an associative array with the 
'** data for the selected show.  This data should be 
'** sufficient for the show detail 
'**********************************************************
Function displaySelectedChild(category as Object, showIndex As Integer) As Integer

    if validateParam(category, "roAssociativeArray", "displaySelectedChild") = false return -1
	
	child = category.Children[showIndex]

	if child <> invalid then
		if child.Type = "video" then
			screen = preShowDetailScreen(category.Title, child.Title)
			showIndex = showDetailScreen(screen, m.conn, category.Children, showIndex)
		else
			screen = preShowPosterScreen(category.Title, child.Title)
			showPosterScreen(screen, m.conn, child)
		endif
	endif
	
    return showIndex
End Function
