--
--****************************
--*** Minimal Display Bars ***
--****************************
--* Coded by: ATPHHe
--* Date Created: 02/19/2020
--* Date Modified: 06/27/2020
--*******************************
--
--============================================================

MinimalDisplayBars = {}

MinimalDisplayBars.MOD_ID = "MinimalDisplayBarsNutritions"

local gameVersion = getCore():getVersionNumber()
MinimalDisplayBars.gameVersionNum = 0

local tempIndex, _ = string.find(gameVersion, " ")

if tempIndex ~= nil then
    MinimalDisplayBars.gameVersionNum = tonumber(string.sub(gameVersion, 0, tempIndex))
    if MinimalDisplayBars.gameVersionNum == nil then 
        tempIndex, _ = string.find(gameVersion, ".") + 1 
        MinimalDisplayBars.gameVersionNum = tonumber(string.sub(gameVersion, 0, tempIndex))
    end
else
    MinimalDisplayBars.gameVersionNum = tonumber(gameVersion)
end
tempIndex = nil
gameVersion = nil

MinimalDisplayBars.defaultSettingsFileName = "MOD DefaultSettings (".. MinimalDisplayBars.MOD_ID ..")B42.lua"
MinimalDisplayBars.configFileName = "MOD Config Options (".. MinimalDisplayBars.MOD_ID ..")B42.lua"
--local configFileLocation = getMyDocumentFolder() .. getFileSeparator() .. MinimalDisplayBars.configFileName

MinimalDisplayBars.configFileLocations = {}

MinimalDisplayBars.configTables = {}

local numOfLocalClients = 0
--local isSplitScreen = false

--============================================================

--*********************************************
-- Other Useful Functions

local function tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        else
            print(formatting .. v)
        end
    end
end

