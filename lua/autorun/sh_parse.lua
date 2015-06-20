
parse = parse or {};
parse.mts = parse.mts or {};
local mts = parse.mts;

function parse.register(type, mt)
	mts[type] = mt;
end


function parse.new(type, name, ...)
	local ret = setmetatable({
		file_name = name;
	}, mts[type]);
	
	if(ret:CanInit(...)) then ret:Init(...); end
	
	return ret;
end

local fs = file.Find("parse/*.lua", "LUA");

for k,v in pairs(fs) do

	if(SERVER) then
		AddCSLuaFile("parse/"..v);
	end
	include("parse/"..v);
	
end