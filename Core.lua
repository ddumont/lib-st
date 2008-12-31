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
				data[row].cols[col] = { ["value"] = math.random(50) };
				-- data[row].cols[col].color    (cell text color)
			end
			-- data[row].color (row text color)
		end 
		data[5].cols[1].color = { ["r"] = 0.5, ["g"] = 1.0, ["b"] = 0.5, ["a"] = 1.0 };
		data[5].color = { ["r"] = 1.0, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 1.0 };
		self.st:SetData(data);
		self.st:SetFilter(function(self, row)
			return row.cols[1].value > 10; 
		end);
		
		self.st:RegisterEvents({
			["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow and column == 2 then
					local value = data[realrow].cols[column].value;
					ScrollingTable:Print("enter! row", realrow, "col 2 value", value);
				end
			end,
			["OnLeave"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow and column == 2 then
					local value = data[realrow].cols[column].value;
					ScrollingTable:Print("leave! row", realrow, "col 2 value", value);
				end
			end,
			["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow and column == 1 then 
					local value = data[realrow].cols[column].value;
					ScrollingTable:Print("click! row", realrow, "col 1 value", value);
				elseif row and realrow then
					ScrollingTable:Print("click! row", realrow);
				end
			end,
		});
	elseif self.st.showing then 
		self.st:Hide();
	else
		self.st:Show();
	end
end

do 
	local defaultcolor = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 };
	local defaulthighlight = { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 };
	local defaulthighlightblank = { ["r"] = 0.0, ["g"] = 0.0, ["b"] = 0.0, ["a"] = 0.0 };
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
		self.frame:SetWidth(width+20);
		self:Refresh();
	end
	
	local SetHighLightColor = function(frame, color)
		if not frame.highlight then 
			frame.highlight = frame:CreateTexture(nil, "OVERLAY");
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
	
	local FireUserEvent = function (self, frame, event, handler, ...)
		if not handler( ...) then
			if self.DefaultEvents[event] then 
				self.DefaultEvents[event]( ...);
			end
		end
	end
	
	local RegisterEvents = function(self, events, fRemoveOldEvents) 
		local table = self; -- save for closure later
		
		for i, row in ipairs(self.rows) do 
			for j, col in ipairs(row.cols) do
				-- unregister old events.
				if fRemoveOldEvents and self.events then 
					for event, handler in pairs(self.events) do 
						col:SetScript(event, nil);
					end
				end
				
				-- register new ones.
				for event, handler in pairs(events) do 
					col:SetScript(event, function(cellFrame, ...)
						local realindex = table.filtered[i+table.offset];
						table:FireUserEvent(col, event, handler, row, cellFrame, table.data, table.cols, i, realindex, j, ... );
					end);
				end
			end
		end
		
		for j, col in ipairs(self.head.cols) do
			-- unregister old events.
			if fRemoveOldEvents and self.events then 
				for event, handler in pairs(self.events) do 
					col:SetScript(event, nil);
				end
			end
			
			-- register new ones.
			for event, handler in pairs(events) do 
				col:SetScript(event, function(cellFrame, ...)
					table:FireUserEvent(col, event, handler, self.head, cellFrame, table.data, table.cols, nil, nil, j, ...);
				end);
			end
		end
		self.events = events;
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
				row = CreateFrame("Button", self.frame:GetName().."Row"..i, self.frame);
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
					col = CreateFrame("Button", row:GetName().."col"..j, row);
					col.text = row:CreateFontString(col:GetName().."text", "OVERLAY", "GameFontHighlightSmall");
					row.cols[j] = col;
					local align = self.cols[j].align or "LEFT";
					col.text:SetJustifyH(align); 
					col:EnableMouse(true);
					col:RegisterForClicks("AnyUp");
					
					if self.events then 
						for event, handler in pairs(self.events) do 
							col:SetScript(event, function(cellFrame, ...)
								local realindex = table.filtered[i+table.offset];
								table:FireUserEvent(col, event, handler, row, cellFrame, table.data, table.cols, i, realindex, j, ... );
							end);
						end
					end
				end
								
				if j > 1 then 
					col:SetPoint("LEFT", row.cols[j-1], "RIGHT", 0, 0);
				else
					col:SetPoint("LEFT", row, "LEFT", 2, 0);
				end
				col:SetHeight(rowHeight);
				col:SetWidth(self.cols[j].width);
				col.text:SetPoint("TOP", col, "TOP", 0, 0);
				col.text:SetPoint("BOTTOM", col, "BOTTOM", 0, 0);
				col.text:SetWidth(self.cols[j].width - 2*lrpadding);
			end
			j = #self.cols + 1;
			col = row.cols[j];
			while col do
				col:Hide();
				j = j + 1;
				col = row.cols[j];
			end
		end
		
		for i = num + 1, #self.rows do
			self.rows[i]:Hide();
		end
		
		self:SetHeight();
	end
	
	local SetDisplayCols = function(self, cols)
		local table = self; -- reference saved for closure
		self.cols = cols;
		
		local row = self.head
		if not row then 
			row = CreateFrame("Frame", self.frame:GetName().."Head", self.frame);
			row:SetPoint("BOTTOMLEFT", self.frame, "TOPLEFT", 4, 0);
			row:SetPoint("BOTTOMRIGHT", self.frame, "TOPRIGHT", -4, 0);
			row:SetHeight(self.rowHeight);
			row.cols = {};
			self.head = row;
		end
		for i = 1, #cols do 
			local colFrameName =  row:GetName().."Col"..i;
			local col = getglobal(colFrameName);
			if not col then 
				col = CreateFrame("Button", colFrameName, row);	
				
				if self.events then 	
					for event, handler in pairs(self.events) do 
						col:SetScript(event, function(cellFrame, ...)
							table:FireUserEvent(col, event, handler, row, cellFrame, table.data, table.cols, nil, nil, i, ...);
						end);
					end
				end
			end
			row.cols[i] = col;

			local fs = col:GetFontString() or col:CreateFontString(col:GetName().."fs", "OVERLAY", "GameFontHighlightSmall");
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
		self.scrollframe:Show();
		self.showing = true;
	end
	local Hide = function(self)
		self.frame:Hide();
		self.showing = false;
	end
	
	local SetData = function(self, data)
		self.data = data;
		self:SortData();
	end
		
	local SortData = function(self)
		-- sanity check
		if not(self.sorttable) or (#self.sorttable > #self.data)then 
			self.sorttable = {};
		end
		if #self.sorttable ~= #self.data then
			for i = 1, #self.data do 
				self.sorttable[i] = i;
			end
		end 
		
		-- go on sorting
		local i, sortby = 1, nil;
		while i <= #self.cols and not sortby do
			if self.cols[i].sort then 
				sortby = i;
			end
			i = i + 1;
		end
		if sortby then 
			table.sort(self.sorttable, function(rowa, rowb)
				local column = self.cols[sortby];
				if column.comparesort then 
					return column.comparesort(self, rowa, rowb, sortby);
				else
					return self:CompareSort(rowa, rowb, sortby);
				end
			end);
		end
		self.filtered = self:DoFilter();
		self:Refresh();
	end
	
	local StringToNumber = function(str)
		if str == "" then 
			return 0;
		else
			return tonumber(str)
		end
	end
	
	local CompareSort = function (self, rowa, rowb, sortbycol)
		local cella, cellb = self.data[rowa].cols[sortbycol], self.data[rowb].cols[sortbycol];
		local a1, b1 = cella.value, cellb.value;
		local column = self.cols[sortbycol];
		if type(a1) == "function" then 
			a1 = a1(unpack(cella.args or {}));
		end
		if type(b1) == "function" then 
			b1 = b1(unpack(cellb.args or {}));
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
		
		if a1 == b1 and column.sortnext and (not(self.cols[column.sortnext].sort)) then 
			local nextcol = self.cols[column.sortnext];
			if nextcol.comparesort then 
				return nextcol.comparesort(self, rowa, rowb, column.sortnext);
			else
				return self:CompareSort(rowa, rowb, column.sortnext);
			end
		else
			local direction = column.sort or column.defaultsort or "asc";
			if direction:lower() == "asc" then 		
				return a1 > b1;
			else
				return a1 < b1;
			end
		end
	end
	
	local Filter = function(self, ...)
		return true;
	end
	
	local SetFilter = function(self, Filter)
		self.Filter = Filter;
		self:SortData();
	end
	
	local DoFilter = function(self)
		local result = {};
		for row = 1, #self.data do 
			if self:Filter(self.data[self.sorttable[row]]) then
				table.insert(result, self.sorttable[row]);
			end
		end
		return result;
	end
	
	local DoCellUpdate = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, ...)
		if fShow then
			local cellData = data[realrow].cols[column];
			
			if type(cellData.value) == "function" then 
				cellFrame.text:SetText(cellData.value(unpack(cellData.args or {})) );
			else
				cellFrame.text:SetText(cellData.value);
			end
			
			local color = cellData.color;
			local colorargs = nil;
			if not color then 
			 	color = cols[column].color;
			 	if not color then 
			 		color = data[realrow].color;
			 		if not color then 
			 			color = defaultcolor;
			 		else
			 			colorargs = data[realrow].colorargs;
			 		end
			 	else
			 		colorargs = cols[column].colorargs;
			 	end
			else
				colorargs = cellData.colorargs;
			end	
			if type(color) == "function" then 
				color = color(unpack(colorargs or {cellFrame}));
			end
			cellFrame.text:SetTextColor(color.r, color.g, color.b, color.a);
		else	
			cellFrame.text:SetText("");
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
		st.CompareSort = CompareSort;
		st.RegisterEvents = RegisterEvents;
		st.FireUserEvent = FireUserEvent;
		
		st.SetFilter = SetFilter;
		st.DoFilter = DoFilter;
		
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
		st.DefaultEvents = {
			["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow then 
					SetHighLightColor(rowFrame, st.highlight);
				end
				return true;
			end, 
			["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if row and realrow then 
					SetHighLightColor(rowFrame, defaulthighlightblank);
				end
				return true;
			end,
			["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, ...)
				if not (row or realrow) then
					for i, col in ipairs(st.cols) do 
						if i ~= column then -- clear out all other sort marks
							cols[i].sort = nil;
						end
					end
					local sortorder = "asc";
					if not cols[column].sort and cols[column].defaultsort then
						sortorder = cols[column].defaultsort; -- sort by columns default sort first;
					elseif cols[column].sort and cols[column].sort:lower() == "asc" then 
						sortorder = "dsc";
					end
					cols[column].sort = sortorder;
					st:SortData();
				end
				return true;
			end,
		};
		st.data = {};
	
		f:SetBackdrop(ScrollPaneBackdrop);
		f:SetBackdropColor(0.1,0.1,0.1);
		f:SetPoint("CENTER",UIParent,"CENTER",0,0);
		
		-- build scroll frame		
		local scrollframe = CreateFrame("ScrollFrame", f:GetName().."ScrollFrame", f, "FauxScrollFrameTemplate");
		st.scrollframe = scrollframe;
		scrollframe:Show();
		scrollframe:SetScript("OnHide", function(self, ...)
			self:Show();
		end);
		
		scrollframe:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4);
		scrollframe:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 3);
		
		local scrolltrough = CreateFrame("Frame", f:GetName().."ScrollTrough", scrollframe);
		scrolltrough:SetWidth(17);
		scrolltrough:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -3);
		scrolltrough:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4);
		scrolltrough.background = scrolltrough:CreateTexture(nil, "BACKGROUND");
		scrolltrough.background:SetAllPoints(scrolltrough);
		scrolltrough.background:SetTexture(0.05, 0.05, 0.05, 1.0);
		local scrolltroughborder = CreateFrame("Frame", f:GetName().."ScrollTroughBorder", scrollframe);
		scrolltroughborder:SetWidth(1);
		scrolltroughborder:SetPoint("TOPRIGHT", scrolltrough, "TOPLEFT");
		scrolltroughborder:SetPoint("BOTTOMRIGHT", scrolltrough, "BOTTOMLEFT");
		scrolltroughborder.background = scrolltrough:CreateTexture(nil, "BACKGROUND");
		scrolltroughborder.background:SetAllPoints(scrolltroughborder);
		scrolltroughborder.background:SetTexture(0.5, 0.5, 0.5, 1.0);
		
		st.Refresh = function(self)	
			FauxScrollFrame_Update(scrollframe, #st.filtered, st.displayRows, st.rowHeight);
			local o = FauxScrollFrame_GetOffset(scrollframe);
			st.offset = o;
			
			for i = 1, st.displayRows do
				local row = i + o;	
				if st.rows then
					for col = 1, #st.cols do
						local rowFrame = st.rows[i];
						local cellFrame = rowFrame.cols[col];
						local fShow = true;
						local fnDoCellUpdate = DoCellUpdate;
						if st.data[st.filtered[row]] then
							st.rows[i]:Show();
							local rowData = st.data[st.filtered[row]];
							local cellData = rowData.cols[col];
							if cellData.DoCellUpdate then 
								fnDoCellUpdate = cellData.DoCellUpdate;
							elseif st.cols[col].DoCellUpdate then 
								fnDoCellUpdate = st.cols[col].DoCellUpdate;
							elseif rowData.DoCellUpdate then
								fnDoCellUpdate = rowData.DoCellUpdate;
							end
						else
							st.rows[i]:Hide();
							fShow = false;
						end
						fnDoCellUpdate(rowFrame, cellFrame, st.data, st.cols, row, st.filtered[row], col, fShow);
					end
				end
			end
		end
		
		scrollframe:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, st.rowHeight, st.Refresh);
		end);
	
		st:SetFilter(Filter);
		st:SetDisplayCols(st.cols);
		st:SetDisplayRows(st.displayRows, st.rowHeight);
		st:RegisterEvents(st.DefaultEvents);
		
		return st;
	end
end