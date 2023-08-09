------------------------------------------------------------------------------------------------
--- @file 		AseFlixel.lua
---
--- @brief 		Aseprite Animation Code Generator for HaxeFlixel
---
--- @details 	This script automates the process of generating animation code for HaxeFlixel
---				based on Aseprite sprite tags. It allows users to customize various parameters
---				through a dialog and exports the generated code to either a Haxe class file or 
---				a text file. The generated code can be used to define animations in HaxeFlixel 
---				game projects.
---				
--- @version 	1.0
---
--- @author Harpwood Studio
--- @see https://harpwood.itch.io/aseflixel
------------------------------------------------------------------------------------------------

local sprite = app.activeSprite

-- Check if a sprite is open and contains animation tags
if not sprite then
  return app.alert('No active sprite found. Please open a sprite and run the script again.')
end

if #sprite.tags == 0 then
	app.alert('No tags found in the sprite. Please add tags to the timeline and run the script again.')
	return
end

-- Function to show the dialog to get user inputs
local function showDialog()
	local dlg = Dialog()
	dlg:modify{ title = 'AseFlixel' }
	dlg:label{ } -- some empty space
	dlg:file{ id = 'path', label = 'Save Animation Code to:', filename = '', filetypes = {''}, save = true,  focus = true } --filetypes = { 'txt', 'hx' },
	dlg:separator{ } 
	dlg:number{ id = 'frameRate', label = 'Default Frame Rate:', decimals = 0, text = '7' }
	dlg:check{ id = 'overrideFrameRate', label = 'Frame Rate from Tag User Data ', selected = true }
	dlg:check{ id = 'includeDirection', label = 'Include Tag Animation Direction', selected = true }
	dlg:separator{}
	dlg:entry{ id = 'instanceName', label = 'Instance Name:', text = '' }
	dlg:entry{ id = 'prefix', label = 'Custom Animation Prefix:', text = '' }
	dlg:entry{ id = 'suffix', label = 'Custom Animation Suffix:', text = '' }
	dlg:separator{}
	dlg:check{ id = 'exportToClass', label = 'Export to Class', selected = false }
	dlg:entry{ id = 'packageName', label = 'Package Name:' }
	dlg:entry{ id = 'className', label = 'Class Name:' }
	dlg:entry{ id = 'assetFolder', label = 'Asset Folder:', text = 'assets' }
	dlg:entry{ id = 'assetFileName', label = 'Asset File Name:' }
	dlg:label{ } -- some empty space
	dlg:button{ id = 'save', text = 'Save', focus = false }
	dlg:button{ id = 'cancel', text = 'Cancel' }

	dlg:show()

	return dlg.data
end

local data = showDialog()

-- Extract user inputs from the dialog
local globalFrameRate = tonumber(data.frameRate)
local includeDirection = data.includeDirection
local overrideFrameRate = data.overrideFrameRate
local customPrefix = data.prefix
local customSuffix = data.suffix
local exportToClass = data.exportToClass
local packageName = data.packageName
local instanceName = data.instanceName
local className = data.className
local assetFolder = data.assetFolder
local assetFileName = data.assetFileName

-- If instanceName if it is not empty add a dot to connect it later with animation code line
-- For example, if the instanceName is 'sprite', the generated code will be 'sprite.animation.add(...
if instanceName ~= '' then
	instanceName = instanceName .. '.'
end

-- Set a placeholder asset file name if it is empty
if assetFileName == '' then
	assetFileName = '[YOUR_ASSET_FILE_NAME_HERE]'
end

local spacing = ''
local code = ''

