local p = {}

local json = require("Module:Json")
local Lua = require("Module:Lua")
local Logic = require("Module:Logic")
local Template = require("Module:Template")
local htmlCreate = mw.html.create

local _args
local _frame

local config = Lua.moduleExists("Module:Match/Config") and require("Module:Match/Config") or {}
local MAX_NUM_MAPS = config.MAX_NUM_MAPS or 20

function p.get(frame)
	return p.luaGet(frame, require("Module:Arguments").getArgs(frame))
end

function p.luaGet(frame, args)
  	_frame = frame
  	_args = args
	local wrapper = htmlCreate("div")
  		:addClass("brkts-popup")
  
  	-- parse nested tables
  	local matchExtradata = json.parse(_args.extradata or "{}")
  	local stream = json.parse(_args.stream or "{}")
  	stream.date = mw.getContentLanguage():formatDate('r', _args.date)
	stream.finished = Logic.readBool(_args.finished) and "true" or ""
  
  	-- parameter
  	local vods = {}
  	
  	-- header
  	local header = htmlCreate("div")
  		:addClass("brkts-popup-header")
  		:node(htmlCreate("div")
  			:addClass("brkts-popup-header-left")
			:css("justify-content","flex-end")
			:css("display","flex")
			:css("width","45%")
  			:wikitext(displayOpponent(1)))
  		:node(htmlCreate("div")
  			:addClass("brkts-popup-header-right")
  			:wikitext(displayOpponent(2)))
  	wrapper:node(header):node(breakNode())
  	
  	-- body
  	local body = htmlCreate("div"):addClass("brkts-popup-body")
  	body = addFlexRow(body, {
	  		htmlCreate("center"):wikitext(
				Template.safeExpand(frame, "countdown", stream))
	  			:css("display","block")
	  			:css("margin","auto")
		},
		nil,
  		{ ["font-size"] = "85%" })
  	for index = 1, MAX_NUM_MAPS do
		local game = "match2game" .. index .. "_"
		local map = _args[game .. "map"]
		if not Logic.isEmpty(map) then
	  		local winner = _args[game .. "winner"]
	  		
			local extradata, err = json.parse(_args[game .. "extradata"])
			
	  		local centerNode = htmlCreate("div")
		  			:addClass("brkts-popup-spaced")
		  			:node(htmlCreate("div"):node("[[" .. map .. "]]"))
	  		if Logic.readBool(extradata.ot) then
				centerNode:node(htmlCreate("div"):node("- OT"))
				if not Logic.isEmpty(extradata.otlength) then
		  			centerNode:node(htmlCreate("div"):node("(" .. extradata.otlength .. ")"))
		  		end
			end
	  		local gameElements = {
		  		htmlCreate("div")
		  			:addClass("brkts-popup-spaced")
					:node(tonumber(winner) == 1 and
						  "[[File:GreenCheck.png|14x14px|link=]]" or
						  "[[File:NoCheck.png|link=]]")
		  			:node(htmlCreate("div"):node(_args[game .. "score1"] or "")),
		  		centerNode,
		  		htmlCreate("div")
		  			:addClass("brkts-popup-spaced")
					:node(htmlCreate("div"):node(_args[game .. "score2"] or ""))
		  			:node(tonumber(winner) == 2 and
						  "[[File:GreenCheck.png|14x14px|link=]]" or
						  "[[File:NoCheck.png|link=]]")
			}
	  		if not Logic.isEmpty(extradata.comment) then
				table.insert(gameElements, breakNode())
				table.insert(gameElements, htmlCreate("div")
		  			:node(extradata.comment)
					:css("margin","auto"))
			end
	  		body = addFlexRow(body, gameElements, "brkts-popup-body-game")
	  		
	  		-- add vods
	  		local vod = _args[game .. "vod"]
	  		if not Logic.isEmpty(vod) then
	  			vods[index] = vod
			end
	  	end
	end
  	wrapper:node(body):node(breakNode())
  
  	-- comment
  	if not Logic.isEmpty(matchExtradata.comment) then
		local comment = htmlCreate("div")
			:addClass("brkts-popup-comment")
			:css("white-space","normal")
			:css("font-size","85%")
			:node(matchExtradata.comment)
		wrapper:node(comment):node(breakNode())
	end
  
  	-- footer
  	local footerSet = false
  	local footer = htmlCreate("div")
  		:addClass("brkts-popup-footer")
  	local footerSpacer = htmlCreate("div")
  		:addClass("brkts-popup-spaced")
  	if not Logic.isEmpty(matchExtradata.octane) then
		footerSet = true
		footerSpacer:node("[[File:Octane_gg.png|14x14px|link=http://octane.gg/match/" ..
	  		matchExtradata.octane ..
	  		"|Octane matchpage]]")
	end
  	for index, vod in pairs(vods) do
		footerSet = true
		footerSpacer:node(Template.safeExpand(frame, "vodlink", {
		  	gamenum = index,
		  	vod = vod,
		  	source = url
		}))
	end
  	if footerSet then
  		footer:node(footerSpacer)
  		wrapper:node(footer)
	end
  	return wrapper
end

function addFlexRow(wrapper, contentElements, class, style)
	local node = htmlCreate("div"):addClass("brkts-popup-body-element")
  	if not Logic.isEmpty(class) then
		node:addClass(class)
 	end
  	for key, val in pairs(style or {}) do
		node:css(key, val)
	end
  	for index, element in ipairs(contentElements) do
		node:node(element)
	end
  	return wrapper:node(node)
end

function breakNode()
  	return htmlCreate("div")
  		:addClass("brkts-popup-break")
end

function displayOpponent(opponentIndex)
  	local opponent = "match2opponent" .. opponentIndex .. "_"
  	local opponentType = _args[opponent .. "type"]
  	if opponentType == "team" or opponentType == "literal" or Logic.isEmpty(opponentType) then
		local template = opponentIndex == 1 and "Team2Short" or "TeamShort"
		return Template.safeExpand(_frame, template, { _args[opponent .. "template"] or "TBD" })
	elseif opponentType == "solo" then
		local template = opponentIndex == 1 and "Player2" or "Player"
		return Template.safeExpand(_frame, template, { _args[opponent .. "match2player1_name"], flag = _args[opponent .. "match2player1_flag"] })
	end
  	return ""
end

return p
