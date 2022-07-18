--  => connecto by totoetlititi
--  <=  
--  =>   CONNECT
--  <=     EXTERNAL
--  =>       SOUND
--  <=         INTERFACE
--  =>  
--  <=
--  K1 select device/srate
--  K2 change INPUT value
--  K3 change OUTPUT value
-- 
--  E1 connect
--  E2 test audio
--  E3 select device/srate
--

-- Main

engine.name = 'PolyPerc'
MusicUtil = require "musicutil"


local viewport = { width = 128, height = 64, frame = 0 }
local focus = { x = 0, y = 0 }
local script_file = "connect_device_to_jack.sh"
local config_file = "connecto/last-config.data"

local array_of_devices = {"None"}
local array_of_srate = {"11025", "22050", "44100", "48000", "96000"}
local input_device = "None"
local output_device = "None"
local input_srate = "44100"
local output_srate = "44100"

local input_device_index  = 0
local output_device_index = 0
local input_srate_index 	= 3
local output_srate_index 	= 3

local connecting_status = 0

local destination = 0 -- device/srate


function init()
  -- Render Style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
	refresh_list_of_devices()
	load_config()
  connect()
  redraw()
end


function refresh_list_of_devices()
	array_of_devices = {"None"}
	local device_index = 0;
	-- list all connected sound devices
	local get_devices_list = io.popen('cat /proc/asound/cards')
	-- read line by line
	repeat
		local raw_list = get_devices_list:read("*l")
		-- retrieve name in []
		if raw_list then 
			local device_name = string.match(raw_list, ('%[(%w+).*%]'))
			if not (device_name == "sndrpimonome" or device_name == nil) then
				table.insert(array_of_devices, device_name)
			end
		end
	until not raw_list
	for i=1, #array_of_devices do
		print('Device: '..i..' > '..array_of_devices[i])
	end
end 


function save_config()
	print("_path.data: ".._path.data)
	local file = io.open(_path.data .. config_file, "w+")
	io.output(file)
  io.write("v1" .. "\n")
  io.write(input_device .. "\n")
  io.write(input_srate .. "\n")
  io.write(output_device .. "\n")
  io.write(output_srate .. "\n")
  io.close(file)
end


function load_config()
  local file = io.open(_path.data .. config_file, "r")
  if file then
    print("datafile found")
    io.input(file)
    if io.read() == "v1" then
    	desired_input_device 	= io.read()
    	desired_input_srate 	= io.read()
    	desired_output_device = io.read()
    	desired_output_srate 	= io.read()
    end
    io.close(file)
  end
  -- check if everything is fine
  local id = getindex(array_of_devices, desired_input_device)
  if (id > -1) then 
  	input_device_index = id
  	input_device = array_of_devices[input_device_index]
  end
  local id = getindex(array_of_devices, desired_output_device)
  if (id > -1) then 
  	output_device_index = id
  	output_device = array_of_devices[output_device_index]
  end
  local id = getindex(array_of_srate, desired_input_srate)
  if (id > -1) then 
  	input_srate_index = id
  	input_srate = array_of_srate[input_srate_index]
  end
  local id = getindex(array_of_srate, desired_output_srate)
  if (id > -1) then 
  	output_srate_index = id
  	output_srate = array_of_srate[output_srate_index]
  end
  print ('Output: '..output_device_index..':'..output_device..' '..output_srate_index..':'..output_srate)
	print ('Input: '..input_device_index..':'..input_device..' '..input_srate_index..':'..input_srate)
end


function connect()
	create_script()
  run_script()
end


function run_script()
	connecting_status = 1
  redraw()
  os.execute(_path.this.lib..script_file)
	connecting_status = 0
	redraw()
end


