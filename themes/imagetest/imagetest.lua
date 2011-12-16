-- imagetest
-- whole bunch of features we want to run through here.
-- 
-- Basic image loading and deletion are tested in the others, so skip that.
-- Same with picking (internaltest)
--
-- Advanced features, e.g. multiple frames, vid stack push / pop
-- Transformation chains
-- Safety harness for unreasonably sized images (> 8kx8k pixels, 0x0 and negative dimensions)
-- Instancing (huge numbers)
-- Linking objects and inherited coordinate spaces
-- Z ordering
-- Override translation origo
-- Shaders
--

aimg = BADID;

function imagetest()
	local symfun = system_load("scripts/symtable.lua");
	symtable = symfun();

	local text_vid = render_text( [[\ffonts/default.ttf,14\#ffffff\bImagetest:\n\r]] ..
	[[\b\!i(1)\t\!binstancing test\n\r]] ..
	[[\b\!i(2)\t\!border + transform-stress test\n\r]] ..
	[[\b\!i(3)\t\!bvid limit test\n\r]] ..
	[[\b\!i(s)\t\!bstack push\n\r]] ..
	[[\b\!i(p)\t\!bstack pop\n\r]] ..
	[[\b\!i(l)\t\!bload image into context\n\r]] .. 
	[[\iESCAPE\t\!ishutdown\n\r]] );

	sprop = image_surface_properties(text_vid);
	move_image(text_vid, VRESW - sprop.width - 10, 0, 0);
	show_image(text_vid);
	order_image(text_vid, 255);
end



function zordervidlim(load) 
	local step = 254.0 / VCTXVIDLIMIT;

	for i=1,VCTXVIDLIMIT do
		print (" --> generated # " .. tostring(i));

		local newid;
		if (load) then
			 newid = load_image("imagetest.png", 0);
			 move_image(newid, math.random( VRESW - 16), math.random( VRESH - 16), 0);
			 resize_image(newid, 64, 64, 0);
		else
			newid = fill_surface(64, 64, step * i, step * i, 255);
			order_image(newid, math.floor ( i * step ));
			for j=1,254 do
				rotate_image(newid, math.random(360), 10);
			end
		end

		move_image(newid, math.random( VRESW - 16), math.random( VRESH - 16), 0);
		
		if (newid == BADID) then
			break;
		end
		
		show_image(newid);
	end
	
end

function instancing_test()
	local newid = fill_surface(64, 64, 0, 255, 0);
	move_image(newid, 0.5*VRESW - 32, 0.5*VRESH - 32, 0);
	show_image(newid);
	order_image(newid, 255);

	for  j=1,20 do
		local instid = instance_image(newid);
		order_image(instid, 254);
		scale_image(instid, 0.5, 0.5, 0);
		show_image(instid);
		image_mask_set(instid, MASK_POSITION);
		blend_image(instid, 0.5);
		
		if (instid == BADID) then
			break;
		end
		
		for j=1,254 do
			move_image(instid, math.random(-128, 128), math.random(-128, 128), 20);
		end
	end
	
	for j=1,254 do 
		move_image(newid, math.random(VRESW), math.random(VRESH), 20);
	end
end

function imagetest_input(inputtbl)	
	if (inputtbl.kind == "digital" and inputtbl.translated and inputtbl.active) then
		if (symtable[ inputtbl.keysym ] == "ESCAPE") then
			shutdown();
		elseif (symtable[ inputtbl.keysym ] == "1") then
			print("Running instancing test");
			instancing_test();
		elseif (symtable[ inputtbl.keysym ] == "2") then
			print("Running Z order/limit test");
			zordervidlim(false);
		elseif (symtable[ inputtbl.keysym ] == "3") then
			print("Running image loading stress");
			zordervidlim(true);
		elseif (symtable[ inputtbl.keysym ] == "l") then
			print("Loading image into context");
			local vid = load_image("imagetest.png");
			resize_image(vid, 64, 64);
			move_image(vid, math.random(VRESW - 64), math.random(VRESH - 64), 0);
			order_image(vid, 0);
			show_image(vid);
		elseif (symtable[ inputtbl.keysym ] == "s") then
			print("Stack push => " .. tostring ( push_video_context() ) );
		elseif (symtable[ inputtbl.keysym ] == "p") then
			print("Stack pop => " .. tostring ( pop_video_context() ) );
		end
	end
end

function imagetest_video_event(source, evtbl)
	print( "-- video event : " .. tostring(source) .. " => " .. evtbl.kind);
end

