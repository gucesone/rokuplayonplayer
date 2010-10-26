'********************************************************************
'**  PlayOn Video Player Application - PlayOnServer
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************


'******************************************************
' Set up the PlayOn server connections object
'******************************************************
Function InitServerConnections() As Object

    conn = CreateObject("roAssociativeArray")

    conn.UrlPlayOnPrefix   = "http://m.playon.tv"
    conn.UrlServerList = conn.UrlPlayOnPrefix + "/q.php?rid=" + itostr(RND(10000))

    conn.Timer = CreateObject("roTimespan")
	conn.IP = invalid
	conn.servers = CreateObject("roArray", 100, true)

    conn.LoadServers    = load_servers
    conn.LoadServerList = load_server_list
	conn.ServerCount    = server_count
	conn.SetServerIP    = set_server_ip
	conn.LastServer     = last_server_selected
	conn.ServerList     = server_list
	
	conn.ParseCatalogNode = parse_catalog_node
	conn.ParseVideoFeed = parse_video_feed
	conn.HasMediaItem    = has_media_item
	conn.ParseGroupNode = parse_group_node
	conn.ParseMediaItem = parse_media_item

    Dbg("InitServerConnections: created server connections for " + conn.UrlServerList)
    return conn

End Function


'******************************************************************
'** Set the IP of the PlayOn server that requests will be issued
'******************************************************************
Function set_server_ip(ip As Object) As Void

    Dbg("set_server_ip: Set IP = " + ip)
	m.IP = ip
	RegWrite("LastServerSelected", m.IP)

End Function

'******************************************************************
'** Return the last layOn server selected
'******************************************************************
Function last_server_selected() As String

	ip = RegRead("LastServerSelected")
	if ip = invalid then
		ip = "invalid"
	end if
	
	Dbg("last_server_selected: IP = " + ip)
	return ip

End Function

'******************************************************************
'** Return the number of servers found
'******************************************************************
Function server_count(conn As Object) As Integer
	count = 0
	for each server in conn.servers
		if server.IP <> invalid then
			count = count + 1
		end if
	end for
	
	return count

End Function

'******************************************************************
'** Returns the list of ip address from the last servers found
'******************************************************************
Function server_list() As Dynamic

	serverList = CreateObject("roArray", 100, true)

	sec = CreateObject("roRegistrySection", "PlayOnServerList")
	keys = sec.GetKeyList()
	for each key in keys
		val = sec.Read(key)
		serverList.push(val)
	end for

	return serverList

End Function

