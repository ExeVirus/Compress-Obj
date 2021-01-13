--    ____                                                ____  _     _ 
--  / ____|                                              / __ \| |   (_)
-- | |     ___  _ __ ___  _ __  _ __ ___  ___ ___ ______| |  | | |__  _ 
-- | |    / _ \| '_ ` _ \| '_ \| '__/ _ \/ __/ __|______| |  | | '_ \| |
-- | |___| (_) | | | | | | |_) | | |  __/\__ \__ \      | |__| | |_) | |
--  \_____\___/|_| |_| |_| .__/|_|  \___||___/___/       \____/|_.__/| |
--                       | |                                        _/ |
--                       |_|                                       |__/ 
--
--              Obj File "compression" utility by ExeVirus
--
---                   Copyright 2020, ExeVirus
-- 			    MIT License
--
--			See Readme.txt for usage or 
--                          compress.lua -h

----------------------------------------
--
--         fileExists(name)
--
-- name: filename to check
-- 
-- returns true or false
----------------------------------------
function fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

----------------------------------------
--
--         getSize(filename)
--
-- filename: filename to check size of
-- 
-- returns number of bytes in file
----------------------------------------
local function getSize(filename)
	local f = io.open(filename,"r")
	local bytes = f:seek("end")
	io.close(f)
	return bytes
end

----------------------------------------
--
--         setDefaults(input)
--
-- input: an empty table
-- sets up the default values for Compress-Obj
--
----------------------------------------
local function setDefaults(input)
	input.infile    = ""
	input.outfile   = ""
	input.precision = 6
	input.comments  = false
	return input
end

----------------------------------------
--
--         printUsage()
--
--
-- Prints Compress.lua usage to console and quits
----------------------------------------
local function printUsage()
print([[
-----------------------------------------------
Compress.lua usage:

	-f <filename>
		filename is the file to compress
		
	-o <filename>
		the filename of the output (default is to overwrite original file)
	
	-precision <number>
		Specify the precision of decimals to output for all values (1-6). Default is 
		6, smallest file size is 1. Typically a good number for most use cases 
		is 2 or 3. This is a lossy operation!
	
	-comments
		Keep comments in the file. (removed by default)
		
	-h
		Show this Message
	
-----------------------------------------------
]])
end

----------------------------------------
--
--         parseArgs(args, current)
--
-- args: from main user lua call
-- current: the current argument being parsed
-- input: table to set args to
-- Parses user input arguments recursively
----------------------------------------
local function parseArgs(args, current, input)
	local parseVal = tostring(args[current])
	if parseVal == "-f" then
		local filename = tostring(args[current+1])
		if fileExists(filename) == false then
			print("Bad argument -f: Input file not specified or does not exist")
			return false
		end
		input.infile = filename
		current = current + 2
	elseif parseVal == "-o" then
		local filename = tostring(args[current+1])
		if filename == "" then
			print("Bad argument -o: You did not specify a valid filename string")
			return false
		end
		input.outfile = filename
		current = current + 2
	elseif parseVal == "-precision" then
		local number = tonumber(args[current+1])
		if number < 1 or number > 6 then
			print("Bad argument -precision: Please specify a number between 1 and 6")
			return false
		end
		input.precision = number
		current = current + 2
	elseif parseVal == "-comments" then
		input.comments = true
		current = current + 1
	else
		printUsage()
		return false
	end
	if current <= #args then input = parseArgs(args, current, input) end --recurse back through
	if input.outfile == "" then input.outfile = input.infile end --Default
	return input
end

-- http://wiki.interfaceware.com/534.html
local function string_split(s, d)
    local t = {}
    local i = 0
    local f
    local match = '(.-)' .. d .. '()'

    if string.find(s, d) == nil then
        return {s}
    end

    for sub, j in string.gmatch(s, match) do
        i = i + 1
        t[i] = sub
        f = j
    end

    if i ~= 0 then
        t[i+1] = string.sub(s, f)
    end

    return t
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