local function deepcompare(t1, t2, ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepcompare(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepcompare(v1,v2) then return false end
    end
    return true
end

--[[
 * Converts an RGB color value to HSL. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes r, g, and b are contained in the set [0, 255] and
 * returns h, s, and l in the set [0, 1].
 *
 * @param   Number  r       The red color value
 * @param   Number  g       The green color value
 * @param   Number  b       The blue color value
 * @return  Array           The HSL representation
]]
local function rgbToHsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
  
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l
  
    l = (max + min) / 2
  
    if max == min then
      h, s = 0, 0 -- achromatic
    else
      local d = max - min
      local s
      if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
      if max == r then
        h = (g - b) / d
        if g < b then h = h + 6 end
      elseif max == g then h = (b - r) / d + 2
      elseif max == b then h = (r - g) / d + 4
      end
      h = h / 6
    end
  
    return {h, s, l}
  end
  
  --[[
   * Converts an HSL color value to RGB. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
   * Assumes h, s, and l are contained in the set [0, 1] and
   * returns r, g, and b in the set [0, 255].
   *
   * @param   Number  h       The hue
   * @param   Number  s       The saturation
   * @param   Number  l       The lightness
   * @return  Array           The RGB representation
  ]]
  local function hslToRgb(h, s, l)
    local r, g, b
  
    if s == 0 then
      r, g, b = l, l, l -- achromatic
    else
      local function hue2rgb(p, q, t)
        if t < 0   then t = t + 1 end
        if t > 1   then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
      end
  
      local q
      if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
      local p = 2 * l - q
  
      r = hue2rgb(p, q, h + 1/3)
      g = hue2rgb(p, q, h)
      b = hue2rgb(p, q, h - 1/3)
    end
  
    return {r * 255, g * 255, b * 255}
  end
  
  --[[
   * Converts an RGB color value to HSV. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
   * Assumes r, g, and b are contained in the set [0, 255] and
   * returns h, s, and v in the set [0, 1].
   *
   * @param   Number  r       The red color value
   * @param   Number  g       The green color value
   * @param   Number  b       The blue color value
   * @return  Array           The HSV representation
  ]]
  local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
  
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
  
    if max == min then
      h = 0 -- achromatic
    else
      if max == r then
      h = (g - b) / d
      if g < b then h = h + 6 end
      elseif max == g then h = (b - r) / d + 2
      elseif max == b then h = (r - g) / d + 4
      end
      h = h / 6
    end
  
    return {h, s, v}
  end
  
  --[[
   * Converts an HSV color value to RGB. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
   * Assumes h, s, and v are contained in the set [0, 1] and
   * returns r, g, and b in the set [0, 255].
   *
   * @param   Number  h       The hue
   * @param   Number  s       The saturation
   * @param   Number  v       The value
   * @return  Array           The RGB representation
  ]]
  local function hsvToRgb(h, s, v)
    local r, g, b
  
    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);
  
    i = i % 6
  
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
  
    return {r * 255, g * 255, b * 255}
  end



function MinimalDisplayBars.compare_and_insert(t1, t2, ignore_mt)
    
    local isEqual = true
    
    if not t1 then
        return false
    end
    
    if not t2 then
        t2 = {}
        isEqual = false
    end
    
    if type(t1) == "table" then
        for k1,v1 in pairs(t1) do
            local v2 = t2[k1]
            if (v2 == nil) then 
                t2[k1] = v1
                isEqual = false
            end
            
            if type(t1[k1]) == "table" then
                isEqual = MinimalDisplayBars.compare_and_insert(t1[k1], t2[k1], ignore_mt)
            end
            
        end
    end
    
    return isEqual
end

function MinimalDisplayBars.deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in pairs(orig) do
                copy[MinimalDisplayBars.deepcopy(orig_key, copies)] = MinimalDisplayBars.deepcopy(orig_value, copies)
            end
            setmetatable(copy, MinimalDisplayBars.deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Splits the string apart.
--  EX: inputstr = "Hello There Friend."
--      sep = " "
--      t = {Hello, 
--          There, 
--          Friend.}
--  EX: inputstr = "Hello,There,Friend."
--      sep = ","
--      t = {Hello, 
--          There, 
--          Friend.}
--
-- Parameters:  inputstr - the string that will be split.
--              sep - the separator character that will be used to split the string
--              t - the table that will be returned.
--
local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Returns true, if "a" a number. Otherwise return false.
local function isNumber(a)
    if tonumber(a) ~= nil then
        local number = tonumber(a)
        if number then
            return true
        end
    end
    
    return false
end


--*************************
-- I/O Functions


--[[

TablePersistence is a small code snippet that allows storing and loading of lua variables containing primitive types. It is licensed under the MIT license, use it how ever is needed. A more detailed description and complete source can be downloaded on http://the-color-black.net/blog/article/LuaTablePersistence. A fork has been created on github that included lunatest unit tests: https://github.com/hipe/lua-table-persistence

Shortcomings/Limitations:
- Does not export udata
- Does not export threads
- Only exports a small subset of functions (pure lua without upvalue)

]]
local write, writeIndent, writers, refCount;
MinimalDisplayBars.io_persistence =
{
	store = function (path, modID, ...)
		local file, e = getFileWriter(path, true, false) --e = io.open(path, "w");
		if not file then
            print("Error opening file for writing: ", e)
            return error(e)
            end
		local n = select("#", ...);
		-- Count references
		local objRefCount = {}; -- Stores reference that will be exported
		for i = 1, n do
			refCount(objRefCount, (select(i,...)));
		end;
		-- Export Objects with more than one ref and assign name
		-- First, create empty tables for each
		local objRefNames = {};
		local objRefIdx = 0;
		file:write("-- Persistent Data (for "..modID..")\n");
		file:write("local multiRefObjects = {\n");
		for obj, count in pairs(objRefCount) do
			if count > 1 then
				objRefIdx = objRefIdx + 1;
				objRefNames[obj] = objRefIdx;
				file:write("{};"); -- table objRefIdx
			end;
		end;
		file:write("\n} -- multiRefObjects\n");
		-- Then fill them (this requires all empty multiRefObjects to exist)
		for obj, idx in pairs(objRefNames) do
			for k, v in pairs(obj) do
				file:write("multiRefObjects["..idx.."][");
				write(file, k, 0, objRefNames);
				file:write("] = ");
				write(file, v, 0, objRefNames);
				file:write(";\n");
			end;
		end;
		-- Create the remaining objects
		for i = 1, n do
			file:write("local ".."obj"..i.." = ");
			write(file, (select(i,...)), 0, objRefNames);
			file:write("\n");
		end
		-- Return them
		if n > 0 then
			file:write("return obj1");
			for i = 2, n do
				file:write(" ,obj"..i);
			end;
			file:write("\n");
		else
			file:write("return\n");
		end;
		if type(path) == "string" then
			file:close();
		end;
	end;

	load = function (path, modID)
		local f, e;
		if type(path) == "string" then
            --f, e = loadfile(path);
			f, e = getFileReader(path, true);
            
            local contents = "";
            local scanLine = f:readLine();
            while scanLine do
                
                contents = contents.. scanLine .."\r\n";
                
                scanLine = f:readLine();
                if not scanLine then break end
            end
            
            f:close();
            
            f = contents;
		else
			f, e = path:read('*a');
		end
		if f then
            local func = loadstring(f);
            if func then
                return func();
            else
                return nil;
            end
		else
			return nil, e;
		end;
	end;
}

-- Private methods

-- write thing (dispatcher)
write = function (file, item, level, objRefNames)
	writers[type(item)](file, item, level, objRefNames);
end;

-- write indent
writeIndent = function (file, level)
	for i = 1, level do
		file:write("\t");
	end;
end;

-- recursively count references
refCount = function (objRefCount, item)
	-- only count reference types (tables)
	if type(item) == "table" then
		-- Increase ref count
		if objRefCount[item] then
			objRefCount[item] = objRefCount[item] + 1;
		else
			objRefCount[item] = 1;
			-- If first encounter, traverse
			for k, v in pairs(item) do
				refCount(objRefCount, k);
				refCount(objRefCount, v);
			end;
		end;
	end;
end;

-- Format items for the purpose of restoring
writers = {
	["nil"] = function (file, item)
        file:write("nil");
    end;
	["number"] = function (file, item)
        file:write(tostring(item));
    end;
	["string"] = function (file, item)
        file:write(string.format("%q", item));
    end;
	["boolean"] = function (file, item)
        if item then
            file:write("true");
        else
            file:write("false");
        end
    end;
	["table"] = function (file, item, level, objRefNames)
        local refIdx = objRefNames[item];
        if refIdx then
            -- Table with multiple references
            file:write("multiRefObjects["..refIdx.."]");
        else
            -- Single use table
            file:write("{\r\n");
            for k, v in pairs(item) do
                writeIndent(file, level+1);
                file:write("[");
                write(file, k, level+1, objRefNames);
                file:write("] = ");
                write(file, v, level+1, objRefNames);
                file:write(";\r\n");
            end
            writeIndent(file, level);
            file:write("}");
        end;
    end;
	["function"] = function (file, item)
        -- Does only work for "normal" functions, not those
        -- with upvalues or c functions
        local dInfo = debug.getinfo(item, "uS");
        if dInfo.nups > 0 then
            file:write("nil --[[functions with upvalue not supported]]");
        elseif dInfo.what ~= "Lua" then
            file:write("nil --[[non-lua function not supported]]");
        else
            local r, s = pcall(string.dump,item);
            if r then
                file:write(string.format("loadstring(%q)", s));
            else
                file:write("nil --[[function could not be dumped]]");
            end
        end
    end;
	["thread"] = function (file, item)
        file:write("nil --[[thread]]\r\n");
    end;
	["userdata"] = function (file, item)
        file:write("nil --[[userdata]]\r\n");
    end;
}

-- Testing Persistence
--MinimalDisplayBars.io_persistence.store("storage.lua", MinimalDisplayBars.MOD_ID, MinimalDisplayBars.configTables)
--t_restored = MinimalDisplayBars.io_persistence.load("storage.lua", MinimalDisplayBars.MOD_ID);
--MinimalDisplayBars.io_persistence.store("storage2.lua", MinimalDisplayBars.MOD_ID, t_restored)



-- Save to a destination file.
-- Returns true if successful, otherwise return false if an error occured.
MinimalDisplayBars.SaveToFile = function(destinationFile, text)
    local fileWriter = getFileWriter(destinationFile, true, false)
    
    fileWriter:write(tostring(text))
    fileWriter:close()
end

-- Load from a sourceFile file.
-- Returns a table of Strings, representing each line in the file.
MinimalDisplayBars.LoadFromFile = function(sourceFile)

	local contents = {}
	local fileReader = getFileReader(sourceFile, true)
    
	local scanLine = fileReader:readLine()
	while scanLine do
        
        table.insert(contents, tostring(scanLine))
        
		scanLine = fileReader:readLine()
		if not scanLine then break end
	end
    
	fileReader:close();
    
	return contents
end

-- Recreates the default configuration files for this mod.
local function recreateConfigFiles(locationIndex)
    local fileContents1 = MinimalDisplayBars.io_persistence.load(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID)
    MinimalDisplayBars.io_persistence.store(
        MinimalDisplayBars.configFileLocations[locationIndex], 
        MinimalDisplayBars.MOD_ID, 
        fileContents1)
    return fileContents1
end


--*********************************************
-- Custom Tables
local DEFAULT_SETTINGS = {
    
    ["moveBarsTogether"] = false,
    
    ["menu"] = {
        ["x"] = 70,
        ["y"] = 15,
        ["width"] = 15,
        ["height"] = 15,
        ["l"] = 3,
        ["t"] = 3,
        ["r"] = 3,
        ["b"] = 3,
        ["color"] = {red = (255 / 255), 
                    green = (255 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["hp"] = {
        ["x"] = 70,
        ["y"] = 30,
        ["width"] = 15,
        ["height"] = 150,
        ["l"] = 3,
        ["t"] = 3,
        ["r"] = 3,
        ["b"] = 3,
        ["color"] = {red = (0 / 255), 
                    green = (128 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["hunger"] = {
        ["x"] = 70 + 15,
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (255 / 255), 
                    green = (255 / 255), 
                    blue = (10 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Hungry.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
	["sickness"] = {
        ["x"] = 70 + 15,
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (150 / 255), 
                    green = (255 / 255), 
                    blue = (10 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Sick.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },	
    ["thirst"] = {
        ["x"] = 85 + (8 * 1),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (173 / 255), 
                    green = (216 / 255), 
                    blue = (230 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Thirsty.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["endurance"] = {
        ["x"] = 85 + (8 * 2),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (244 / 255), 
                    green = (244 / 255), 
                    blue = (244 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Endurance.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["fatigue"] = {
        ["x"] = 85 + (8 * 3),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (240 / 255), 
                    green = (240 / 255), 
                    blue = (170 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Tired.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["boredomlevel"] = {
        ["x"] = 85 + (8 * 4),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (170 / 255), 
                    green = (170 / 255), 
                    blue = (170 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Bored.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["unhappynesslevel"] = {
        ["x"] = 85 + (8 * 5),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (128 / 255), 
                    green = (128 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Moodle_Icon_Unhappy.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["stress"] = {
        ["x"] = 85 + (8 * 6),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (200 / 255), 
                    green = (0 / 255), 
                    blue = (100 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodle_Icon_Stressed.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["discomfortlevel"] = {
        ["x"] = 85 + (8 * 7),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (128 / 255), 
                    green = (128 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/Moodles/Mood_Discomfort.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["temperature"] = {
        ["x"] = 85 + (8 * 8),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (0 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = true,
        ["imageName"] = "media/ui/MDBTemperature.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["calorie"] = {
        ["x"] = 85 + (8 * 9),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/TraitNutritionist.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["carbohydrates"] = {
        ["x"] = 85 + (8 * 10),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/SpagettiRaw.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["proteins"] = {
        ["x"] = 85 + (8 * 11),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/Proteins.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    },
    ["lipids"] = {
        ["x"] = 85 + (8 * 12),
        ["y"] = 30,
        ["width"] = 8,
        ["height"] = 150,
        ["l"] = 2,
        ["t"] = 3,
        ["r"] = 2,
        ["b"] = 3,
        ["color"] = {red = (100 / 255), 
                    green = (255 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75},
        ["isMovable"] = true,
        ["isResizable"] = false,
        ["isVisible"] = true,
        ["isVertical"] = true,
        ["alwaysBringToTop"] = false,
        ["showMoodletThresholdLines"] = true,
        ["isCompact"] = false,
        ["imageShowBack"] = false,
        ["imageName"] = "media/ui/Butter.png",
        ["imageSize"] = 22,
        ["showImage"] = false,
        ["isIconRight"] = false,
    }
        
    
}

--Presets
local MrX_Settings = require('Presets/MDB_Preset_MrX')
local Ann_Settings = require('Presets/MDB_Preset_Ann')
local Kughi_Settings = require('Presets/MDB_Preset_Kughi')
local Sebo_Settings = require('Presets/MDB_Preset_Sebo')

local PRESETS = {
    ["MrX"] = MrX_Settings,
    ["Ann"] = Ann_Settings,
    ["Kughi"] = Kughi_Settings,
    ["Sebo"] = Sebo_Settings
}
--**********************************************
-- Vanilla Functions


--*************************************
-- Custom Functions

MinimalDisplayBars.displayBars = {} -- This should store all the display bars as they are created.

--fix vanilla bug stat == nan

-- local function isNaN(value)
--     return type(value) == "number" and value ~= value
-- end

local function isNaN(value)
    if type(value) == "string" then
      value = tonumber(value)
      if value == nil then return nil end
    elseif type(value) ~= "number" then
      return nil
    end
    return value ~= value
end

local function fixWornItems(isoPlayer)
    local wornItems = isoPlayer:getWornItems()
    if not wornItems then return end

    local size = wornItems:size()
    for i = 0, size - 1 do
        local item = wornItems:get(i):getItem()
        if item and instanceof(item, "Clothing") and isNaN(item:getWetness()) then
            -- print("Fixing Wetness Bug for Item: " .. item:getType())
            item:setWetness(0.0)
        end
    end
end

local function fixTemperature(isoPlayer,bodyDmg)
    if not bodyDmg or not isoPlayer then return end

    -- Fix indumenti buggati
    fixWornItems(isoPlayer)

    -- Reset della temperatura corporea
    local therm = bodyDmg:getThermoregulator()
    bodyDmg:setWetness(0.0)
    bodyDmg:setTemperature(37.0)
    if therm then
        therm:reset()
    end
end

local function fixThirst(isoStats)
    if not isoStats then return end

    -- Fix indumenti buggati
    -- fixWornItems(isoPlayer)
    isoStats:setThirst(0.0)
end

local function fixCalories(nutrition)
    if not nutrition then return end
    nutrition:setCalories(800.0)
end

local function fixLipids(nutrition)
    if not nutrition then return end
    nutrition:setLipids(0.0)
end

local function fixProteins(nutrition)
    if not nutrition then return end
    nutrition:setProteins(0.0)
end

local function fixCarbohydrates(nutrition)
    if not nutrition then return end
    nutrition:setCarbohydrates(0.0)
end





--==========================
-- Health Functions
local function calcHealth(value)
    return value / 100 
end
local function getHealth(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getBodyDamage():getOverallBodyHealth()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcHealth( isoPlayer:getBodyDamage():getOverallBodyHealth()) 
        end
    end
end

local function getColorHealth(isoPlayer) 
    local hpRatio = 0
    
    if not isoPlayer:isDead() then
        hpRatio = getHealth(isoPlayer)
    end
    
    local color
    if 0 <= hpRatio and hpRatio < 1 then
        color = { red = (255 / 255), 
                    green = (255 / 255) * (math.pow(0.1, 1 - hpRatio)), 
                    blue = (10 / 255) * (1 - hpRatio), 
                    alpha = 0.75 }
    elseif hpRatio < 0 then
        color = { red = (255 / 255), 
                    green = (0 / 255), 
                    blue = (0 / 255), 
                    alpha = 0.75 }
    else
        local r = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["red"]
        local g = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["green"]
        local b = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["blue"]
        local a = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["hp"]["color"]["alpha"]
        color = { red = ( r ), 
                    green = ( g ), 
                    blue = ( b ), 
                    alpha = a }
    end
    
    -- if hpWarningFlash[isoPlayer] then
    --     local hsv = rgbToHsv(color.red, color.green, color.blue)
    --     local sat = 0.5 * math.sin(hpTickCounter / 30 * math.pi) + 0.5
        
    --     local rgb = hsvToRgb(hsv[1], sat, hsv[3])
    --     --print(rgb[1] .. " " .. rgb[2] .. " " .. rgb[3])
    --     color.red = rgb[1]
    --     color.green = rgb[2]
    --     color.blue = rgb[3]
    -- end
    
    --print(hpWarningFlash[isoPlayer])
    
    return color
end

-- Hunger Functions
local function calcHunger(value)
    return 1 - value
end
local function getHunger(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getStats():getHunger()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcHunger( isoPlayer:getStats():getHunger() )
        end
    end
end

local function getColorHunger(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["hunger"]["color"]
    return color
end

-- Sickness Functions
local function calcSickness(value)
    return value
end
local function getSickness(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getStats():getSickness()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcSickness( isoPlayer:getStats():getSickness() )
        end
    end
end

local function getColorSickness(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["sickness"]["color"]
    return color
end

-- Thirst Functions
local function calcThirst(value)
    return 1 - value
end

local function getThirst(isoPlayer, useRealValue)
    if not isoPlayer or isoPlayer:isDead() then
        return -1
    end

    local isoStats = isoPlayer:getStats()
    local thirst = isoStats:getThirst()
    if isNaN(thirst) or thirst < 0 then
        fixThirst(isoStats)
        thirst = isoStats:getThirst()
    end

    if useRealValue then
        return thirst
    else
        return calcThirst(thirst)
    end
end

local function getColorThirst(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["thirst"]["color"]
    return color
end

-- Endurance Functions
local function calcEndurance(value)
    return value
end
local function getEndurance(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getStats():getEndurance()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcEndurance( isoPlayer:getStats():getEndurance() )
        end
    end
end

local function getColorEndurance(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["endurance"]["color"]
    return color
end

-- Fatigue Functions
local function calcFatigue(value)
    return value
end
local function getFatigue(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getStats():getFatigue()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcFatigue( isoPlayer:getStats():getFatigue() )
        end
    end
end

local function getColorFatigue(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["fatigue"]["color"]
    return color
end

-- BoredomLevel Functions
local function calcBoredomLevel(value)
    return value / 100
end
local function getBoredomLevel(isoPlayer, useRealValue)
    if useRealValue then
        return isoPlayer:getBodyDamage():getBoredomLevel()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcBoredomLevel( isoPlayer:getBodyDamage():getBoredomLevel() )
        end
    end
end

local function getColorBoredomLevel(isoPlayer, useRealValue) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["boredomlevel"]["color"]
    return color
end

-- Stress Functions
local function getCigStress(isoPlayer)
    return isoPlayer:getStats():getStressFromCigarettes()
end

local function getBaseStress(isoPlayer)
    -- Stress base = (stress totale) - (stress cigs)
    local cigStress = getCigStress(isoPlayer)
    return isoPlayer:getStats():getStress() - cigStress
end

local maxStress = 1
local function getMaxCigStress(isoPlayer)
    return isoPlayer:getStats():getMaxStressFromCigarettes()
end

local function calcStress(value, maxValue)
    return value / maxValue
end

local function getStress(isoPlayer, useRealValue)
    local maxCigaretStress = getMaxCigStress(isoPlayer)
    local baseStress = getBaseStress(isoPlayer)
    local cigsStress = getCigStress(isoPlayer)
    if isoPlayer:isDead() then
        return -1, -1
    end

    if useRealValue then
        return baseStress, cigsStress
    else
        baseStress = calcStress(baseStress, maxStress+maxCigaretStress) 
        cigsStress = calcStress(cigsStress, maxStress+maxCigaretStress)
        return baseStress, cigsStress
    end

end

local function getColorStress(isoPlayer)
    -- Il colore “base” che hai definito in configTables
    local color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["stress"]["color"]

    color.cigs = {
        red   = math.min(1, 1.5 * color.red),
        green = math.min(1, 1.5 * color.green),
        blue  = math.min(1, 1.5 * color.blue),
        alpha = 0.75
    }

    return color
end


-- UnhappynessLevel (UnhappinessLevel) Functions
local function calcUnhappynessLevel(value)
    --print(value)
    return value / 100
end
local function getUnhappynessLevel(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getBodyDamage():getUnhappynessLevel()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcUnhappynessLevel( isoPlayer:getBodyDamage():getUnhappynessLevel() )
        end
    end
end

local function getColorUnhappynessLevel(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["unhappynesslevel"]["color"]
    return color
end

-- DiscomfortLevel functions
local function calcDiscomfortLevel(value)
    --print(value)
    return value / 100
end
local function getDiscomfortLevel(isoPlayer, useRealValue) 
    if useRealValue then
        return isoPlayer:getBodyDamage():getDiscomfortLevel()
    else
        if isoPlayer:isDead() then
            return -1
        else
            return calcDiscomfortLevel( isoPlayer:getBodyDamage():getDiscomfortLevel() )
        end
    end
end

local function getColorDiscomfortLevel(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["discomfortlevel"]["color"]
    return color
end

-- Temperature Functions
local maxTempLim = 41  -- 41.0 C
local minTempLim = 19  -- 19.0 C
local function calcTemperature(value)
    return (value - minTempLim) / (maxTempLim - minTempLim)
end
local function getTemperature(isoPlayer, useRealValue)
    if not isoPlayer or isoPlayer:isDead() then
        return -1
    end

    local bodyDmg = isoPlayer:getBodyDamage()
    if not bodyDmg then return -1 end

    local temperature = bodyDmg:getTemperature()
    if isNaN(temperature) then
        fixTemperature(isoPlayer, bodyDmg)
        temperature = bodyDmg:getTemperature()
    end

    if useRealValue then
        return temperature
    else
        return calcTemperature(temperature)
    end
end

local function getColorTemperature(isoPlayer) 
    local tempRatio = getTemperature(isoPlayer) 
    
    local color
    if calcTemperature(20.0) <= tempRatio and tempRatio < calcTemperature(36.5) then
        local hue = (180 + (80 - 80 * ( (tempRatio - calcTemperature(20.0)) / (calcTemperature(36.5) - calcTemperature(minTempLim)) ))) / 360
        local rgb = hsvToRgb(hue, 1, 1)
        --print(hue * 360)
        --print(rgb[1].." "..rgb[2].." "..rgb[3])
        color = { red = rgb[1] / 255, 
                    green = rgb[2] / 255, 
                    blue = rgb[3] / 255, 
                    alpha = 0.75 }
    elseif calcTemperature(36.5) <= tempRatio and tempRatio <= calcTemperature(37.5) then
        local hue = (60 + (120 - 120 * ( (tempRatio - calcTemperature(36.5)) / (calcTemperature(37.5) - calcTemperature(36.5)) ))) / 360
        local rgb = hsvToRgb(hue, 1, 1)
        --print(hue * 360)
        --print(rgb[1].." "..rgb[2].." "..rgb[3])
        color = { red = rgb[1] / 255, 
                    green = rgb[2] / 255, 
                    blue = rgb[3] / 255, 
                    alpha = 0.75 }
    elseif calcTemperature(37.5) < tempRatio and tempRatio <= calcTemperature(40.0) then
        local hue = (0 + (60 - 60 * ( (tempRatio - calcTemperature(37.5)) / (calcTemperature(40.0) - calcTemperature(37.5)) ))) / 360
        local rgb = hsvToRgb(hue, 1, 1)
        --print(hue * 360)
        --print(rgb[1].." "..rgb[2].." "..rgb[3])
        color = { red = rgb[1] / 255, 
                    green = rgb[2] / 255, 
                    blue = rgb[3] / 255, 
                    alpha = 0.75 }
    else
        color = { red = (255 / 255), 
                    green = (255 / 255), 
                    blue = (255 / 255), 
                    alpha = 0.75 }
    end
    
    return color
end

-- Calorie Functions
local maxCalorie = 3700  -- 3700 calories
local minCalorie = -2200  -- -2200 calories
local function calcCalorie(value)
    return (value - minCalorie) / (maxCalorie - minCalorie)
end

local function getCalorie(isoPlayer, useRealValue)
    if not isoPlayer or isoPlayer:isDead() then
        return -1
    end

    local nutrition = isoPlayer:getNutrition()
    local calories = nutrition:getCalories()
    if isNaN(calories) then
        fixCalories(nutrition)
        calories = nutrition:getCalories()
    end

    if useRealValue then
        return calories
    else
        return calcCalorie(calories)
    end
end

local function getColorCalorie(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["calorie"]["color"]
    return color
end
-- Carbohydrates Functions
local maxCarbohydrates = 1000  -- 1000F Carbohydrates
local minCarbohydrates = -500  -- -5000 Carbohydrates
local function calcCarbohydrates(value)
    return (value - minCarbohydrates) / (maxCarbohydrates - minCarbohydrates)
end

local function getCarbohydrates(isoPlayer, useRealValue)
    if not isoPlayer or isoPlayer:isDead() then
        return -1
    end

    local nutrition = isoPlayer:getNutrition()
    local carbo = nutrition:getCarbohydrates()
    if isNaN(carbo) then
        fixCarbohydrates(nutrition)
        carbo = nutrition:getCarbohydrates()
    end

    if useRealValue then
        return carbo
    else
        return calcCarbohydrates(carbo)
    end
end

local function getColorCarbohydrates(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["carbohydrates"]["color"]
    return color
end

-- Proteins Functions
local maxProteins = 1000  -- 1000F Proteins
local minProteins = -500  -- -5000 Proteins
local function calcProteins(value)
    return (value - minProteins) / (maxProteins - minProteins)
end

local function getProteins(isoPlayer, useRealValue)
    if not isoPlayer or isoPlayer:isDead() then
        return -1
    end

    local nutrition = isoPlayer:getNutrition()
    local proteins = nutrition:getProteins()
    if isNaN(proteins) then
        fixProteins(nutrition)
        proteins = nutrition:getProteins()
    end

    if useRealValue then
        return proteins
    else
        return calcProteins(proteins)
    end
end

local function getColorProteins(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["proteins"]["color"]
    return color
end

-- Lipids Functions
local maxLipids = 1000  -- 1000F lipids
local minLipids = -500  -- -5000 lipids
local function calcLipids(value)
    return (value - minLipids) / (maxLipids - minLipids)
end

local function getLipids(isoPlayer, useRealValue)
    if not isoPlayer or isoPlayer:isDead() then
        return -1
    end

    local nutrition = isoPlayer:getNutrition()
    local lipids = nutrition:getLipids()
    if isNaN(lipids) then
        fixLipids(nutrition)
        lipids = nutrition:getLipids()
    end

    if useRealValue then
        return lipids
    else
        return calcLipids(lipids)
    end
end

local function getColorLipids(isoPlayer) 
    local color
    color = MinimalDisplayBars.configTables[isoPlayer:getPlayerNum() + 1]["lipids"]["color"]
    return color
end



--============================
-- Moodlet Threshold Tables
local function getMoodletThresholdTables() 
    local t = {
        ["hunger"] = {
            [1] = calcHunger(0.15), -- 0.15 / 1.00
            [2] = calcHunger(0.25),
            [3] = calcHunger(0.45),
            [4] = calcHunger(0.70),
        },
		["sickness"] = {
            [1] = calcSickness(.25), -- 25 / 100
            [2] = calcSickness(.50),
            [3] = calcSickness(.75),
            [4] = calcSickness(.90),
        },		
        ["thirst"] = {
            [1] = calcThirst(0.12), -- 0.12 / 1.00
            [2] = calcThirst(0.25),
            [3] = calcThirst(0.70),
            [4] = calcThirst(0.84),
        },
        ["endurance"] = {
            [1] = calcEndurance(0.10), -- 0.10 / 1.00
            [2] = calcEndurance(0.25),
            [3] = calcEndurance(0.50),
            [4] = calcEndurance(0.75),
        },
        ["fatigue"] = {
            [1] = calcFatigue(0.60), -- 0.60 / 1.00
            [2] = calcFatigue(0.70),
            [3] = calcFatigue(0.80),
            [4] = calcFatigue(0.90),
        },
        ["boredomlevel"] = {
            [1] = calcBoredomLevel(25), -- 25/100
            [2] = calcBoredomLevel(50),
            [3] = calcBoredomLevel(75),
            [4] = calcBoredomLevel(90),
        },
        ["stress"] = {
            [1] = calcStress(0.25,1),
            [2] = calcStress(0.50,1), 
            [3] = calcStress(0.75,1),
            [4] = calcStress(0.90,1),
        },
        ["unhappynesslevel"] = {
            [1] = calcUnhappynessLevel(20), -- 20/100
            [2] = calcUnhappynessLevel(45),
            [3] = calcUnhappynessLevel(60),
            [4] = calcUnhappynessLevel(80),
        },
        ["discomfortlevel"] = {
            [1] = calcDiscomfortLevel(20), -- 20/100
            [2] = calcDiscomfortLevel(40),
            [3] = calcDiscomfortLevel(60),
            [4] = calcDiscomfortLevel(80),
        },
        ["temperature"] = {
            [1] = calcTemperature(30.0), -- 30.0 C (MIN: 19.0 C, MAX: 41.0 C)
            [2] = calcTemperature(25.0),
            [3] = calcTemperature(36.5),
            [4] = calcTemperature(37.5),
            [5] = calcTemperature(39.0),
        },
        -- ["proteins"] = {
        --     [1] = calcProteins(-500), -- < -300
        --     [2] = calcProteins(-300), -- -300 - -100
        --     [3] = calcProteins(-100), -- -100 - 50
        --     [4] = calcProteins(50), -- 50 - 100
        --     [5] = calcProteins(100), -- 100 - 150
        --     [6] = calcProteins(150), -- 150 - 250
        --     [7] = calcProteins(250), -- 250 - 300
        --     [8] = calcProteins(300), -- > 300
        -- }, 
    }
    
    return t
end






function MinimalDisplayBars.createMoveBarsTogetherPanel(playerIndex)
    local minX = 1000000
    local maxX = 0
    local minY = 1000000
    local maxY = 0
    
    for _, bar in pairs(MinimalDisplayBars.displayBars[playerIndex]) do
        if bar and bar:isVisible() then 
            bar.parentOldX = nil
            bar.parentOldY = nil
            
            if bar.x < minX then minX = bar.x end
            if bar.x + bar:getWidth() > maxX then maxX = bar.x + bar:getWidth() end
            if bar.y < minY then minY = bar.y end
            if bar.y + bar:getHeight() > maxY then maxY = bar.y + bar:getHeight() end
        end
    end
    
    local barHP = MinimalDisplayBars.displayBars[playerIndex]["hp"]
    
    local moveBarsTogetherRectangle
    if barHP.parent then
        barHP.parent:removeFromUIManager()
    end
    if barHP.moveBarsTogether then
        moveBarsTogetherRectangle = 
            ISPanel:new(
                minX, 
                minY, 
                maxX - minX, 
                maxY - minY);
        moveBarsTogetherRectangle:instantiate()
        moveBarsTogetherRectangle:addToUIManager()
        moveBarsTogetherRectangle:setVisible(false)
    end
    for _, bar in pairs(MinimalDisplayBars.displayBars[playerIndex]) do
        if bar then 
            if bar.moveBarsTogether then 
                bar.parent = moveBarsTogetherRectangle
            else
                if bar.parent then
                    if not moveBarsTogetherRectangle then moveBarsTogetherRectangle = bar.parent end
                    bar.parent = nil
                end
            end
        end
    end
    if not barHP.moveBarsTogether then 
        if moveBarsTogetherRectangle then 
            moveBarsTogetherRectangle:removeFromUIManager()
        end
    end
end

local function resetBar(bar)
    
    if not bar then return end
    
    local DEFAULTS = 
        MinimalDisplayBars.io_persistence.load(
            MinimalDisplayBars.defaultSettingsFileName, 
            MinimalDisplayBars.MOD_ID)
    
    for k, v in pairs(MinimalDisplayBars.configTables[bar.coopNum][bar.idName]) do
        
        -- Ignore resetting these toggle options
        if k ~= "isMovable" 
           and k ~= "isResizable" 
           and k ~= "alwaysBringToTop" 
           and k ~= "showMoodletThresholdLines" 
           and k ~= "isCompact"
           and k ~= "showImage"
           then
           
            MinimalDisplayBars.configTables[bar.coopNum][bar.idName][k] = DEFAULTS[bar.idName][k]
            
        end
        
    end
    
    -- reset
    if bar then 
        bar:resetToConfigTable() 
        MinimalDisplayBars.createMoveBarsTogetherPanel(bar.playerIndex)
    end
    
    -- store options
    MinimalDisplayBars.io_persistence.store(
        bar.fileSaveLocation, 
        MinimalDisplayBars.MOD_ID, 
        MinimalDisplayBars.configTables[bar.coopNum])
    
    return
end

local function toggleMovable(bar)
    if bar.moveWithMouse then
        bar.moveWithMouse = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isMovable"] = false
    else
        bar.moveWithMouse = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isMovable"] = true
    end
end

local function toggleResizeable(bar)
    if bar.resizeWithMouse then
        bar.resizeWithMouse = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isResizable"] = false
    else
        bar.resizeWithMouse = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isResizable"] = true
    end
end

local function toggleAlwaysBringToTop(bar)
    if bar.alwaysBringToTop then
        bar.alwaysBringToTop = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["alwaysBringToTop"] = false
    else
        bar.alwaysBringToTop = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["alwaysBringToTop"] = false
    end
end

local function toggleMoodletThresholdLines(bar)
    if bar.showMoodletThresholdLines then
        bar.showMoodletThresholdLines = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["showMoodletThresholdLines"] = false
    else
        bar.showMoodletThresholdLines = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["showMoodletThresholdLines"] = true
    end
end

local function toggleCompact(bar)
    if bar.isCompact then
        bar.isCompact = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isCompact"] = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["height"] = 150
    else
        bar.isCompact = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isCompact"] = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["height"] = 75
    end
    --bar:resetToConfigTable() 
end

local function toggleMoveBarsTogether(bar)
    if bar.moveBarsTogether then
        bar.moveBarsTogether = false
        MinimalDisplayBars.configTables[bar.coopNum]["moveBarsTogether"] = false
    else
        bar.moveBarsTogether = true
        MinimalDisplayBars.configTables[bar.coopNum]["moveBarsTogether"] = true
    end
    --bar:resetToConfigTable()
end

local function toggleShowImage(bar)
    if bar.showImage then
        bar.showImage = false
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["showImage"] = false
    else
        bar.showImage = true
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["showImage"] = true
    end
    --bar:resetToConfigTable() 
end

local function onConfirmLoadPreset(target, button, param1, param2)

    if button.internal ~= "YES" then return end
    local bar = param1
    if not bar then return end
    
    if not param2 then
        getPlayer():Say("Loading MDB_Preset.lua")
    
        local loadedPreset = MinimalDisplayBars.io_persistence.load(
            "MDB_Preset.lua",
            MinimalDisplayBars.MOD_ID
        )
        if not loadedPreset then
            getPlayer():Say("Can't find MDB_Preset.lua!")
            return
        end

        local defaultTable = MinimalDisplayBars.io_persistence.load(
            MinimalDisplayBars.defaultSettingsFileName,
            MinimalDisplayBars.MOD_ID
        )
    
        -- loadedPreset = MinimalDisplayBars.deepcopy(loadedPreset)

        MinimalDisplayBars.compare_and_insert(defaultTable, loadedPreset, true)

        MinimalDisplayBars.configTables[bar.coopNum] = loadedPreset

        MinimalDisplayBars.io_persistence.store(
            bar.fileSaveLocation,
            MinimalDisplayBars.MOD_ID,
            MinimalDisplayBars.configTables[bar.coopNum]
        )
    else
        getPlayer():Say("Loading "..param2.." Preset")
        -- getModFileWriter
        if not param2 then
            getPlayer():Say("Can't find MDB_Preset.lua!")
            return
        end
        local defaultTable = MinimalDisplayBars.io_persistence.load(
            MinimalDisplayBars.defaultSettingsFileName,
            MinimalDisplayBars.MOD_ID
        )
    
        local loadedPreset = MinimalDisplayBars.deepcopy(PRESETS[param2])

        MinimalDisplayBars.compare_and_insert(defaultTable, loadedPreset, true)

        MinimalDisplayBars.configTables[bar.coopNum] = loadedPreset
    end
    
    local allBars = MinimalDisplayBars.displayBars[bar.playerIndex]
    for _, someBar in pairs(allBars) do
        if someBar and someBar.resetToConfigTable then
            someBar:resetToConfigTable()
        end
    end
    
    MinimalDisplayBars.createMoveBarsTogetherPanel(bar.playerIndex)
    local barHP = MinimalDisplayBars.displayBars[bar.playerIndex]["hp"]
            
    -- Make sure bars are toggled correctly
        -- Make sure bars are all toggled correctly when new bars are added.
    for _, minibar in pairs(MinimalDisplayBars.displayBars[bar.playerIndex]) do
        if minibar then 
            if barHP.moveWithMouse ~= minibar.moveWithMouse then
                toggleMovable(minibar) end
            if barHP.resizeWithMouse ~= minibar.resizeWithMouse then
                toggleResizeable(minibar) end
            if barHP.alwaysBringToTop ~= minibar.alwaysBringToTop then
                toggleAlwaysBringToTop(minibar) end
            if barHP.showMoodletThresholdLines ~= minibar.showMoodletThresholdLines then
                toggleMoodletThresholdLines(minibar) end
            if barHP.isCompact ~= minibar.isCompact then
                toggleCompact(minibar) end
            if barHP.moveBarsTogether ~= minibar.moveBarsTogether then
                toggleMoveBarsTogether(minibar) end
            -- if barHP.showImage ~= minibar.showImage then
            --     toggleShowImage(minibar) end
        end
    end

    getPlayer():Say("Preset loaded successfully!")
end

local function toggleModalLoadPreset(generic_bar)
    -- local windowSize = 600+(getCore():getOptionFontSizeReal()*100);
    local texture = getTexture("media/ui/mdbPresetFolder.png")
    local windowSize = 600+(getCore():getOptionFontSizeReal()*100);
        if texture then
            windowSize = texture:getWidth()
            windowSize = windowSize + (getCore():getOptionFontSizeReal()*100)
        end
    
    -- for reference videocentre from  MapSpawnSelect:render
    -- local tempString = ""
	-- local w = 1920
	-- local h = 1080
	
    local animPopup = ISModalRichText:new((getCore():getScreenWidth()-windowSize)/2, getCore():getScreenHeight()/2-300,windowSize,200, "", true, nil, onConfirmLoadPreset, generic_bar.playerIndex, generic_bar);
    animPopup:initialise();
    animPopup.backgroundColor = {r=0, g=0, b=0, a=0.9};
    animPopup.alwaysOnTop = true;

    -- test
    -- local div = w/(animPopup.chatText:getWidth() - 10*2 - 2)
	-- local w2 = w / div
	-- local h2 = h / div
	-- tempString = "<VIDEOCENTRE:".. "test.bik" ..","..w..","..h..","..w2..","..h2..">\n"

    -- animPopup.chatText.text = tempString .. getText("UI_LoadPreset_Info")
    animPopup.chatText.text = getText("UI_LoadPreset_Info")
    animPopup.chatText:paginate();
    animPopup:setHeightToContents()
    animPopup:ignoreHeightChange()
    animPopup:setY(getCore():getScreenHeight()/2-(animPopup:getHeight()/2));
    animPopup:setVisible(true);
    animPopup:addToUIManager();
end
local function toggleModalImportPreset(generic_bar, name)
    local texture = getTexture("media/ui/mdbImport"..name..".png")
    local windowSize = 600+(getCore():getOptionFontSizeReal()*100);
    if texture then
        windowSize = texture:getWidth()
        windowSize = windowSize + (getCore():getOptionFontSizeReal()*100)
    end
	
    local animPopup = ISModalRichText:new((getCore():getScreenWidth()-windowSize)/2, getCore():getScreenHeight()/2-300,windowSize,200, "", true, nil, onConfirmLoadPreset, generic_bar.playerIndex, generic_bar, name);
    animPopup:initialise();
    animPopup.backgroundColor = {r=0, g=0, b=0, a=0.9};
    animPopup.alwaysOnTop = true;
    animPopup.chatText.text = getText("UI_ImportPreset_Info", name)
    animPopup.chatText:paginate();
    animPopup:setHeightToContents()
    animPopup:ignoreHeightChange()
    animPopup:setY(getCore():getScreenHeight()/2-(animPopup:getHeight()/2));
    animPopup:setVisible(true);
    animPopup:addToUIManager();
end

-- ContextMenu
local contextMenu = nil
MinimalDisplayBars.displayBarPropertiesPanel = nil
local colorPicker = nil

local function setHeightWidth(bar)
    
    if not bar then return end
    
    ISGenericMiniDisplayBar.alwaysBringToTop = false
    
    if MinimalDisplayBars.displayBarPropertiesPanel and MinimalDisplayBars.displayBarPropertiesPanel.close then 
        MinimalDisplayBars.displayBarPropertiesPanel:close() 
    end
    
    MinimalDisplayBars.displayBarPropertiesPanel = 
        ISDisplayBarPropertiesPanel:new(
            bar:getX(), 
            bar:getY(), 
            bar)
    
    bar.displayBarPropertiesPanel = MinimalDisplayBars.displayBarPropertiesPanel
    MinimalDisplayBars.displayBarPropertiesPanel:initialise()
    --bar:addChild(MinimalDisplayBars.displayBarPropertiesPanel)
    
    --[[
    MinimalDisplayBars.displayBarPropertiesPanel:setInitialColor(
        ColorInfo.new(
            bar.color.red, 
            bar.color.green, 
            bar.color.blue, 
            bar.color.alpha)
        )
        
    MinimalDisplayBars.displayBarPropertiesPanel.pickedTarget = bar
    MinimalDisplayBars.displayBarPropertiesPanel.pickedFunc = function(bar, color)
        bar.color = {
            red = color.r, 
            green = color.g, 
            blue = color.b, 
            alpha = bar.color.alpha
        }
            
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["color"] = bar.color
        MinimalDisplayBars.io_persistence.store(
            bar.fileSaveLocation, 
            MinimalDisplayBars.MOD_ID, 
            MinimalDisplayBars.configTables[bar.coopNum])
        
        MinimalDisplayBars.displayBarPropertiesPanel:close()
        
        return
    end
    --]]
    
    MinimalDisplayBars.displayBarPropertiesPanel:addToUIManager()
    
    local screenHeight = getCore():getScreenHeight()
    local bottom = (MinimalDisplayBars.displayBarPropertiesPanel.y + MinimalDisplayBars.displayBarPropertiesPanel.height)
    if bottom > screenHeight then
        MinimalDisplayBars.displayBarPropertiesPanel:setY(MinimalDisplayBars.displayBarPropertiesPanel.y - (bottom - screenHeight))
    end
    
    local screenWidth = getCore():getScreenWidth()
    local right = (MinimalDisplayBars.displayBarPropertiesPanel.x + MinimalDisplayBars.displayBarPropertiesPanel.width)
    if right > screenWidth then
        MinimalDisplayBars.displayBarPropertiesPanel:setX(MinimalDisplayBars.displayBarPropertiesPanel.x - (right - screenWidth))
    end
    
    return
end

local function setBarColor(bar)
    
    if not bar then return end
    
    ISGenericMiniDisplayBar.alwaysBringToTop = false
    
    if colorPicker and colorPicker.close then colorPicker:close() end
    --if colorPicker and colorPicker.removeSelf then colorPicker:removeSelf() end
    
    colorPicker = ISColorPickerMDB:new(bar.x, bar.y)
    bar.colorPicker = colorPicker
    colorPicker:initialise()
    --bar:addChild(colorPicker)
    
    colorPicker:setInitialColor(
        ColorInfo.new(
            bar.color.red, 
            bar.color.green, 
            bar.color.blue, 
            bar.color.alpha)
        )
        
    colorPicker.pickedTarget = bar
    colorPicker.pickedFunc = function(bar, color)
        bar.color = 
        {
            red = color.r, 
            green = color.g, 
            blue = color.b, 
            alpha = bar.color.alpha
        }
            
        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["color"] = bar.color
        MinimalDisplayBars.io_persistence.store(
            bar.fileSaveLocation, 
            MinimalDisplayBars.MOD_ID, 
            MinimalDisplayBars.configTables[bar.coopNum])
        
        colorPicker:close()
        
        return
    end
        
    local screenHeight = getCore():getScreenHeight()
    local bottom = (colorPicker.y + colorPicker.height)
    if bottom > screenHeight then
        colorPicker.y = (colorPicker.y - (bottom - screenHeight))
    end
    
    local screenWidth = getCore():getScreenWidth()
    local right = (colorPicker.x + colorPicker.width)
    if right > screenWidth then
        colorPicker.x = (colorPicker.x - (right - screenWidth))
    end
    
    colorPicker:addToUIManager()
    
    return
end

-- prevent UI from covering this context menu and color picker
local contextMenuTicks = 0

local function preventContextCoverup()
    
    contextMenuTicks = contextMenuTicks + 1
    
    if contextMenuTicks >= 16 then
        contextMenuTicks = 0
        
        -- Prevent minimal display bars from covering context and other clicked UI.
        if contextMenu and not contextMenu:isVisible() then
            contextMenu = nil
        elseif MinimalDisplayBars.displayBarPropertiesPanel and not MinimalDisplayBars.displayBarPropertiesPanel:isVisible() then
            MinimalDisplayBars.displayBarPropertiesPanel = nil
        elseif colorPicker and not colorPicker:isVisible() then
            colorPicker = nil
        end
        
        -- Allow bring to top when all display bar UI's are closed.
        if not contextMenu 
                and not colorPicker 
                and not MinimalDisplayBars.displayBarPropertiesPanel then
            ISGenericMiniDisplayBar.alwaysBringToTop = true
        end
    end
    
end



MinimalDisplayBars.showContextMenu = function(generic_bar, dx, dy)

    ISGenericMiniDisplayBar.alwaysBringToTop = false
    
	contextMenu = ISContextMenu.get(
        generic_bar.playerIndex, 
        (generic_bar.x + dx), (generic_bar.y + dy), 
        1, 1
    )
    
    -- Title
	--contextMenu:addOption("--- " .. getText("ContextMenu_MinimalDisplayBars_Title") .. " ---")
    contextMenu:addOption("--- " .. "Minimal Display Bars" .. " ---")
    
    -- Display Bar Name
    contextMenu:addOption("==/   " .. getText("ContextMenu_MinimalDisplayBars_".. generic_bar.idName .."") .. "   \\==")
    
    -- Bar HP
    local barHP = MinimalDisplayBars.displayBars[generic_bar.playerIndex]["hp"]
    
    -- === Menu ===
    if generic_bar.idName == "menu" then
    
        -- Reset All
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Reset"),
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                MinimalDisplayBars.configTables[generic_bar.coopNum] = 
                    MinimalDisplayBars.io_persistence.load(
                        MinimalDisplayBars.defaultSettingsFileName, 
                        MinimalDisplayBars.MOD_ID)
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                if generic_bar then 
                    generic_bar:resetToConfigTable() end
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        bar:resetToConfigTable() 
                    end
                end
                
                MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end)
        
        --[[
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Reset_Display_Bar")), subMenu)
        for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
            if bar then 
                subMenu:addOption(
                        getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                        nil,
                        function()
                            
                            
                            
                            MinimalDisplayBars.io_persistence.store(bar.fileSaveLocation, MinimalDisplayBars.MOD_ID, MinimalDisplayBars.configTables[bar.coopNum])
                            
                            return
                        end
                )
            end
        end
        --]]
        
        -- Show Display Bar
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Show_Bar")), 
            subMenu
        )
        subMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Show_All_Display_Bars"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                --[[if generic_bar then 
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isVisible"] = true
                    generic_bar:setVisible(true) 
                end]]
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isVisible"] = true
                        bar:setVisible(true) 
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                -- recreate MoveBarsTogether panel when showing a display bar
                MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end
        )
        
        for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
            if bar then 
                subMenu:addOption(
                    getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                    nil,
                    function()
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isVisible"] = true
                        bar:setVisible(true)
                        
                        MinimalDisplayBars.io_persistence.store(
                            bar.fileSaveLocation, 
                            MinimalDisplayBars.MOD_ID, 
                            MinimalDisplayBars.configTables[bar.coopNum])
                        
                        -- recreate MoveBarsTogether panel when showing a display bar
                        MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                        
                        return
                    end
                )
            end
        end
        
        -- Hide Display Bar
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Hide_Bar")), 
            subMenu
        )
        subMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Hide_All_Display_Bars"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isVisible"] = false
                        bar:setVisible(false) 
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                -- recreate MoveBarsTogether panel when hiding a display bar
                MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end
        )
        
        for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
            if bar then 
                subMenu:addOption(
                    getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                    nil,
                    function()
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["isVisible"] = false
                        bar:setVisible(false)
                        
                        MinimalDisplayBars.io_persistence.store(
                            bar.fileSaveLocation, 
                            MinimalDisplayBars.MOD_ID, 
                            MinimalDisplayBars.configTables[bar.coopNum])
                        
                        -- recreate MoveBarsTogether panel when hiding a display bar
                        MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                        
                        return
                    end
                )
            end
        end
        
        -- Set Height/Width
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth")), 
            subMenu
        )
        --[[
        subMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_All"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                setHeightWidth(MinimalDisplayBars.displayBars[generic_bar.playerIndex]["hp"], true)
                
                return
            end
        )--]]
        
        for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
            if bar then 
                subMenu:addOption(
                    getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                    nil,
                    function()
                        if not bar then return end
                        setHeightWidth(bar)
                    end
                )
            end
        end
        
        -- Change Display Bar Color
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Set_Color")), 
            subMenu
        )
        
        for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
            
            if bar.idName ~= "temperature" then
                
                if bar then 
                    subMenu:addOption(
                        getText("ContextMenu_MinimalDisplayBars_".. bar.idName ..""),
                        nil,
                        function()
                            if not bar then return end
                            setBarColor(bar)
                        end
                    )
                end
                
            end
            
        end
        
        -- Toggle Movable All
        local str
        if barHP.moveWithMouse == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Movable_All")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Movable_All")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)

                if not generic_bar then return end
                
                if generic_bar then 
                    toggleMovable(generic_bar) end
                
                toggleMovable(barHP) 
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.moveWithMouse ~= bar.moveWithMouse then
                            toggleMovable(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                return
            end
        )
            
        -- Toggle Resizable All
        --[[
        local str
        if barHP.resizeWithMouse == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Resizable_All")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Resizable_All")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)

                if not generic_bar then return end
                
                toggleResizeable(barHP) 
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.resizeWithMouse ~= bar.resizeWithMouse then
                            toggleResizeable(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                
                return
            end
        )
        --]]
        
        -- Toggle Always Bring Display Bars To Top
        local str
        if barHP.alwaysBringToTop == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Always_Bring_Display_Bars_To_Top")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Always_Bring_Display_Bars_To_Top")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                
                toggleAlwaysBringToTop(barHP)
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.alwaysBringToTop ~= bar.alwaysBringToTop then
                            toggleAlwaysBringToTop(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                return
            end
        )
            
        -- Toggle Moodlet Threshold Lines
        local str
        if barHP.showMoodletThresholdLines == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Moodlet_Threshold_Lines")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Moodlet_Threshold_Lines")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleMoodletThresholdLines(barHP) 
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.showMoodletThresholdLines ~= bar.showMoodletThresholdLines then
                            toggleMoodletThresholdLines(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                return
            end
        )
            
        -- Toggle Compact
        --[[
        local str
        if barHP.isCompact == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Compact")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Compact")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleCompact(barHP) 
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.isCompact ~= bar.isCompact then
                            toggleCompact(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                return
            end
        )
        --]]
        
        -- Toggle Move Bars Together
        local str
        if barHP.moveBarsTogether == true then
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Move_Bars_Together")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_ON")..")"
        else
            str = getText("ContextMenu_MinimalDisplayBars_Toggle_Move_Bars_Together")
                        .." ("..getText("ContextMenu_MinimalDisplayBars_OFF")..")"
        end
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleMoveBarsTogether(barHP) 
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.moveBarsTogether ~= bar.moveBarsTogether then
                            toggleMoveBarsTogether(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                return
            end
        )
        
        -- Toggle Show Image
        local str = getText("ContextMenu_MinimalDisplayBars_Toggle_Show_Image")..
        " ("..getText("ContextMenu_MinimalDisplayBars_"..(barHP.showImage and "ON" or "OFF"))..")"
        
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                
                toggleShowImage(barHP) 
                
                for _, bar in pairs(MinimalDisplayBars.displayBars[generic_bar.playerIndex]) do
                    if bar then 
                        if barHP.showImage ~= bar.showImage then
                            toggleShowImage(bar) 
                        end
                    end
                end
                
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                return
            end
        )

        -- Toggle Load Preset
        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(
            contextMenu:addOption(getText("ContextMenu_MinimalDisplayBars_Toggle_Load_Preset")), 
            subMenu
        )
        subMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Toggle_Load_Preset"),
            generic_bar,
            function(generic_bar)
            
            if not generic_bar then return end
            
            toggleModalLoadPreset(generic_bar)
            return
            end
        )
        
        -- Import Preset
        local presets = {["Kughi"] = "Concentrated",["Ann"] = "Minimal",["MrX"] = "Horizon", ["Sebo"] = "Bottom"}
        for index, preset in pairs(presets) do
            local str = getText("ContextMenu_MinimalDisplayBars_Toggle_Import_Preset")
            subMenu:addOption(
                str .. " " .. preset .. " ("..index..")",
                generic_bar,
                function(generic_bar)
                
                if not generic_bar then return end
                
                toggleModalImportPreset(generic_bar, index)
                return
                end
            )
        end

        -- Export Preset
        local str = getText("ContextMenu_MinimalDisplayBars_Toggle_Export_Preset")
        contextMenu:addOption(
            str,
            generic_bar,
            function(generic_bar)
            
            if not generic_bar then return end
            
            MinimalDisplayBars.io_persistence.store(
                "MDB_Preset.lua",
                MinimalDisplayBars.MOD_ID,
                MinimalDisplayBars.configTables[generic_bar.coopNum]
            )
            
            getPlayer():Say("Preset exported successfully!")
            return
            end
        )
        
    else
    
    -- === Display Bars ===
        -- reset
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Reset_Display_Bar"),
            generic_bar,
            function(generic_bar)
                resetBar(generic_bar)
                return
            end
        )
        
        -- set vertical
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_Vertical"),
            generic_bar,
            function(generic_bar)
                
                if not generic_bar then return end
                if MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] == false or generic_bar.isVertical == false then
                    generic_bar.isVertical = true
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] = true
                    local oldW = tonumber(generic_bar.oldWidth)
                    local oldH = tonumber(generic_bar.oldHeight)
                    generic_bar:setWidth(oldH)
                    generic_bar:setHeight(oldW)
                    
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["width"] = generic_bar:getWidth()
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["height"] = generic_bar:getHeight()
                    
                    MinimalDisplayBars.io_persistence.store(
                        generic_bar.fileSaveLocation, 
                        MinimalDisplayBars.MOD_ID, 
                        MinimalDisplayBars.configTables[generic_bar.coopNum])
                    
                    -- recreate MoveBarsTogether panel
                    MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                end
                return
            end
        )
        
        -- set horizontal
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_Horizontal"),
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                if MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] == true or generic_bar.isVertical == true then
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isVertical"] = false
                    generic_bar.isVertical = false

                    local oldW = tonumber(generic_bar.oldWidth)
                    local oldH = tonumber(generic_bar.oldHeight)
                    generic_bar:setWidth(oldH)
                    generic_bar:setHeight(oldW)
                    
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["width"] = generic_bar:getWidth()
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["height"] = generic_bar:getHeight()
                    
                    MinimalDisplayBars.io_persistence.store(
                        generic_bar.fileSaveLocation, 
                        MinimalDisplayBars.MOD_ID, 
                        MinimalDisplayBars.configTables[generic_bar.coopNum])
                    
                    -- recreate MoveBarsTogether panel
                    MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                end
                return
            end
        )
        -- set horizontal icon position
        contextMenu:addOption(
            "Set Horizontal Icon ("..(generic_bar.isIconRight and "Left" or "Right")..")",
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end 
                    generic_bar.isIconRight = not generic_bar.isIconRight
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isIconRight"] = generic_bar.isIconRight
                    
                    MinimalDisplayBars.io_persistence.store(
                        generic_bar.fileSaveLocation, 
                        MinimalDisplayBars.MOD_ID, 
                        MinimalDisplayBars.configTables[generic_bar.coopNum])
                    
                    -- recreate MoveBarsTogether panel
                    MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                return
            end
        )
        -- set hide/show icon
        contextMenu:addOption(
            (generic_bar.showImage and "Hide" or "Show").." Icon",
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end 
                    generic_bar.showImage = not generic_bar.showImage
                    MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["showImage"] = generic_bar.showImage
                    
                    MinimalDisplayBars.io_persistence.store(
                        generic_bar.fileSaveLocation, 
                        MinimalDisplayBars.MOD_ID, 
                        MinimalDisplayBars.configTables[generic_bar.coopNum])
                    
                    -- recreate MoveBarsTogether panel
                    MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                return
            end
        )
        
        -- set color
        if generic_bar.idName ~= "temperature" then
            
            contextMenu:addOption(
                getText("ContextMenu_MinimalDisplayBars_Set_Color"),
                generic_bar,
                function(generic_bar)
                
                    setBarColor(generic_bar)
                    
                    return
                end)
        end
        
        -- set height / width
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Set_HeightWidth"),
            generic_bar,
            function(generic_bar)
            
                setHeightWidth(generic_bar)
                
                return
            end
        )
        
        -- hide
        contextMenu:addOption(
            getText("ContextMenu_MinimalDisplayBars_Hide"),
            generic_bar,
            function(generic_bar)
            
                if not generic_bar then return end
                generic_bar:setVisible(false)
                
                MinimalDisplayBars.configTables[generic_bar.coopNum][generic_bar.idName]["isVisible"] = false
                MinimalDisplayBars.io_persistence.store(
                    generic_bar.fileSaveLocation, 
                    MinimalDisplayBars.MOD_ID, 
                    MinimalDisplayBars.configTables[generic_bar.coopNum])
                
                -- recreate MoveBarsTogether panel when hiding a display bar
                MinimalDisplayBars.createMoveBarsTogetherPanel(generic_bar.playerIndex)
                
                return
            end
        )
        
    end
    
end


--=============================================
-- UI

local playerIndices = {} -- added for split-screen support

-- added for split-screen support
local function OnBootGame() 
    playerIndices = {}
    --numOfLocalClients = 0
end

-- added for split-screen support
local function OnLocalPlayerDisconnect(isoPlayer)
    if getPlayer():isLocalPlayer() then
    
        --[[numOfLocalClients = numOfLocalClients - 1
        if numOfLocalClients < 0 then 
            numOfLocalClients = 0 
        end]]
        
        for k, v in pairs(playerIndices) do
            if playerIndices[k] == isoPlayer:getPlayerNum() + 1 then
                table.remove(playerIndices, k)
                break
            end
        end
        
    end
end

-- added for split-screen support
--[[local function OnLocalPlayerDeath(isoPlayer)
    if isoPlayer:isLocalPlayer() then
        numOfLocalClients = numOfLocalClients - 1
        if numOfLocalClients < 0 then 
            numOfLocalClients = 0 
        end
    end
end]]


-- Give default settings to config opts.
--[[MinimalDisplayBars.configFileLocations[1] = MinimalDisplayBars.configFileName
MinimalDisplayBars.configFileLocations[2] = MinimalDisplayBars.configFileName .. " P2.lua"
MinimalDisplayBars.configFileLocations[3] = MinimalDisplayBars.configFileName .. " P3.lua"
MinimalDisplayBars.configFileLocations[4] = MinimalDisplayBars.configFileName .. " P4.lua"

MinimalDisplayBars.configTables[1] = MinimalDisplayBars.io_persistence.load(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID)
MinimalDisplayBars.configTables[2] = MinimalDisplayBars.io_persistence.load(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID)
MinimalDisplayBars.configTables[3] = MinimalDisplayBars.io_persistence.load(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID)
MinimalDisplayBars.configTables[4] = MinimalDisplayBars.io_persistence.load(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID)

for i=1, 4, 1 do 
    if not deepcompare(MinimalDisplayBars.configTables[i], DEFAULT_SETTINGS, false) then
        MinimalDisplayBars.io_persistence.store(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID, DEFAULT_SETTINGS)
        MinimalDisplayBars.configTables[i] = MinimalDisplayBars.io_persistence.load(MinimalDisplayBars.defaultSettingsFileName, MinimalDisplayBars.MOD_ID)
    end
end

-- Removes this table from memory.
DEFAULT_SETTINGS = nil
]]

-- Function that will create all of the display bars for a given ISOPlayer.
local function createUiFor(playerIndex, isoPlayer)
    
    -- Make sure this is a local player only.
    if not isoPlayer:isLocalPlayer() then return end

    
    -- Split-screen support
    local xOffset = getPlayerScreenLeft(playerIndex)
    local yOffset = getPlayerScreenTop(playerIndex)
    
    local coopNum = playerIndex + 1
    
    local isAlreadySpawned = false
    for k, v in pairs(playerIndices) do
        if playerIndices[k] == (coopNum) then
            isAlreadySpawned = true
            break
        end
    end
    if not isAlreadySpawned then table.insert(playerIndices, coopNum) end
    
    if playerIndices[1] == coopNum then
        MinimalDisplayBars.configFileLocations[coopNum] = MinimalDisplayBars.configFileName
    elseif playerIndices[2] == coopNum then
        MinimalDisplayBars.configFileLocations[coopNum] = MinimalDisplayBars.configFileName .. " P2.lua"
    elseif playerIndices[3] == coopNum then
        MinimalDisplayBars.configFileLocations[coopNum] = MinimalDisplayBars.configFileName .. " P3.lua"
    elseif playerIndices[4] == coopNum then
        MinimalDisplayBars.configFileLocations[coopNum] = MinimalDisplayBars.configFileName .. " P4.lua"
    else
        MinimalDisplayBars.configFileLocations[coopNum] = MinimalDisplayBars.configFileName .. " P_wildcard.lua"
    end
    
    MinimalDisplayBars.configTables[coopNum] = 
        MinimalDisplayBars.io_persistence.load(
            MinimalDisplayBars.defaultSettingsFileName, 
            MinimalDisplayBars.MOD_ID)
    
    if not deepcompare(MinimalDisplayBars.configTables[coopNum], DEFAULT_SETTINGS, false) then
        print("Configuration tables do not match. Storing default settings.")
            print("defaultSettingsFileName: ", MinimalDisplayBars.defaultSettingsFileName)
            print("MOD_ID: ", MinimalDisplayBars.MOD_ID)
            -- print("DEFAULT_SETTINGS: ", DEFAULT_SETTINGS)
    
        MinimalDisplayBars.io_persistence.store(
            MinimalDisplayBars.defaultSettingsFileName, 
            MinimalDisplayBars.MOD_ID, 
            DEFAULT_SETTINGS)
        MinimalDisplayBars.configTables[coopNum] = 
            MinimalDisplayBars.io_persistence.load(
                MinimalDisplayBars.defaultSettingsFileName, 
                MinimalDisplayBars.MOD_ID)
    end
    
    --if isoPlayer:isLocalPlayer() then numOfLocalClients = numOfLocalClients + 1 end
    --numOfLocalClients = numOfLocalClients + 1
    --local coopNum = numOfLocalClients
    --local listOfPlayers = getPlayer():getPlayers()
    --print(type(listOfPlayers))
    --for k, v in ipairs(listOfPlayers) do
    --    numOfLocalClients = numOfLocalClients + 1
    --end
    --print(listOfPlayers)
    --numOfLocalClients = math.floor(listOfPlayers:size())
    
    
    -- MoodletThresholdTables
    local moodletThresholdTables = getMoodletThresholdTables()
    
    
    --===============================================================================
    -- Get/Setup all configuration settings from the config file.
    local t_restored = 
        MinimalDisplayBars.io_persistence.load(
            MinimalDisplayBars.configFileLocations[coopNum], 
            MinimalDisplayBars.MOD_ID)
    
    if not MinimalDisplayBars.compare_and_insert(MinimalDisplayBars.configTables[coopNum], t_restored, true) then
        MinimalDisplayBars.io_persistence.store(
            MinimalDisplayBars.configFileLocations[coopNum], 
            MinimalDisplayBars.MOD_ID, 
            t_restored)
    end

    if t_restored then 
        MinimalDisplayBars.configTables[coopNum] = t_restored 
    else 
        MinimalDisplayBars.configTables[coopNum] = recreateConfigFiles(coopNum)
    end
    
    -- Prevents Display bars from covering player 2-3-4's inventory and other options.
    --[[if coopNum >= 2 then
        for k, _ in pairs(MinimalDisplayBars.configTables[coopNum]) do 
            if type(MinimalDisplayBars.configTables[coopNum][k]) == "table" then
                if k ~= "menu" then 
                    print(k .. " " .. tostring(k ~= "menu"))
                    MinimalDisplayBars.configTables[coopNum][k]["alwaysBringToTop"] = false
                end
            end
        end 
    end]]
    
    --==================================
    -- Create Display Bars
    
    --[[ === REFERENCE ===
    someBar must be created above the ContextMenu. local someBar = {}
    someBar = ISGenericMiniDisplayBar:new(
        idName, 
        fileSaveLocation,  
        playerIndex, isoPlayer, coopNum, 
        configTable, 
        xOffset, yOffset, 
        bChild, 
        valueFunction, 
        colorFunction, useColorFunction,
        moodletThresholdTable)
    ]]
    --====================
    
    local idName1 = "menu"
    local bar1 = ISGenericMiniDisplayBar:new(
        idName1, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        function(tIsoPlayer) 
            if tIsoPlayer:isDead() then return -1 else return 1 end 
        end,
        nil, false,
        nil)
    bar1:initialise()
    bar1:addToUIManager()
    
    local idName2 = "hp"
    local bar2 = ISGenericMiniDisplayBar:new(
        idName2, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getHealth,
        getColorHealth, true,
        nil)
        --moodletThresholdTables[idName2])
    bar2:initialise()
    bar2:addToUIManager()
    
    local idName3 = "hunger"
    local bar3 = ISGenericMiniDisplayBar:new(
        idName3, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getHunger,
        getColorHunger, true,
        moodletThresholdTables[idName3])
    bar3:initialise()
    bar3:addToUIManager()
    
    local idName4 = "thirst"
    local bar4 = ISGenericMiniDisplayBar:new(
        idName4, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getThirst,
        getColorThirst, true,
        moodletThresholdTables[idName4])
    bar4:initialise()
    bar4:addToUIManager()
    
    local idName5 = "endurance"
    local bar5 = ISGenericMiniDisplayBar:new(
        idName5, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getEndurance,
        getColorEndurance, true,
        moodletThresholdTables[idName5])
    bar5:initialise()
    bar5:addToUIManager()
    
    local idName6 = "fatigue"
    local bar6 = ISGenericMiniDisplayBar:new(
        idName6, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getFatigue,
        getColorFatigue, true,
        moodletThresholdTables[idName6])
    bar6:initialise()
    bar6:addToUIManager()
    
    local idName7 = "boredomlevel"
    local bar7 = ISGenericMiniDisplayBar:new(
        idName7, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getBoredomLevel,
        getColorBoredomLevel, true,
        moodletThresholdTables[idName7])
    bar7:initialise()
    bar7:addToUIManager()

    local idName8 = "stress"
    local bar8 = ISGenericMiniDisplayBar:new(
        idName8, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getStress,
        getColorStress, true,
        moodletThresholdTables[idName8])
    bar8:initialise()
    bar8:addToUIManager() 
    
    local idName9 = "unhappynesslevel"
    local bar9 = ISGenericMiniDisplayBar:new(
        idName9, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], xOffset, yOffset, 
        nil, 
        getUnhappynessLevel,
        getColorUnhappynessLevel, true,
        moodletThresholdTables[idName9])
    bar9:initialise()
    bar9:addToUIManager()

    local idName10 = "discomfortlevel"
    local bar10 = ISGenericMiniDisplayBar:new(
        idName10, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], xOffset, yOffset, 
        nil, 
        getDiscomfortLevel,
        getColorDiscomfortLevel, true,
        moodletThresholdTables[idName10])
    bar10:initialise()
    bar10:addToUIManager()
    
    local idName11 = "temperature"
    local bar11 = ISGenericMiniDisplayBar:new(
        idName11, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getTemperature,
        getColorTemperature, true,
        moodletThresholdTables[idName11])
    bar11:initialise()
    bar11:addToUIManager()
    
    local idName12 = "calorie"
    local bar12 = ISGenericMiniDisplayBar:new(
        idName12, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getCalorie,
        getColorCalorie, true,
        nil)
    bar12:initialise()
    bar12:addToUIManager()
    
    local idName13 = "carbohydrates"
    local bar13 = ISGenericMiniDisplayBar:new(
        idName13, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getCarbohydrates,
        getColorCarbohydrates, true,
        nil)
    bar13:initialise()
    bar13:addToUIManager()

    local idName14 = "proteins"
    local bar14 = ISGenericMiniDisplayBar:new(
        idName14, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getProteins,
        getColorProteins, true,
        nil)
        -- moodletThresholdTables[idName14])
    bar14:initialise()
    bar14:addToUIManager()

    local idName15 = "lipids"
    local bar15 = ISGenericMiniDisplayBar:new(
        idName15, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getLipids,
        getColorLipids, true,
        nil)
    bar15:initialise()
    bar15:addToUIManager()
	
	local idName16 = "sickness"
    local bar16 = ISGenericMiniDisplayBar:new(
        idName16, 
        MinimalDisplayBars.configFileLocations[coopNum], 
        playerIndex, isoPlayer, coopNum, 
        MinimalDisplayBars.configTables[coopNum], 
        xOffset, yOffset, 
        nil, 
        getSickness,
        getColorSickness, true,
        moodletThresholdTables[idName16])
    bar16:initialise()
    bar16:addToUIManager()  
    
    
    -- Add all valid display bars to a Global varible to be shared.
    MinimalDisplayBars.displayBars[playerIndex] = 
    {
        [idName2] = bar2,
        [idName3] = bar3,
        [idName4] = bar4,
        [idName5] = bar5,
        [idName6] = bar6,
        [idName7] = bar7,
        [idName8] = bar8,
        [idName9] = bar9,
        [idName10] = bar10,
        [idName11] = bar11,
        [idName12] = bar12,
        [idName13] = bar13,
        [idName14] = bar14,
        [idName15] = bar15,
		[idName16] = bar16,
    }
    
    ------------------------------------------------------------------------------
    -- required fix for any Horizontal Bars from 4.3.0 and versions below 4.3.0
    local data = MinimalDisplayBars.LoadFromFile("_horizontalbarfix")
    if not data or data[1] == nil then 
        data = {} end
    
    if data[1] ~= "fixed" then
        for _, bar in pairs(MinimalDisplayBars.displayBars[playerIndex]) do
            if bar then 
                if bar.isVertical then
                    if bar.width > bar.height then
                        local oldW = tonumber(bar.oldWidth)
                        local oldH = tonumber(bar.oldHeight)
                        bar:setWidth(oldH)
                        bar:setHeight(oldW)
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["width"] = oldH
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["height"] = oldW
                    end
                else
                    if bar.width < bar.height then
                        local oldW = tonumber(bar.oldWidth)
                        local oldH = tonumber(bar.oldHeight)
                        bar:setWidth(oldH)
                        bar:setHeight(oldW)
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["width"] = oldH
                        MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["height"] = oldW
                    end
                end
            end
        end
        
        -- store options
        MinimalDisplayBars.io_persistence.store(
            MinimalDisplayBars.configFileLocations[coopNum], 
            MinimalDisplayBars.MOD_ID, 
            MinimalDisplayBars.configTables[coopNum])
        
        MinimalDisplayBars.SaveToFile("_horizontalbarfix", "fixed")
    end
    ------------------------------------------------------------------------------
    
    -- Make sure bars are all toggled correctly when new bars are added.
    for _, bar in pairs(MinimalDisplayBars.displayBars[playerIndex]) do
        if bar then 
            
            -- Override settings
            MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["imageName"] = DEFAULT_SETTINGS[bar.idName]["imageName"]
            bar.imageName = DEFAULT_SETTINGS[bar.idName]["imageName"]
            -- MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["imageSize"] = DEFAULT_SETTINGS[bar.idName]["imageSize"]
            -- bar.imageSize = DEFAULT_SETTINGS[bar.idName]["imageSize"]
            MinimalDisplayBars.configTables[bar.coopNum][bar.idName]["imageShowBack"] = DEFAULT_SETTINGS[bar.idName]["imageShowBack"]
            bar.imageShowBack = DEFAULT_SETTINGS[bar.idName]["imageShowBack"]
            
            local barHP = MinimalDisplayBars.displayBars[playerIndex]["hp"]
            
            -- Make sure bars are toggled correctly
            if barHP.moveWithMouse ~= bar.moveWithMouse then
                toggleMovable(bar) end
            if barHP.resizeWithMouse ~= bar.resizeWithMouse then
                toggleResizeable(bar) end
            if barHP.alwaysBringToTop ~= bar.alwaysBringToTop then
                toggleAlwaysBringToTop(bar) end
            if barHP.showMoodletThresholdLines ~= bar.showMoodletThresholdLines then
                toggleMoodletThresholdLines(bar) end
            if barHP.isCompact ~= bar.isCompact then
                toggleCompact(bar) end
            if barHP.moveBarsTogether ~= bar.moveBarsTogether then
                toggleMoveBarsTogether(bar) end
            -- if barHP.showImage ~= bar.showImage then
            --     toggleShowImage(bar) end
        end
    end
    
    -- Create MoveBarsTogether Panel.
    MinimalDisplayBars.createMoveBarsTogetherPanel(playerIndex)
    
end

Events.OnRenderTick.Add(preventContextCoverup)

Events.OnGameBoot.Add(OnBootGame)
Events.OnDisconnect.Add(OnLocalPlayerDisconnect)
--Events.OnPlayerDeath.Add(OnLocalPlayerDeath)

Events.OnCreatePlayer.Add(createUiFor)