'******************************************************************
'** Given a connection object for the PlayOn server, fetch and
'** parse this top-level tree for all playon server found.
'******************************************************************
Function load_servers(conn As Object) As Dynamic

	RegDeleteSection("PlayOnServerList")
	
    http = NewHttp(conn.UrlServerList)
    Dbg("load_servers: url = ", http.Http.GetUrl())
	
	conn.servers.Clear()

    slist = http.GetToStringWithRetry()

	r = CreateObject("roRegex", "\|", "")
	list = r.Split(slist)
	
	waitobj = ShowPleaseWait("Finding Available PlayOn Computers", "     Testing Connections...")
	Dbg("load_servers: number of possible PlayOn servers = " + itostr((list.Count())))

	httpObjects=CreateObject("roArray", (list.Count()), true)
	httpEvents=CreateObject("roArray", (list.Count()), true)
	httpIPs=CreateObject("roArray", (list.Count()), true)
	
	serverCount = 0
	
	list.ResetIndex()
	serverip = list.GetIndex()
	while serverip <> invalid
		httpEvents[serverCount] = invalid
		httpIPs[serverCount] = invalid
		httpObjects[serverCount] = NewHttp(serverip + "/data/data.xml?id=0")

		' make sure there is no duplicate IPs, if so skip them (okay = false)
		for x = 0 to (list.Count()-1)
		
			if httpIPs[x] <> invalid and httpIPs[x] = serverip then
				Dbg("load_servers: skipping duplicate IP  = ", serverip)
				httpObjects[serverCount] = invalid
				exit for
			endif
			
		end for
		
		if httpObjects[serverCount] <> invalid
			Dbg("load_servers: requesting PlayOn data url = ", httpObjects[serverCount].Http.GetUrl())
			
			if (httpObjects[serverCount].Http.AsyncGetToString()) = true then
				httpEvents[serverCount] = httpObjects[serverCount].Http.GetPort()
				httpIPs[serverCount] = serverip
			
				serverCount = serverCount + 1
			else 
				Dbg("load_servers: request failed for PlayOn data url = ", httpObjects[serverCount].Http.GetUrl())
				httpObjects[serverCount] = invalid
			end if
		end if
		
		serverip = list.GetIndex()
	end while	

	foundCount = 0
	eventCount = 0

	m.Timer.Mark()
	while m.Timer.TotalMilliseconds() < 5000 and eventCount < serverCount

		for x = 0 to (list.Count()-1)

			if httpEvents[x] <> invalid
				event = wait(10, httpEvents[x])
				if type(event) = "roUrlEvent" then
				
					eventCount = eventCount + 1
					rsp = event.GetString()
					
					xml=CreateObject("roXMLElement")
					if xml.Parse(rsp) then
						
						m.IP = httpIPs[x]
						
						catalog = m.ParseCatalogNode(xml) 
						if catalog <> invalid then
							foundCount = foundCount + 1

							waitobj = ShowPleaseWait("Finding Available PlayOn Computers", "     Found " + foundCount.tostr() + " PlayOn Computer(s)")
							
							conn.servers.Push(catalog)
							Dbg("load_servers: adding valid catalog node")
							
							RegWrite(GetServerName(m.IP), m.IP, "PlayOnServerList")
						else
							Dbg("load_servers: no valid catalog node")
						endif
					else
						Dbg("load_servers: unable to parse XML")
					endif
					
					httpObjects[x] = invalid
					httpEvents[x] = invalid
					httpIPs[x] = invalid
					
				endif
			endif
			
		end for

	end while	

	for x = 0 to (list.Count()-1)

		if httpObjects[x] <> invalid
			Dbg("load_servers: cancel request to PlayOn data url = ", httpObjects[x].Http.GetUrl())
			httpObjects[x].Http.AsyncCancel()
			
			httpObjects[x] = invalid
			httpEvents[x] = invalid
			httpIPs[x] = invalid
		endif
		
	end for
	
	httpObjects.Clear()
	httpEvents.Clear()
	httpIPs.Clear()
	
    return conn.servers

End Function

'******************************************************************
'** Given a connection object for the PlayOn server, fetch and
'** parse the top-level tree for the last playon server selected.
'******************************************************************
Function load_server_list(conn As Object) As Dynamic

	conn.servers.Clear()

    serverList = conn.ServerList()

	if (serverList = invalid)
		return conn.servers
	end if
	
	for each serverIP in serverList
	
		http = NewHttp(serverIP + "/data/data.xml?id=0")

		Dbg("load_server_list: requesting PlayOn data url = ", http.Http.GetUrl())
					
		rsp = http.GetToStringWithRetry()

		xml=CreateObject("roXMLElement")
		if xml.Parse(rsp) then
			
			m.IP = serverIP
			
			catalog = m.ParseCatalogNode(xml) 
			if catalog <> invalid then
				waitobj = ShowPleaseWait("Finding Available PlayOn Computers", "     Found PlayOn Computer")
				
				conn.servers.Push(catalog)
				Dbg("load_server_list: adding valid catalog node")
			else
				Dbg("load_server_list: no valid catalog node")
			endif
		else
			Dbg("load_server_list: unable to parse XML")
		endif
		
	end for
	
    return conn.servers

End Function

'***********************************************************
'Retrieves and parses the name of the PlayOn server
'***********************************************************
Function GetServerName(ip As String) As String

	http = NewHttp(ip + "/js/search.js?id=1")
    Dbg("GetServerName: url = ", http.Http.GetUrl())
	
	rsp = http.GetToStringWithTimeout(3)
	
	serverName = ExtractStrFromMatch(rsp, "return (.+);", 1)
	if serverName.Len() > 2 then
		serverName = serverName.Mid(1, serverName.Len()-2)
	else 
		serverName = "Unknown"
	endif 

    Dbg("GetServerName: name = ", serverName)
    return serverName