-- The main logic of the script is executited when the save button is pressed
if data.save then
	
	-- Get the path and filename to save the generated code
	local path = data.path

	if path == "" then
		--- Use the path and filename of the Aseprite file, but remove the extension
		-- !!! Danger of overwriting your Aseprite file if you alter the following line of code !!!
		local n = string.gsub(sprite.filename, '.aseprite', '') 
		
		-- Handle the file name of the generated code
		if exportToClass then
			if className == '' then
				local j = 1
				-- Check where is the last '\' character in the path and mark its position
				for i = 1, #n do
					if string.sub(n, i, i) == '\\' then
						j = i
					end
				end
				-- Get the filename as a class name
				className = string.sub(n, j + 1, #n)
				className = className:gsub('^%l', string.upper)
			end
			path = n .. '.hx'
		else
			path = n .. '.txt'
		end		
	else
		if exportToClass then
			if not path:match("%.hx$") then
				path = string.gsub(path, ".txt", "")
				path = path .. ".hx"
			end
		else
			if not path:match("%.txt$") then
				path = string.gsub(path, '.txt', '')
				path = path .. ".txt"
			end
		end
	end

	-- Add boilerplate code and/or comments
	if exportToClass then
		spacing = "    "
		code = "package " .. packageName .. ";\n\n"
		code = code .. "import flixel.FlxSprite;\n"
		code = code .. "import flixel.system.FlxAssets.FlxGraphicAsset;\n\n"
		code = code .. "/**\n"
		code = code .. " * ".. className .. " class code generated with AseFlixel\n"
		code = code .. " * @author Harpwood Studio\n"
		code = code .. " * https://harpwood.itch.io/aseflixel\n"
		code = code .. " */\n"
		code = code .. "class " .. className .. " extends FlxSprite\n"
		code = code .. "{\n"
		code = code .. spacing .. "public function new(?X:Float=0, ?Y:Float=0, ?SimpleGraphic:FlxGraphicAsset)\n"
		code = code .. spacing .. "{\n"
		spacing = spacing .. spacing
		code = code .. spacing .. "super(X, Y, SimpleGraphic);\n\n"
		code = code .. spacing .. 'loadGraphic("'.. assetFolder .. '/' .. assetFileName .. '", true, ' .. sprite.width .. ', ' .. sprite.height .. ');\n'
		code = code .. spacing .. "\n"
	else
		code = code .. spacing .. "/**\n"
		code = code .. spacing .. " * Animation code generated with AseFlixel\n"
		code = code .. spacing .. " * @author Harpwood Studio\n" 
		code = code .. spacing .. " * https://harpwood.itch.io/aseflixel\n"
		code = code .. spacing .. " */\n"
	end

	-- Apply the data to animation code
	for i, tag in ipairs(sprite.tags) do
		-- Retrieve data from the tags
		local tagName = tag.name
		local fromFrame = tag.fromFrame.frameNumber - 1
		local toFrame = tag.toFrame.frameNumber - 1
		local tagData = tag.data
		local aniDir = tag.aniDir
		
		-- Determine the correct frames
		local frameList = {}
		for frame = fromFrame, toFrame do
			table.insert(frameList, frame)
		end

		-- Handle animation direction if specified
		if includeDirection then
			if aniDir == AniDir.REVERSE then
				frameList = { table.unpack(frameList) } 
				table.sort(frameList, function(a, b) return a > b end)
			elseif aniDir == AniDir.PING_PONG then
				local pingPongFrameList = { table.unpack(frameList) }
				for i = #frameList - 1, 2, -1 do
					table.insert(pingPongFrameList, frameList[i])
				end
				frameList = pingPongFrameList
			elseif aniDir == AniDir.PING_PONG_REVERSE then
				table.sort(frameList, function(a, b) return a > b end)
				local pingPongReverseFrameList = { table.unpack(frameList) }
				for i = #frameList - 1, 2, -1 do
					table.insert(pingPongReverseFrameList, frameList[i])
				end
				frameList = pingPongReverseFrameList
			end
		end

		-- Determine the frame rates
		local frameRate		
		if overrideFrameRate then 
			frameRate = tonumber(tagData) or globalFrameRate
		else
			frameRate = globalFrameRate
		end

		-- Determine the animation name
		tagName = customPrefix .. tagName .. customSuffix

		-- Determine the animation code
		if exportToClass then 
			instanceName = ''
		end
		local animationCode = instanceName .. 'animation.add("' .. tagName .. '", [' .. table.concat(frameList, ', ') .. '], ' .. frameRate .. ');'
		code = code .. spacing .. animationCode .. "\n"
	end

	-- Close the boilerplate code if exporting to a class
	if exportToClass then
		code = code .. "    }\n}"
	end

	-- Save the generated animation code to a file
	local file = io.open(path, "w")
	file:write(code)
	file:close()

	-- Show a message box indicating successful code generation and file saving
	app.alert("Animation code has been saved to " .. path)
end

