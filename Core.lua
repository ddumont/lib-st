ScrollingTable = LibStub("AceAddon-3.0"):NewAddon("st", "AceConsole-3.0");

function ScrollingTable:OnInitialize()
    self:RegisterChatCommand("st", "ChatCommand");
end

function ScrollingTable:OnEnable()
    self:Print("Enabled.");
end

function ScrollingTable:OnDisable()
    self:Print("Disabled.");
end

function ScrollingTable:ChatCommand()
	if not self.st then 
		self.st = self:CreateST();
	elseif self.st.showing then 
		self.st:Hide();
	else
		self.st:Show();
	end
end

do 
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
		local width = 12;
		for num, col in pairs(self.cols) do
			width = width + col.width;
		end
		self.frame:SetWidth(width);
		self:Refresh();
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
				self.rows[i] = row;
				local rel = self.frame;
				if i > 1 then 
					rel = self.rows[i-1];
					row:SetPoint("TOPLEFT", rel, "BOTTOMLEFT", 0, 0);
					row:SetPoint("TOPRIGHT", rel, "BOTTOMRIGHT", 0, 0);
				else
					row:SetPoint("TOPLEFT", rel, "TOPLEFT", 6, -5);
					row:SetPoint("TOPRIGHT", rel, "TOPRIGHT", -6, -5);
				end
				row:SetHeight(rowHeight);
			end
			
			if not row.cols then 
				row.cols = {};
			end
			for j = 1, #self.cols do
				local col = row.cols[j];
				if not col then 
					col = CreateFrame("Button", row:GetName().."Col"..j, row);
					row.cols[j] = col;
				
					local fs = col:CreateFontString(col:GetName().."fs", "OVERLAY", "GameFontHighlightSmall");
					if j > 1 then
						fs:SetPoint("RIGHT", col, "RIGHT", 0, 0); 
					else
						fs:SetPoint("LEFT", col, "LEFT", 0, 0);
					end
					col:SetFontString(fs);
									
					col:SetText(row:GetName().."Col"..j);
					col:SetTextColor(1.0, 0.0, 0.0, 1.0);
					col:SetPushedTextOffset(0,0);
				end	
				local rel = row;
				if j > 1 then 
					rel = row.cols[j-1];
					col:SetPoint("LEFT", rel, "RIGHT", 0, 0);
				else
					col:SetPoint("LEFT", rel, "LEFT", 0, 0);
				end
				col:SetHeight(rowHeight);
				col:SetWidth(self.cols[j].width);
			end
			j = #self.cols + 1;
			col = row.cols[j];
			while col do
				col:Hide();
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
		self:Refresh();
	end
		
	function ScrollingTable:CreateST(cols, numRows, rowHeight)
		local st = {};
		local f = CreateFrame("Frame", "ScrollTable"..framecount, UIParent);
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
		
		st.displayRows = numRows or 12;
		st.rowHeight = rowHeight or 15;
		st.cols = cols or {
			{ ["name"] = "Test 1", ["width"] = 100 }, -- [1]
			{ ["name"] = "Test 2", ["width"] = 200 }, -- [2]
			{ ["name"] = "Test 3", ["width"] = 200 }, -- [2]
		};
	
		f:SetBackdrop(ScrollPaneBackdrop);
		f:SetBackdropColor(0.1,0.1,0.1);
		f:SetPoint("CENTER",UIParent,"CENTER",0,0);
		
		-- build scroll frame
		local scrollframe = CreateFrame("ScrollFrame", f:GetName().."ScrollFrame", f, "FauxScrollFrameTemplate");
		scrollframe:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0);
		scrollframe:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 0);
		
		st.Refresh = function ()
			FauxScrollFrame_Update(scrollframe, #st.data, st.displayRows, st.rowHeight);
			local o = 0, FauxScrollFrame_GetOffset(scrollframe);
			
			for i = 1, st.displayRows do
				 
			end
		end
		
		scrollframe:SetScript("OnVerticalScroll", function()
			FauxScrollFrame_OnVerticalScroll(st.rowHeight, st.Refresh);
		end);
		
		st.data = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22};
		st:SetDisplayCols(st.cols);
		st:SetDisplayRows(st.displayRows, st.rowHeight);
		return st;
	end
end