function create_script()
	-- discard the revious file content
	io.open(_path.this.lib..script_file,"w"):close()
	local script = io.open(_path.this.lib..script_file, "w")
	script:write("#!/bin/sh \n")
	script:write("killall alsa_in \n")
	script:write("killall alsa_out \n")
	script:write("sleep 1 \n")
	if not (input_device == "None") then
		script:write("alsa_in -d hw:CARD=" .. input_device .." -r " .. input_srate .." & \n")
	end
	if not (output_device == "None") then
		script:write("alsa_out -d hw:CARD=" .. output_device .." -r " .. output_srate .." & \n")
	end
	script:write("sleep 1 \n")
	if not (input_device == "None") then
		script:write("jack_connect alsa_in:capture_1 softcut:input_1 \njack_connect alsa_in:capture_2 softcut:input_2 \njack_connect alsa_in:capture_1 crone:input_1 \njack_connect alsa_in:capture_2 crone:input_2 \n")
	end
	if not (output_device == "None") then
		script:write("jack_connect softcut:output_1 alsa_out:playback_1 \njack_connect softcut:output_2 alsa_out:playback_2 \njack_connect crone:output_1 alsa_out:playback_1 \njack_connect crone:output_2 alsa_out:playback_2 \n")
	end
	script:close()
end


-- INTERACTION

function enc(id,delta)
		if id == 1 then
			destination = util.clamp(destination - delta, 0, 1)
		-- output device
	  elseif id == 3 then
	  	if (destination == 0) then -- device destination
	  		output_device_index = util.clamp(output_device_index + delta, 1, #(array_of_devices)) 
	  		output_device = array_of_devices[output_device_index]
	  	else -- srate destination
	  		output_srate_index = util.clamp(output_srate_index + delta, 1, #(array_of_srate)) 
	  		output_srate = array_of_srate[output_srate_index]
	  	end
	  -- input device
	  elseif id == 2 then
	  	if (destination == 0) then -- device destination
	  		input_device_index = util.clamp(input_device_index + delta, 1, #(array_of_devices)) 
	  		input_device = array_of_devices[input_device_index]
	  	else -- srate destination
	  		input_srate_index = util.clamp(input_srate_index + delta, 1, #(array_of_srate)) 
	  		input_srate = array_of_srate[input_srate_index]
	  	end
	  end
	  redraw()
end


function key(id,state)
  if (id == 1 and state == 1) then
		save_config()
  	connect()
  end
  if (id == 2 and state == 1) then
  	engine.hz(MusicUtil.note_num_to_freq(69))
  end
  if (id == 3 and state == 1) then
		destination = 1 - destination
  end
  redraw()
end


-- DRAW

function redraw()
  screen.clear()
  if (connecting_status == 0) then
  	draw_text()
  	draw_frame()
  else
  	draw_connect_animation()
  end
  screen.update()
end


local x1 = 5
local x2 = viewport.width/4
local x3 = 3*viewport.width/4
local y1 = viewport.height/2 - 10
local y2 = viewport.height/2
local y3 = viewport.height/2 + 10
local level_min = 3

function draw_text()
	screen.font_size(8)
	screen.level(level_min)
	screen.move(x2, y1)
	screen.text_center('INPUT')
	screen.move(x3, y1)
	screen.text_center('OUTPUT')
	if (destination == 0) then screen.level(15) else screen.level(level_min) end
	screen.move(x2, y2)
	screen.text_center(input_device)
	screen.move(x3, y2)
	screen.text_center(output_device)
	if (destination == 1) then screen.level(15) else screen.level(level_min) end
	screen.move(x2, y3)
	screen.text_center(input_srate..'Hz')
	screen.move(x3, y3)
	screen.text_center(output_srate..'Hz')
end


function draw_connect_animation()
	screen.level(15)
	screen.move(viewport.width/2, viewport.height/2 + 4)
	screen.font_size(20)
	screen.text_center("CONNECTING...")
end	


function draw_frame()
	screen.level(8)
  screen.rect(1, 1, viewport.width-1, viewport.height-1)
  screen.stroke()
end


-- UTIL

re = metro.init()
re.time = 1.0 / 10.
re.event = function()
  viewport.frame = viewport.frame + 1
  redraw()
end
re:start()


function getindex(array, name)
	local result = -1
	for i,d in pairs(array) do
		if d == name then
			result = i
		end
	end
	return result
end

