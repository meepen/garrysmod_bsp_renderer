


local meshes = {};
local materials = {};
local ents = {};
local divisor = 25; -- 1/4 scale
local pos, ang;

local function trinorm(p1,p2,p3)
	local u = p2 - p1;
	local v = p3 - p1;
	return Vector(
		u.y*v.z - u.z*v.y,
		u.z*v.x - u.x*v.z,
		u.x*v.y - u.y*v.x
	);
end

local function buildtriangle(triangles, buf, vertex, u, v)

	buf[#buf + 1] = {
		pos = vertex/divisor, 
		u   = u, 
		v   = v,
	};
	
	if(#buf == 3) then
		for i = 1, 3 do
			triangles[#triangles + 1] = buf[i];
		end
		
		table.remove(buf, 2);
		
	end
	

end

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
		
		local name = l6.data[v.textureinfo];
		--name = name.." "..tostring(v.w).." "..tostring(v.h).." "..tostring(v.plane.normal);
		material_list[name] = material_list[name] or {};
		--local str = tostring(v.plane.normal);
		--material_list[name][str] = material_list[name][str] or {};
		table.insert(material_list[name], v);
		
	end
	
	local light_normal = Vector(0,0,0);
	
	for _, coal in next, material_list, nil do
		local triangles = {};
		
		local mat = l6.data[coal[1].textureinfo];
	
		local _mesh = Mesh(mat);
		
		meshes[#meshes + 1] = _mesh;
		materials[#meshes] = mat:GetMaterial(divisor);
		
		for i = 1, #coal do
			local v = coal[i];
			
			local buf = {}; -- 3 vertices
			
			for i = 0, v.numedges - 1 do
				
				local edgeidx = l13.data[v.firstedge + i];
				
				local edgesidx = l12.data[edgeidx[1]];
				
				local edge1, edge2 = l3.data[edgesidx[0]], l3.data[edgesidx[1]];
				
				local first = edgeidx[2] and edge1 or edge2;
				local second = edgeidx[2] and edge2 or edge1;
				
				
				local u,v = mat:GenerateUV(first.x, first.y, first.z);
				buildtriangle(triangles, buf, first, u, v);
				
				
				local u,v = mat:GenerateUV(second.x, second.y, second.z);
				buildtriangle(triangles, buf, second, u, v);
				
			
			end
			
		end
		_mesh:BuildFromTriangles(triangles);
	end
	
	for k,v in next, self:GetLump(0).data do
		if(v.model and v.origin and v.angles) then
			local e = ClientsideModel(v.model);
			e:SetNoDraw(true);
			
			e:SetRenderOrigin(util.StringToType(v.origin, "Vector") / divisor);
			e:SetRenderAngles(util.StringToType(v.angles, "Angle"));
			e:SetModelScale(1/divisor, 0);
			e:SetSkin(tonumber(v.skin or 0) or 0);
			
			ents[#ents + 1] = e;
			e:Spawn();
			
		end
	end
	
end);

local nmeshes = 0;
local time = 0;
local entities = 0;
local meshtime = 0;
local entitytime = 0;
local lasttime = SysTime();
local updatetime = .25;

hook.Add("HUDPaint", "", function()
	
	surface.SetTextColor(255,255,255,255);
	surface.SetFont("BudgetLabel");
	surface.SetTextPos(3,2);
	surface.DrawText(("render time: %.6f (%i meshes, %i entities)"):format(time, nmeshes, entities));
	surface.SetTextPos(2,10);
	surface.DrawText(("mesh time: %.6f, entity time: %.6f"):format(meshtime, entitytime));
	
end);
	
hook.Add("PreDrawOpaqueRenderables", "", function()
	if(not ang) then ang = Angle(0,0,0); end
	if(not pos) then return; end
	local t = SysTime();
	local et, mt;
	ang.y = math.NormalizeAngle(ang.y + 0 * FrameTime());
	render.PushFilterMag(TEXFILTER.ANISOTROPIC);
	render.PushFilterMin(TEXFILTER.ANISOTROPIC);
	render.SetLightingMode(2);
		
		local change_pos, change_ang;
		change_ang = ang;
		change_pos = EyePos() - pos;
		change_pos:Rotate(change_ang);
		
		cam.Start3D(change_pos, EyeAngles() + change_ang);
			mt = SysTime();
			for i = 1, #meshes do
				
				render.SetMaterial(materials[i]);
				meshes[i]:Draw();
				
			end
			
			mt = SysTime() - mt;
			
			et = SysTime();
			for i = 1, #ents do
				local v = ents[i];
				v:SetNoDraw(false); -- do i have to do this?
				v:DrawModel();
				v:SetNoDraw(true);
			end
			et = SysTime() - et;
		cam.End3D();
		
	render.SetLightingMode(0);
	render.PopFilterMin();
	render.PopFilterMag();
	
	t = SysTime() - t;
	
	if(SysTime() - lasttime > updatetime) then
		nmeshes = #meshes;
		entities = #ents;
		time = t;
		entitytime = et;
		meshtime = mt;
		lasttime = SysTime();
		
	end
	
end);