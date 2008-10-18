ScrollingTable = LibStub("AceAddon-3.0"):NewAddon("st", "AceConsole-3.0");

function ScrollingTable:OnInitialize()
    self:RegisterChatCommand("st", "ChatCommand");
end

function ScrollingTable:ChatCommand()
	if not self.st then 
		self.st = self:CreateST();
		local data = {}
		for row = 1, 20 do
			if not data[row] then 
				data[row] = {};
			end
			for col = 1, 3 do
				if not data[row].cols then 
					data[row].cols = {};
				end
				data[row].cols[col] = { ["value"] = math.random(100) };
				-- data[row].cols[col].color    (cell text color)
			end
			-- data[row].color (row text color)
		end 
		data[5].cols[1].color = { ["r"] = 0.5, ["g"] = 1.0, ["b"] = 0.5, ["a"] = 1.0 };
		data[5].color = { ["r"] = 1.0, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 1.0 };
		self.st:SetData(data);
	elseif self.st.showing then 
		self.st:Hide();
	else
		self.st:Show();
	end
end

do 
	local defaultcolor = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 };
	local defaulthighlight = { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 };
	local lrpadding = 2.5;
	
	local ScrollPaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	};
	
	local framecount = 1; 
	
	local SetHeight = function(self)
		self.frame:SetHeight( (self.displayRows * self.rowHeight) + 10);
		self:Refresh();
	end
	
	local SetWidth = function(self)
		local width = 13;
		for num, col in pairs(self.cols) do
			width = width + col.width;
		end
		self.frame:SetWidth(width);
		self:Refresh();
	end
	
	local SetHighLightColor = function(frame, color)
		if not frame.highlight then 
			frame.highlight = frame:CreateTexture(nil, "HIGHLIGHT");
			frame.highlight:SetAllPoints(frame);
		end
		frame.highlight:SetTexture(color.r, color.g, color.b, color.a);
	end
	
	local SetBackgroundColor = function(frame, color)
		if not frame.background then 
			frame.background = frame:CreateTexture(nil, "BACKGROUND");
			frame.background:SetAllPoints(frame);
		end
		frame.background:SetTexture(color.r, color.g, color.b, color.a);
	end
	
	local SetDisplayRows = function(self, num, rowHeight)
		-- should always set columns first
		self.displayRows = num;
		self.rowHeight = rowHeight;
		if not self.rows then 
			self.rows = {};
		end
		for i = 1, num do 
			local row = self.rows[i];
			if not row then 
				row = CreateFrame("Frame", self.frame:GetName().."Row"..i, self.frame);
				row:EnableMouse(true);
				SetHighLightColor(row, self.highlight);
				
				self.rows[i] = row;
				if i > 1 then 
					row:SetPoint("TOPLEFT", self.rows[i-1], "BOTTOMLEFT", 0, 0);
					row:SetPoint("TOPRIGHT", self.rows[i-1], "BOTTOMRIGHT", 0, 0);
				else
					row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -5);
					row:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -4, -5);
				end
				row:SetHeight(rowHeight);
			end
			
			if not row.cols then 
				row.cols = {};
			end
			for j = 1, #self.cols do
				local col = row.cols[j];
				if not col then 
					col = row:CreateFontString(row:GetName().."col"..j, "OVERLAY", "GameFontHighlightSmall");
					row.cols[j] = col;
					local align = self.cols[j].align or "LEFT";
					col:SetJustifyH(align); 
				end	
				if j > 1 then 
					col:SetPoint("LEFT", row.cols[j-1], "RIGHT", 2 * lrpadding, 0);
				else
					col:SetPoint("LEFT", row, "LEFT", 2 + lrpadding, 0);
				end
				col:SetHeight(rowHeight);
				col:SetWidth(self.cols[j].width - (2 * lrpadding));
			end
			j = #self.cols + 1;
			col = row.cols[j];
			while col do
				col:Hide();
				j = j + 1;
				col = row.cols[j];
			end
		end
		
		i = num + 1;
		row = self.rows[i];
		while row do
			row:Hide();
		end
		
		self:SetHeight();
	end
	
	local SetDisplayCols = function(self, cols)
		self.cols = cols;

		local row = CreateFrame("Frame", self.frame:GetName().."Head", self.frame);
		row:SetPoint("BOTTOMLEFT", self.frame, "TOPLEFT", 4, 0);
		row:SetPoint("BOTTOMRIGHT", self.frame, "TOPRIGHT", -4, 0);
		row:SetHeight(self.rowHeight);
		row.cols = {};
		for i = 1, #cols do 
			col = CreateFrame("Button", row:GetName().."Col"..i, row);
			
			local ref = self; -- reference saved for closure
			col:SetScript("OnClick", function (self)
				for j = 1, #ref.cols do 
					if j ~= i then -- clear out all other sort marks
						ref.cols[j].sort = nil;
					end
				end
				local sortorder = "asc";
				if not ref.cols[i].sort and ref.cols[i].defaultsort then
					sortorder = ref.cols[i].defaultsort; -- sort by columns default sort first;
				elseif ref.cols[i].sort and ref.cols[i].sort:lower() == "asc" then 
					sortorder = "dsc";
				end
				ref.cols[i].sort = sortorder;
				ref:SortData();
			end);
			
			row.cols[i] = col;
			local fs = col:CreateFontString(col:GetName().."fs", "OVERLAY", "GameFontHighlightSmall");
			fs:SetAllPoints(col);
			fs:SetPoint("LEFT", col, "LEFT", lrpadding, 0);
			fs:SetPoint("RIGHT", col, "RIGHT", -lrpadding, 0);
			local align = cols[i].align or "LEFT";
			fs:SetJustifyH(align); 
			
			col:SetFontString(fs);
			fs:SetText(cols[i].name);
			fs:SetTextColor(1.0, 1.0, 1.0, 1.0);
			col:SetPushedTextOffset(0,0);
			
			if i > 1 then 
				col:SetPoint("LEFT", row.cols[i-1], "RIGHT", 0, 0);
			else
				col:SetPoint("LEFT", row, "LEFT", 2, 0);
			end
			col:SetHeight(self.rowHeight);
			col:SetWidth(cols[i].width);
			
			local color = cols[i].bgcolor;
			if (color) then 
				local colibg = "col"..i.."bg";
				local bg = self.frame[colibg]; 
				if not bg then 
					bg = self.frame:CreateTexture(nil, "OVERLAY");
					self.frame[colibg] = bg;
				end 
				bg:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 4);
				bg:SetPoint("TOPLEFT", col, "BOTTOMLEFT", 0, -4);
				bg:SetPoint("TOPRIGHT", col, "BOTTOMRIGHT", 0, -4);
				bg:SetTexture(color.r, color.g, color.b, color.a);
			end
		end
		
		self:SetWidth();
	end
	
	local Show = function(self)
		self.frame:Show();
		self.showing = true;
	end
	local Hide = function(self)
		self.frame:Hide();
		self.showing = false;
	end
	
	local SetData = function(self, data)
		self.data = data;
		if not(self.sorttable) or (#self.sorttable > #data)then 
			self.sorttable = {};
		end
		if #self.sorttable ~= #self.data then
			for i = 1, #self.data do 
				self.sorttable[i] = i;
			end
		end 
		self:SortData();
	end
		
	local SortData = function(self)
		local i, sortby = 1, nil;
		while i <= #self.cols and not sortby do
			if self.cols[i].sort then 
				sortby = i;
			end
			i = i + 1;
		end
		if sortby then 
			table.sort(self.sorttable, function(a,b)
				local cola, colb = self.data[a].cols[sortby], self.data[b].cols[sortby];
				local a1, b1 = cola.value, colb.value;
				if type(a1) == "function" then 
					a1 = a1(unpack(cola.args or {}));
				end
				if type(b1) == "function" then 
					b1 = b1(unpack(colb.args or {}));
				end
				
				if type(a1) ~= type(b1) then
					local typea, typeb = type(a1), type(b1);
					if typea == "number" and typeb == "string" then 
						if tonumber(typeb) then -- is it a number in a string?
							b1 = StringToNumber(b1); -- "" = 0
						else
							a1 = tostring(a1);
						end
					elseif typea == "string" and typeb == "number" then 
						if tonumber(typea) then -- is it a number in a string?
							a1 = StringToNumber(a1); -- "" = 0
						else
							b1 = tostring(b1);
						end
					end
				end

				if self.cols[sortby].sort:lower() == "asc" then 		
					return a1 > b1;
				else
					return a1 < b1;
				end
			end);
		end
		self:Refresh();
	end
	
	local StringToNumber = function(str)
		if str == "" then 
			return 0;
		else
			return tonumber(str)
		end
	end
	 
	function ScrollingTable:CreateST(cols, numRows, rowHeight, highlight, parent)
		local st = {};
		local f = CreateFrame("Frame", "ScrollTable"..framecount, parent or UIParent);
		framecount = framecount + 1;
		st.showing = true;
		st.frame = f;
		
		st.Show = Show;
		st.Hide = Hide;
		st.SetDisplayRows = SetDisplayRows;
		st.SetRowHeight = SetRowHeight;
		st.SetHeight = SetHeight;
		st.SetWidth = SetWidth;
		st.SetDisplayCols = SetDisplayCols;
		st.SetData = SetData;
		st.SortData = SortData;
		
		st.highlight = highlight or defaulthighlight;
		st.displayRows = numRows or 12;
		st.rowHeight = rowHeight or 15;
		st.cols = cols or {
			{
				["name"] = "Test 1",
			 	["width"] = 50,
			 	["color"] = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 1.0, ["a"] = 1.0 },
			}, -- [1]
			{ 
				["name"] = "Test 2", 
				["width"] = 50, 
				["align"] = "CENTER",
				["bgcolor"] = { ["r"] = 1.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.2 },
			}, -- [2]
			{ 
				["name"] = "Test 3", 
				["width"] = 50, 
				["align"] = "RIGHT",
				["bgcolor"] = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.5 },
			}, -- [3]
		};
		st.data = {};
	
		f:SetBackdrop(ScrollPaneBackdrop);
		f:SetBackdropColor(0.1,0.1,0.1);
		f:SetPoint("CENTER",UIParent,"CENTER",0,0);
		
		-- build scroll frame
		local scrollframe = CreateFrame("ScrollFrame", f:GetName().."ScrollFrame", f, "FauxScrollFrameTemplate");
		scrollframe:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
		scrollframe:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 0);
		
		st.Refresh = function()
			FauxScrollFrame_Update(scrollframe, #st.data, st.displayRows, st.rowHeight);
			local o = FauxScrollFrame_GetOffset(scrollframe);
			
			for i = 1, st.displayRows do
				local row = i + o;	
				if st.rows then
					for col = 1, #st.cols do
						local celldisplay = st.rows[i].cols[col];
						if st.data[row] then
							local celldata = st.data[st.sorttable[row]].cols[col];
							local color = celldata.color or st.cols[col].color or st.data[st.sorttable[row]].color or defaultcolor;
							if type(celldata.value) == "function" then 
								celldisplay:SetText( celldata.value(unpack(celldata.args or {})) );
							else
								celldisplay:SetText(celldata.value);
							end
							if type(color) == "function" then 
								color = color(unpack(celldata.colorargs or {}));
							end
							celldisplay:SetTextColor(color.r, color.g, color.b, color.a);						
						else
							celldisplay:SetText("");
						end
					end
				end
			end
		end
		
		scrollframe:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, st.rowHeight, st.Refresh);
		end);
		
		st:SetDisplayCols(st.cols);
		st:SetDisplayRows(st.displayRows, st.rowHeight);
		return st;
	end
end