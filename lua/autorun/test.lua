function restartTimer()	--Starts/Restarts the timer for the vote
	print("Entered Restart Timer")
	
	serverPlayerNames = {}
	serverPlayers = {}
	for i, v in ipairs(player.GetAll()) do
		if v:Alive() then
			serverPlayers[i] = v
			serverPlayerNames[i] = v:Nick()
		end
	end
	print(serverPlayers[1])
	for i = 1, table.getn(serverPlayerNames) do
		table.insert(serverVotes, 0)
	end
	net.Start("votingTimerStart")
	net.Broadcast()
	timer.Simple(30, function() 
		print("Entered Timer Loop")
		net.Start("votingTimerExpire")
		net.WriteString("")
		net.Broadcast()
		
		mostVotes = 1
		votedFor = 1
		
		print(serverVotes[1])
		if table.getn(serverPlayers) >= 1 then
			for i = 1, table.getn(serverPlayerNames) do	--Tally Up The Votes, and check Who Was Voted For The Most
				if tonumber(mostVotes) < tonumber(serverVotes[i]) then
					mostVotes = serverVotes[i]
					votedFor = i
				end
			end
			print(serverPlayers[votedFor], " Has Been Voted For.")
			if mostVotes > (table.getn(serverPlayers) /2) then
				serverPlayers[votedFor]:Kill()
			end
			--timer.Create( "delayTimer", 10, 1, restartTimer())
			timer.Simple(10, restartTimer)
		end
	end)
end

if SERVER then
	serverPlayers = {}
	serverVotes = {}
	serverPlayerNames = {}
	--Testing!
	
	util.AddNetworkString("vote")	--Letting Lua Know "vote" is to be expected on serverside
	util.AddNetworkString("startVote")
	util.AddNetworkString("votingTimerExpire")
	util.AddNetworkString("votingTimerStart")
	net.Receive("vote", function()
		local val = net.ReadUInt(8)	--Gets The Index Of The Vote Clientside
		print(val) --Testing To Make Sure Variables Are Being Passed Correctly
		if (serverVotes[val] == nil) then
            serverVotes[val] = 1
		else
			serverVotes[val] = serverVotes[val] + 1
		end
	end)
	
	for i, v in ipairs(player.GetAll()) do
		table.insert(serverVotes, 0)
	end
	for i, v in ipairs(player.GetAll()) do
		if v:Alive() then
			serverPlayers[i] = v
			serverPlayerNames[i] = v:Nick()
		end
	end
	
	--serverVotes = {0}
	net.Receive("startVote", restartTimer)
	
	--restartTimer()
end
if CLIENT then
	function voteFrame()
		names = {}
		frameH = 1000
		frameW = 300
		gridHeight = 1
		j = 0
		--Setup The Frame
		local Frame = vgui.Create("DFrame")
		Frame:SetTitle( "The Voting Game" )		
		Frame:MakePopup()
		Frame.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
			draw.RoundedBox( 0, 0, 0, w, h, Color(0, 0, 0, 255) ) -- Draw a red box instead of the frame
		--Frame:SetVisible(false)
		end
		
		--Testing!
		for i, v in ipairs( player.GetAll() ) do
			print( v:Nick() )
		end
		names = {}
		for i, v in ipairs(player.GetAll()) do
			if v:Alive() then
				names[i] = v:Nick()
			end
		end
		
		--names = {"hsh", "Shmurf", "yeeter", "Competer1", "hsh", "Shmurf", "yeeter", "Competer2", "hsh", "Shmurf", "yeeter", "Competer3"} --Place Holder For Testing
		buttons = {}
		--Configure All The Buttons Dynamically
		for i = 1, table.getn(names) do 
			buttons[i] = vgui.Create("DButton", Frame)
			buttons[i]:SetText(names[i])
			buttons[i]:SetTextColor( Color(255,255,255) )
			buttons[i]:SetSize( 100, 30 )
			if frameW > j*110 then
				buttons[i]:SetPos((j*101)+1, (gridHeight * 31))
				j = j + 1
			else
				j = 0
				gridHeight = gridHeight + 1
				buttons[i]:SetPos((j*101)+1, (gridHeight * 31))
				j = j + 1
			end
			
			buttons[i].Paint = function( self, w, h )
				draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 250 ) ) -- Draw buttons initially
			end
			
			buttons[i].DoClick = function()
				--print( "I was clicked!") --Only For Testing
				Frame:SetVisible(false)
				net.Start("vote")
				net.WriteUInt( i, 8 ) -- The second argument is 8 since the age will never be above 255. Doing this saves bandwidth and can reduce bandwidth.
				net.SendToServer()
			end
			buttons[i].OnCursorEntered = function()
				buttons[i].Paint = function( self, w, h )
					draw.RoundedBox( 0, 0, 0, 100, 100, Color( 255, 0, 15, 250 ) ) -- Draw buttons red on hover
				end
			end
			buttons[i].OnCursorExited = function()
				buttons[i].Paint = function( self, w, h )
					draw.RoundedBox( 0, 0, 0, 100, 100, Color( 0, 0, 0, 250 ) ) -- Draw buttons black on Cursor Exit
				end
			end
		end
		Frame:SetSize(frameW+4, (gridHeight+1)*31)
		Frame:Center()
		Frame:SetVisible(true)
	end
	net.Receive("votingTimerStart", function()	--When Server Timer For Vote Starts
		print("Vote Started")
		voteFrame()
	end)
	net.Receive("votingTimerExpire", function() --When Server Timer For Vote Ends
		print("Vote Ended")
		
	end)
	concommand.Add( "openVote", function()  
		Frame:SetVisible(true)
	end)
	concommand.Add( "startVote", function()  
		net.Start("startVote")
		net.SendToServer()
	end)
end 