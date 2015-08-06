local tex = {};

tex.__index = function(self, k) return getmetatable(self)[k]; end

function tex:GetMaterial(scale)
	return self.Material or self:MakeMaterial();
end

function tex:MakeMaterial()
	
	self.w = self.texdata.w;
	self.h = self.texdata.h;
	
	self.Material = CreateMaterial(tostring(self).."_texinfo", "UnlitGeneric",
	{
		["$basetexture"] = Material(self.texdata.name):GetTexture("$basetexture"):GetName(),
		["$detailscale"] = 1,
		["$reflectivity"] = self.texdata.reflectivity,
		["$model"] = 1,
	});
	
	return self.Material;
end

function tex:GenerateUV(x,y,z)
	return (self.vecs[0][3] + self.vecs[0][2] * z + self.vecs[0][1] * y + self.vecs[0][0] * x) / self.texdata.w,
		(self.vecs[1][3] + self.vecs[1][2] * z + self.vecs[1][1] * y + self.vecs[1][0] * x) / self.texdata.h;
end

function tex:Init(bsp)
	
	self.vecs = {
		[0] = {}, [1] = {}
	};
	self.light = {
		[0] = {}, [1] = {}
	};
	
	self.vecs[0][0] = bsp.file:ReadFloat();
	self.vecs[0][1] = bsp.file:ReadFloat();
	self.vecs[0][2] = bsp.file:ReadFloat();
	self.vecs[0][3] = bsp.file:ReadFloat();
	
	self.vecs[1][0] = bsp.file:ReadFloat();
	self.vecs[1][1] = bsp.file:ReadFloat();
	self.vecs[1][2] = bsp.file:ReadFloat();
	self.vecs[1][3] = bsp.file:ReadFloat();
	
	self.light[0][0] = bsp.file:ReadFloat();
	self.light[0][1] = bsp.file:ReadFloat();
	self.light[0][2] = bsp.file:ReadFloat();
	self.light[0][3] = bsp.file:ReadFloat();
	
	self.light[1][0] = bsp.file:ReadFloat();
	self.light[1][1] = bsp.file:ReadFloat();
	self.light[1][2] = bsp.file:ReadFloat();
	self.light[1][3] = bsp.file:ReadFloat();
	
	
	self.flags = bsp.file:ReadLong();
	
	self.texdataid = bsp.file:ReadLong();
	
	if(self.texdataid == -1) then return; end
	
	self.texdata = bsp:GetLump(2).data[self.texdataid];
	
end


function tex:CanInit(bsp) return bsp ~= nil; end

parse.register("tex", tex);