End Function

'***********************************************************
'Given the xml element to an <Category> tag in the category
'feed, walk it and return the top level node to its tree
'***********************************************************
Function parse_catalog_node(xml As Object) As dynamic
	
    if xml.catalog = invalid then
        Dbg("parse_catalog_node: no catalog tag")
        return invalid
    endif

    if islist(xml.catalog) = false then
        Dbg("parse_catalog_node: invalid feed body")
        return invalid
    endif
	
	Dbg("parse_catalog_node: catalog = " + xml@name)

    catalog = init_container_item()
	catalog.Title = xml@name
	catalog.IP = m.IP
	catalog.Href = xml@href
	catalog.Feed = "http://" + m.IP + catalog.Href
	
	catalog.Children = CreateObject("roArray", 100, true)
	
	catalog.ContentId = ExtractStrFromMatch(catalog.Href, "id=(.+)",1)
	
	catalog.SDPosterUrl = "file://pkg:/images/PlayOn_category_sd.png"
	catalog.HDPosterUrl = "file://pkg:/images/PlayOn_category_hd.png"

	if xml.art <> invalid
		artUrl = xml@art
		if artUrl.Len() > 0 then
			catalog.SDPosterUrl = "http://" + m.IP + prepareURL(artUrl)
			catalog.HDPosterUrl = "http://" + m.IP + prepareURL(artUrl)
		endif
	endif

	catalog.ShortDescriptionLine1 = catalog.Title

	return catalog
End Function

'**************************************************************************
' parse feed, determine if group or media items
'**************************************************************************
Function parse_video_feed(feed As String, showWait As Boolean) As Object

    Dbg("parse_video_feed: Feed = " + feed)
	
	children  = CreateObject("roArray", 100, true)

	waitobj = invalid
	if showWait = true then
		waitobj = ShowPleaseWait("Preparing stream, please wait...", "")
	end if
	
    http = NewHttp(feed)
    rsp = http.GetToStringWithRetry()

    xml=CreateObject("roXMLElement")

    if not xml.Parse(rsp) then
        Dbg("parse_video_feed:  Can't parse feed")
		ShowErrorDialog("Unable to parse feed", "Video Feed")
        return children
    endif

    if xml.GetName() <> "group" and xml.GetName() <> "catalog" then
        Dbg("parse_video_feed: No group/catalog tag found")
        return children
    endif

    if islist(xml.GetBody()) = false then
        Dbg("parse_video_feed:  No group or catalog body found")
        return children
    endif
	
	element = GetFirstXMLElement(xml)
	if element.GetName() = "group"  then
	
		hasMedia = invalid
		
		childList = xml.GetChildElements()
		for each child in childList
			item = m.ParseGroupNode(child)
			
			if item <> invalid then
				Dbg("parse_video_feed: adding item = " + item.Title)
				children.Push(item)
			endif
			
		next
	else
		Dbg("parse_video_feed: unsupported child type of " + element.GetName())
	endif
	
	return children

End Function

	
'***********************************************************
'Given the xml element to an <Category> tag in the category
'feed, walk it and return the top level node to its tree
'***********************************************************
Function parse_group_node(item As Object) As dynamic
	Dbg("parse_group_node: parsing group node")

	if item.name = invalid or item.href = invalid or item.type = invalid then
		Dbg("parse_group_node: Invalid name, href, or type")
		return invalid
	endif
	
	'***********************************************************
	'Given the xml element to an <Category> tag in the category
	'feed, walk it and return the top level node to its tree
	'***********************************************************
	'Dbg("parse_group_node: group = " + item@name )
	'print "ip:    " + m.IP

	o = init_container_item()

	o.Parent = m
	o.IP = m.IP
	o.ContentId = ExtractStrFromMatch(item@href, "id=(.+)",1)
	o.Type = item@type

	o.Title = item@name
	o.Description = ""
	o.Media = invalid
	
	o.Href = item@href
	o.Feed = "http://" + m.IP + o.Href

	o.SDPosterUrl = "file://pkg:/images/icon-folder-sd.png"
	o.HDPosterUrl = "file://pkg:/images/icon-folder-hd.png"

	if item.art <> invalid
		artUrl = item@art
		if artUrl <> invalid and artUrl.Len() > 0 then
			o.SDPosterUrl = "http://" + m.IP + prepareURL(artUrl)
			o.HDPosterUrl = "http://" + m.IP + prepareURL(artUrl)
		endif
	endif
	
	o.ShortDescriptionLine1 = o.Title
	o.ShortDescriptionLine2 = o.Description

    return o
