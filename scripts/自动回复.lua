--注册串口接收函数
uartReceive = function (data)
    sys.publish("UART",data)--发布消息
end

function CRC16_MODBUS(Data)
	local DataLen = #Data
	local CRCin = 0xFFFF
    local CRCData = 0
	local DataByte = 0
	for j=1,DataLen/2,1 do
		--DataByte = string.byte(Data,j)
		local hex=string.sub(Data,(j-1)*2+1,(j-1)*2+2)
		local DataByte=string.byte(string.fromHex(hex))
		CRCin = (CRCin ~ DataByte) & 0xFFFF
		for i=1,8,1 do
			if ((CRCin & 0x0001) > 0) then
				CRCin = CRCin >> 1
                CRCin = (CRCin ~ 0xA001) & 0xFFFF
			else
				CRCin = CRCin >> 1
			end	
		end
	end
    CRCData = (CRCin >> 8) & 0xFF
    CRCData = CRCData | ((CRCin & 0xFF) << 8)
	return CRCData
end



--自动回复
--例如收到 05 03 02 58 00 04 C5 E6
--自动回复 05 03 08 00 00 41 B4 00 00 41 B4 0F CB
sys.taskInit(function()
    while true do
        --等待消息，超时1000ms
        local r,udata = sys.waitUntil("UART",1000)
        if r then
        	local receiveHex=string.toHex(udata," ")
        	log.info("收到:",receiveHex)
        	local first_sub = string.sub(string.toHex(udata," "), 1, 2)
        	local str=first_sub .. "0308000041B4000041B4" 
        	local datacrc=CRC16_MODBUS(str)
        	str=str .. string.format("%04X",datacrc)
        	
            --发送串口消息，并获取发送结果
            local sendResult = apiSendUartData(str:fromHex())
            local sendHex=string.toHex(str:fromHex()," ")
            log.info("回复:",sendHex)
        end
    end
end)