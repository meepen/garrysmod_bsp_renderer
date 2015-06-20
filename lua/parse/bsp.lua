
local bsp = {};

bsp.__index = function(self, k) return getmetatable(self)[k]; end

local function unsigned(n, bits)
	if(n < 0) then 
		return math.abs(n) + 2^(bits-1);
	end
	return n;
end

function bsp:Init()
	self.file = file.Open(self.file_name, "rb", "GAME");
	assert(self.file, "file GAME/"..tostring(self.file_name).." does not exist!");

	self:ParseHeader();
	self:ParseLump0();  -- entities
	self:ParseLump1();  -- planes
	self:ParseLump3();  -- vertices
	self:ParseLump12(); -- edges
	self:ParseLump13(); -- surfedges
	self:ParseLump7();  -- edges
	self:ParseLump2();  -- texdata
	self:ParseLump6();  -- texinfo
	self:ParseLump14();
	
	
end

function bsp:CanInit() return self.file_name ~= nil end

function bsp:ParseHeader()
	local header = {lumps = {}};
	self.file:Seek(0);
	header.ident = self.file:Read(4);
	assert(header.ident == "VBSP", "entered incorrect map file '"..self.file_name.."'");
	header.version = self.file:ReadLong();
	for i = 0, 63 do header.lumps[i] = self:ParseLump(); end
	header.revision = self.file:ReadLong();
	self.header = header;
end

function bsp:ParseLump()
	local lump = {};
	lump.offset = self.file:ReadLong();
	lump.length = self.file:ReadLong();
	lump.version = self.file:ReadLong();
	lump.fourCC = self.file:Read(4);
	return lump;
end

function bsp:ReadPlane()
	local plane = {};
	plane.normal = Vector(self.file:ReadFloat(), self.file:ReadFloat(), self.file:ReadFloat());
	plane.distance = self.file:ReadFloat();
	plane.type = self.file:ReadLong();
	return plane;
end

function bsp:ReadFace()
	local face = {};
	face.plane = self:GetLump(1).data[unsigned(self.file:ReadShort(), 16)];
	face.side = self.file:ReadByte();
	face.node = self.file:ReadByte();
	
	face.firstedge   = self.file:ReadLong();-- surfedge index
	face.numedges    = self.file:ReadShort();
	face.textureinfo = self.file:ReadShort();
	face.dispinfo    = self.file:ReadShort();
	self.file:ReadShort();
	face.styles      = self.file:Read(4);
	face.lightmapind = self.file:ReadLong();
	face.area        = self.file:ReadFloat();
	
	self.file:ReadLong();self.file:ReadLong(); 
	self.file:ReadLong();self.file:ReadLong(); 
	self.file:ReadLong(); 
	self.file:ReadShort(); 
	self.file:ReadShort(); 
	self.file:ReadLong(); 
	return face;
end

function bsp:GetLump(i) return self.header.lumps[i]; end

function bsp:ParseLump1()
	local plane_size = 20;
	local lump = self:GetLump(1);
	lump.data = {};
	self.file:Seek(lump.offset);
	for i = 0, lump.length - 1, plane_size do
		
		lump.data[i / plane_size] = self:ReadPlane();
		
	end
	lump.parsed = true;
end

function bsp:ReadTexInfo()

	return parse.new("tex", nil, self);
	
end

function bsp:ParseLump0()

	local lump = self:GetLump(0);
	self.file:Seek(lump.offset);
	lump.datastring = self.file:Read(lump.length);
	lump.data = {};
	
	for s in lump.datastring:gmatch("%{.-%}") do
		lump.data[#lump.data + 1] = util.KeyValuesToTable('"xd"\r\n'..s);
	end

end

function bsp:ParseLump6()
	local texinfo_size = 72;
	
	local lump = self:GetLump(6);
	lump.data = {};
	self.file:Seek(lump.offset);
	
	for i = 0, lump.length - 1, texinfo_size do
		
		lump.data[i / texinfo_size] = self:ReadTexInfo();
		
	end
	
	lump.parsed = true;
end

function bsp:ParseLump2()
	local texdata_size = 32;
	local lump = self:GetLump(2);
	lump.data = {};
	self.file:Seek(lump.offset);
	
	for i = 0, lump.length - 1, texdata_size do
	
		local r = {};
		r.reflectivity = Vector(self.file:ReadFloat(), self.file:ReadFloat(), self.file:ReadFloat());
		r.stringtableid = self.file:ReadLong();
		r.w, r.h = self.file:ReadLong(), self.file:ReadLong();
		self.file:ReadLong();
		self.file:ReadLong();
		
		local old = self.file:Tell();
		self.file:Seek(self:GetLump(44).offset + 4 * r.stringtableid);
		
		r.stringtableidx = self.file:ReadLong();
		
		self.file:Seek(self:GetLump(43).offset + r.stringtableidx);
		
		r.name = "";
		for i = 1, 260 do
			local chr = string.char(self.file:ReadByte());
			if(chr == '\x00') then break; end
			r.name = r.name..chr;
		end
	
		lump.data[i / texdata_size] = r;
		self.file:Seek(old);
		
	end
	
	lump.parsed = true;
end

function bsp:ParseLump3()
	local vector_size = 12;
	local lump = self:GetLump(3);
	self.file:Seek(lump.offset);
	lump.data = {};
	
	for i = 0, lump.length - 1, vector_size do
	
		lump.data[i / vector_size] = Vector(self.file:ReadFloat(), self.file:ReadFloat(), self.file:ReadFloat());
	
	end
	
	lump.parsed = true;
end

function bsp:ParseLump12()
	local edge_size = 4; -- two shorts
	
	local lump = self:GetLump(12);
	self.file:Seek(lump.offset);
	lump.data = {};
	
	for i = 0, lump.length - 1, edge_size do
		lump.data[i/edge_size] = {
			[0] = unsigned(self.file:ReadShort(), 16),
			[1] = unsigned(self.file:ReadShort(), 16)
		};
	end
	
	lump.parsed = true;
end

function bsp:ParseLump7()
	local face_size = 56;
	
	local lump = self:GetLump(7);
	self.file:Seek(lump.offset);
	lump.data = {};
	
	
	for i = 0, lump.length - 1, face_size do
		
		lump.data[i / face_size] = self:ReadFace();
	
	end
	lump.parsed = true;
end

function bsp:ParseLump13()
	local int_size = 4;
	
	local lump = self:GetLump(13);
	self.file:Seek(lump.offset);
	lump.data = {};
	
	for i = 0, lump.length - 1, int_size do
	
		local n = self.file:ReadLong();
		lump.data[i / int_size] = {math.abs(n), n >= 0};
	
	end
	
	lump.parsed = true;
end

function bsp:ParseLump14()
	local int_size = 48;
	
	local lump = self:GetLump(14);
	self.file:Seek(lump.offset);
	lump.data = {};
	
	for i = 0, lump.length - 1, int_size do
	
		local r = {};
		r.mins = Vector(self.file:ReadFloat(), self.file:ReadFloat(), self.file:ReadFloat());
		r.maxs = Vector(self.file:ReadFloat(), self.file:ReadFloat(), self.file:ReadFloat());
		r.origin = Vector(self.file:ReadFloat(), self.file:ReadFloat(), self.file:ReadFloat());
		r.node = self.file:ReadLong();
		
		r.firstface = self.file:ReadLong();
		r.numfaces = self.file:ReadLong();
		
		lump.data[i / int_size] = r;
	
	end
	
	lump.parsed = true;
end

parse.register("bsp", bsp);