End Function

'***********************************************************
'Detemine if it has a media or folder item, based on type 
'***********************************************************
Function has_media_item(item As Object) As Boolean

	if item.type <> invalid
		if item@type = "video" then
			Dbg("is_media_item: true")
			return true
		endif
	endif
	
	Dbg("is_media_item: false")
    return false

End Function
	
'***********************************************************
'Given the xml element to an <Category> tag in the category
'feed, walk it and return the top level item to its tree
'***********************************************************
Function parse_media_item(item As Object) As dynamic
	Dbg("parse_media_item: parsing media item")

    http = NewHttp(item.Feed)

    rsp = http.GetToStringWithRetry()

    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
        Dbg("parse_media_item: Can't parse feed")
        return invalid
    endif

	'PrintXML(xml, 5)

    if xml.GetName() <> "group" then
        Dbg("parse_media_item:  No group tag found")
        return invalid
    endif

    if islist(xml.GetBody()) = false then
        Dbg("parse_media_item: No group body found")
        return invalid
    endif

    o = init_container_item()

	o.Parent = m
	o.IP = m.IP
	o.Href = item.Href
	o.Feed = item.Feed
	o.ContentId = item.ContentId
	o.Type = item.Type
	
	mediaList = xml.GetChildElements()
	for each media in mediaList

		if (media <> invalid)
			if media.GetName() = "media" then
				o.Title = media@name
				o.videoURL = "http://" + m.IP + "/" + HttpDecode(media@src)

				o.StreamURls = [ o.videoURL ]
				o.StreamFormat = "hls"
				o.StreamQualities = ["SD"]
				o.Bitrates  = [0]
				
				o.SDPosterUrl = "file://pkg:/images/icon-video-sd.png"
				o.HDPosterUrl = "file://pkg:/images/icon-video-hd.png"

				if media.art <> invalid then
					artUrl = media@art
					if artUrl <> invalid and artUrl.Len() > 0 then
						'artUrl = strReplace(artUrl, "size=large", "size=small")
						Dbg("parse_media_item: Image URL = " + "http://" + m.IP + artUrl)
						o.SDPosterUrl = "http://" + m.IP + prepareURL(artUrl)
						o.HDPosterUrl = "http://" + m.IP + prepareURL(artUrl)
					endif
				endif
				
			else if media.GetName() = "media_title" then
				o.Title = media@name
			else if media.GetName() = "description" then
				o.Description = media@name
			else if media.GetName() = "date" then
				o.ReleaseDate = media@name
			else if media.GetName() = "time" then
				o.Length = secondsFromString(media@name)
			else if media.GetName() = "rating" then
				o.Rating = media@name
			endif
		endif

	next
	
	if o.Type <> "video"
		Dbg("parse_media_item: Type is not Video")
		return invalid
	endif
	
	o.ShortDescriptionLine1 = o.Title
	o.ShortDescriptionLine2 = o.ReleaseDate

    return o
End Function


'******************************************************
'Initialize a Container Item
'******************************************************
Function init_container_item() As Object
    o = CreateObject("roAssociativeArray")
	
    o.Title        = ""
    o.Description  = ""
    o.Type         = "normal"
	o.ContentId    = invalid
	o.ContentType  = "episode"
    o.Parent       = invalid
	o.IP           = invalid
	o.Children     = invalid
	o.Href         = ""
    o.Feed         = ""
	
	o.RenderFunction = invalid
	
    return o
End Function

Function prepareURL(url As String) As String

	url = strReplace(url, "%26size=", "&size=")
	url = strReplace(url, "%2fmain.m3u8", "/main.m3u8")
	
	return url
End Function