'********************************************************************
'**  PlayOn Video Player Application - Detail Screen
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application - Detail Screen 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'***************************************************************
'** Perform any startup/initialization stuff prior to 
'** initially showing the screen.  
'***************************************************************
Function preShowDetailScreen(breadA=invalid, breadB=invalid) As Object
    port=CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if

	m.categoryTitle = breadA
	
	screen.SetPosterStyle("rounded-square-generic")
	
    return screen
End Function

'***************************************************************
'** The show detail screen (springboard) is where the user sees
'** the details for a show and is allowed to select a show to
'** begin playback.  This is the main event loop for that screen
'** and where we spend our time waiting until the user presses a
'** button and then we decide how best to handle the event.
'***************************************************************
Function showDetailScreen(screen As Object, conn As Object, showList As Object, showIndex as Integer) As Integer

    if validateParam(screen, "roSpringboardScreen", "showDetailScreen") = false return -1
    if validateParam(showList, "roArray", "showDetailScreen") = false return -1

	m.conn        = conn

    refreshShowDetail(screen, showList, showIndex)

    'remote key id's for left/right navigation
    remoteKeyLeft  = 4
    remoteKeyRight = 5
 
    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed()
                Dbg("showDetailScreen: Screen closed")
                exit while
            else if msg.isRemoteKeyPressed() 
                Dbg("showDetailScreen: Remote key pressed = ", msg.GetIndex())
                if msg.GetIndex() = remoteKeyLeft then
					Dbg("showDetailScreen: Left key pressed")
					showIndex = getPrevShow(showList, showIndex)
					if showIndex <> -1
						refreshShowDetail(screen, showList, showIndex)
					end if
                else if msg.GetIndex() = remoteKeyRight
					Dbg("showDetailScreen: Right key pressed")
                    showIndex = getNextShow(showList, showIndex)
					if showIndex <> -1
					   refreshShowDetail(screen, showList, showIndex)
					end if
                endif
            else if msg.isButtonPressed() 
                Dbg("showDetailScreen: Button pressed = ", msg.GetIndex())
				
				media = showList[showIndex].Media
				
                if msg.GetIndex() = 1
					Dbg("showDetailScreen: Play button pressed")
                    media.PlayStart = 0
                    showVideoScreen(media)
                endif

                if msg.GetIndex() = 3
					Dbg("showDetailScreen: Go Back button pressed")
					return showIndex
                endif
				
            end if
        else
            Dbg("showDetailScreen: Unexpected message class: " + type(msg))
        end if
    end while

    return showIndex

End Function

'**************************************************************
'** Refresh the contents of the show detail screen. This may be
'** required on initial entry to the screen or as the user moves
'** left/right on the springboard.  When the user is on the
'** springboard, we generally let them press left/right arrow keys
'** to navigate to the previous/next show in a circular manner.
'** When leaving the screen, the should be positioned on the 
'** corresponding item in the poster screen matching the current show
'**************************************************************
Function refreshShowDetail(screen As Object, showList As Object, showIndex as Integer) As Integer

    if validateParam(screen, "roSpringboardScreen", "refreshShowDetail") = false return -1
    if validateParam(showList, "roArray", "refreshShowDetail") = false return -1

    screen.ClearButtons()

    show = showList[showIndex]

    if show <> invalid and type(show) = "roAssociativeArray"
		if show.Media = invalid then
				show.Media = m.conn.ParseMediaItem(show)
		end if

		media = show.Media
		if media <> invalid then
			screen.PrefetchPoster(media.SDPosterUrl, media.HDPosterUrl)
			screen.SetContent(media)
			screen.SetBreadcrumbText(m.categoryTitle, media.Title)

			screen.AddButton(1, "Play")    
		end if
		
    end if

    screen.AddButton(3,"Go Back")

    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)

    screen.Show()

End Function

'********************************************************
'** Get the next item in the list and handle the wrap 
'** around case to implement a circular list for left/right 
'** navigation on the springboard screen
'********************************************************
Function getNextShow(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getNextShow") = false return -1

    nextIndex = showIndex + 1
    if nextIndex >= showList.Count() or nextIndex < 0 then
       nextIndex = 0 
    end if

	getnextlabel:

    show = showList[nextIndex]
    if validateParam(show, "roAssociativeArray", "getNextShow") = false return -1 

	'only select video types
	if show.Type <> "video" then
		nextIndex = nextIndex + 1
		if nextIndex >= showList.Count() or nextIndex < 0 then
		   nextIndex = 0 
		end if
		
		goto getnextlabel
	endif
	
    return nextIndex
End Function


'********************************************************
'** Get the previous item in the list and handle the wrap 
'** around case to implement a circular list for left/right 
'** navigation on the springboard screen
'********************************************************
Function getPrevShow(showList As Object, showIndex As Integer) As Integer
    if validateParam(showList, "roArray", "getPrevShow") = false return -1 

    prevIndex = showIndex - 1
    if prevIndex < 0 or prevIndex >= showList.Count() then
        if showList.Count() > 0 then
            prevIndex = showList.Count() - 1 
        else
            return -1
        end if
    end if

	getprevlabel:

    show = showList[prevIndex]
    if validateParam(show, "roAssociativeArray", "getPrevShow") = false return -1 
	
	'only select video types
	if show.Type <> "video" then
		prevIndex = prevIndex - 1
		if prevIndex < 0 or prevIndex >= showList.Count() then
			if showList.Count() > 0 then
				prevIndex = showList.Count() - 1 
			else
				return -1
			end if
		end if
		
		goto getprevlabel
	endif

    return prevIndex
End Function
