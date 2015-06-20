


local meshes = {};
local materials = {};
local ents = {};
local divisor = 25; -- 1/4 scale
local pos, ang;


concommand.Add("drawmap", function(p,_,_,s)
	meshes = {};
	materials = {};
	pos = p:GetEyeTrace().HitPos + Vector(0,0,50);
	local time = SysTime;
	local t = time();
	local self = parse.new("bsp", "maps/"..s..".bsp");
	print("decode: ", ("%.6f"):format(time() - t));
	
	local l7  = self:GetLump(7);
	local l13 = self:GetLump(13);
	local l12 = self:GetLump(12);
	local l3  = self:GetLump(3);
	local l6  = self:GetLump(6);

	for k = 0, #l7.data do
		local v = l7.data[k];
		if(l6.data[v.textureinfo].texdata.name:sub(1,6):lower() == "tools/") then continue; end
		local mat = l6.data[v.textureinfo]:GetMaterial(divisor);
		
		local _mesh = Mesh();
			
		meshes[#meshes + 1] = _mesh;
		materials[#meshes] = mat;
		mesh.Begin(_mesh, MATERIAL_POLYGON, v.numedges);
		
			for i = 0, v.numedges - 1 do
			
				local edgeidx = l13.data[v.firstedge + i];
				
				local edgesidx = l12.data[edgeidx[1]];
				
				local edge1, edge2 = l3.data[edgesidx[0]], self:GetLump(3).data[edgesidx[1]];
				
				if(not edge1 or not edge2) then continue; end
				
				if(not edgeidx[2]) then
					mesh.TexCoord(0, l6.data[v.textureinfo]:GenerateUV(edge1.x, edge1.y, edge1.z, divisor));
					edge1 = edge1 / divisor;
					mesh.Position(edge1);
					mesh.AdvanceVertex();
				else
					mesh.TexCoord(0, l6.data[v.textureinfo]:GenerateUV(edge2.x, edge2.y, edge2.z, divisor));
					edge2 = edge2 / divisor;
					mesh.Position(edge2);
					mesh.AdvanceVertex();
				end
			
			end
		
		mesh.End();
	end
	
	for k,v in next, self:GetLump(0).data do
		if(v.model and v.origin and v.angles) then
			local e = ClientsideModel(v.model);
			e:Spawn();
			e:SetNoDraw(true);
			print(v.origin, util.StringToType(v.origin, "Vector") / divisor);
			e:SetRenderOrigin(util.StringToType(v.origin, "Vector") / divisor);
			e:SetRenderAngles(util.StringToType(v.angles, "Angle"));
			e:SetModelScale(1/divisor, 0);
			e:SetSkin(tonumber(v.skin or 0) or 0);
			print(v.model);
			ents[#ents + 1] = e;
			
		end
	end
	
end);
	
hook.Add("PreDrawOpaqueRenderables", "", function()
	if(not ang) then ang = Angle(0,0,0); end
	if(not pos) then return; end
	ang.y = math.NormalizeAngle(ang.y + 50 * FrameTime());
	render.PushFilterMag(TEXFILTER.ANISOTROPIC);
	render.PushFilterMin(TEXFILTER.ANISOTROPIC);
	render.SetLightingMode(2);
		
		local change_pos, change_ang;
		change_ang = ang;
		change_pos = EyePos() - pos;
		change_pos:Rotate(change_ang);
		
		cam.Start3D(change_pos, EyeAngles() + change_ang);
			for i = 1, #meshes do
				
				render.SetMaterial(materials[i]);
				meshes[i]:Draw();
				
			end
			for i = 1, #ents do
				local v = ents[i];
				v:SetNoDraw(false); -- do i have to do this?
				v:DrawModel();
				v:SetNoDraw(true);
			end
		cam.End3D();
		
	render.SetLightingMode(0);
	render.PopFilterMin();
	render.PopFilterMag();
end);