----------------------------------------
--
--         strip(tostrip)
--
-- tostrip: string to remove needless information
-- Removes any trailing 0000's 
--
-- For example, "1.00000" becomes "1" 
-- and "1.100" becomes "1.1"
--
-- Also removes the "-" in the specific case of "-0.000000"
--
----------------------------------------
local function strip(tostrip)
	local start = string.gsub(tostrip, "%.%d+", "")
	local trailing = string.gsub(tostrip, "-?%d+%.", "")
	local slen = string.len(trailing)
	
	
	--strip the 00's
	for i=slen,1,-1 do
		if string.sub(trailing,i,i) == "0" then 
			trailing = string.sub(trailing, 1, -2)
		else
			break; --No more zeros to strip
		end
	end
	
	if start == "-0" and string.len(trailing) == 0 then --special case
		return "0"
	elseif string.len(trailing) > 0 then
		return start .. "." .. trailing
	else
		return start
	end
end

----------------------------------------
--
--         compressObj()
--
--
-- Prints Compress.lua usage to console and quits
----------------------------------------
local function compressObj(_infile, _outfile, _precision, _comments)
	local infile    = _infile
	local outfile   = _outfile
	local precision = _precision
	local comments  = _comments
	local newLines  = {} --Table storing the lines of the new, compressed file
	local gval = 1 --for tracking groups
	
	local get_lines = io.lines
    local filelines = {}
    for line in get_lines(infile) do
        table.insert(filelines, line)
    end
	
	for _, _line in ipairs(filelines) do
        local l = string_split(_line, "%s+")

        if l[1] == "v" then
			local line  = "v "
			local line2 = strip(string.format("%."..precision.."f", round(tonumber(l[2]), precision)))
			local line3 = strip(string.format("%."..precision.."f", round(tonumber(l[3]), precision)))
			local line4 = strip(string.format("%."..precision.."f", round(tonumber(l[4]), precision)))
            table.insert(newLines, line .. line2 .. " " .. line3 .. " " .. line4)
        elseif l[1] == "f" then
            table.insert(newLines,_line)
        elseif l[1] == "vt" then
			local line  = "vt "
			local line2 = strip(string.format("%."..precision.."f", round(tonumber(l[2]), precision)))
			local line3 = strip(string.format("%."..precision.."f", round(tonumber(l[3]), precision)))
            table.insert(newLines, line .. line2 .. " " .. line3)
		elseif l[1] == "vn" then
			local line  = "vn "
			local line2 = strip(string.format("%."..precision.."f", round(tonumber(l[2]), precision)))
			local line3 = strip(string.format("%."..precision.."f", round(tonumber(l[3]), precision)))
            local line4 = strip(string.format("%."..precision.."f", round(tonumber(l[4]), precision)))
            table.insert(newLines, line .. line2 .. " " .. line3 .. " " .. line4)
		elseif l[1] == "g" then 
			local line = "g " .. tostring(gval)
			gval = gval + 1
			table.insert(newLines, line)
		elseif l[1] == "s" then
			table.insert(newLines, _line)
		end
    end
	
	local file = io.open(outfile,"wb")
	for _,line in ipairs(newLines) do
		file:write(line .. "\n")
	end
	io.close(file)

	return getSize(outfile);
end

--------------------------------------------------------------------
---------------------END API FUNCTIONS------------------------------
----------------------(Begin Program)------------------------------

--Read in args
args = {...}
user_input = {} --For storing user input args
setDefaults(user_input)
user_input = parseArgs(args, 1, user_input)
if user_input == false then return end --quit if function failed due to improper input

--Get original file size (in bytes):
local original_size = getSize(user_input.infile) 

--Compress file
local compressed_size = compressObj(user_input.infile, user_input.outfile, user_input.precision, user_input.comments)

print("Original File Size: " .. original_size .. " Bytes")
print("Compressed File Size: " .. compressed_size .. " Bytes")
print(string.format("%.3f %% of original file size", compressed_size/original_size*100))
