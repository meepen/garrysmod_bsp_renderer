


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
	
	local material_mesh_lookup = {};
	local material_list = {};
	
	local l7  = self:GetLump(7);
	local l13 = self:GetLump(13);
	local l12 = self:GetLump(12);
	local l3  = self:GetLump(3);
	local l6  = self:GetLump(6);

	for k = 0, #l7.data do
		local v = l7.data[k];
		if(l6.data[v.textureinfo].texdata.name:sub(1,6):lower() == "tools/") then continue; end
		local mat = l6.data[v.textureinfo]:GetMaterial(divisor);
		
		material_list[l6.data[v.textureinfo].texdata.name] = material_list[l6.data[v.textureinfo].texdata.name] or {};
		table.insert(material_list[l6.data[v.textureinfo].texdata.name], v);
		
	end
	
	for _, coal in next, material_list, nil do
	
		local _mesh = Mesh();
		local mat = l6.data[coal[1].textureinfo];
		
		meshes[#meshes + 1] = _mesh;
		materials[#meshes] = mat:GetMaterial(divisor);
		
		local amt = 0;
		for i = 1, #coal do
			local v = coal[i];
			amt = amt + v.numedges - 2;
		end
		
		mesh.Begin(_mesh, MATERIAL_TRIANGLES, amt);
		for i = 1, #coal do
			local v = coal[i];
					
			local last,first;
			for i = 0, v.numedges - 1 do
				
				
				
				local edgeidx = l13.data[v.firstedge + i];
				
				local edgesidx = l12.data[edgeidx[1]];
				
				local edge1, edge2 = l3.data[edgesidx[0]], self:GetLump(3).data[edgesidx[1]];
				
				local whatiwant = edgeidx[2] and edge2 or edge1;
				if(not whatiwant) then continue; end
				
				if(not first) then first = whatiwant / divisor; continue; end
				if(not last) then last = whatiwant / divisor; continue; end
				
				
				mesh.TexCoord(0, mat:GenerateUV(first.x, first.y, first.z, divisor));
				mesh.Position(first);
				mesh.AdvanceVertex();
				mesh.TexCoord(0, mat:GenerateUV(last.x, last.y, last.z, divisor));
				mesh.Position(last);
				mesh.AdvanceVertex();
				
				mesh.TexCoord(0, mat:GenerateUV(whatiwant.x, whatiwant.y, whatiwant.z, divisor));
				whatiwant = whatiwant / divisor;
				mesh.Position(whatiwant);
				mesh.AdvanceVertex();
				
				last = whatiwant;
			
			end
			
		end
		mesh.End();
	end
	
	for k,v in next, self:GetLump(0).data do
		if(v.model and v.origin and v.angles) then
			local e = ClientsideModel(v.model);
			e:Spawn();
			e:SetNoDraw(true);
			
			e:SetRenderOrigin(util.StringToType(v.origin, "Vector") / divisor);
			e:SetRenderAngles(util.StringToType(v.angles, "Angle"));
			e:SetModelScale(1/divisor, 0);
			e:SetSkin(tonumber(v.skin or 0) or 0);
			
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