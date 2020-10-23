-- sponsorblock_minimal.lua
--
-- This script skips sponsored segments of YouTube videos
-- using data from https://github.com/ajayyy/SponsorBlock

local options = {
    API = "https://sponsor.ajay.app/api/skipSegments",

    -- Categories to fetch and skip
    categories = '"sponsor","intro","outro","interaction","selfpromo"'
}

function getranges()
    	local args = {
        	"curl",
		"-s",
        	"-d",
        	"videoID="..youtube_id,
        	"-d",
		"categories=["..options.categories.."]",
		"-G",
        	options.API}
	local sponsors
    	sponsors = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    	if not string.match(sponsors.stdout,"%[(.-)%]") then return end
	ranges = {}
	for i in string.gmatch(string.sub(sponsors.stdout,2,-2),"%[(.-)%]") do
		k,v = string.match(i,"(%d+.?%d*),(%d+.?%d*)")
		ranges[k] = v
	end
	return
end

function skip_ads(name,pos)
	if pos == nil then return end
	for k,v in pairs(ranges) do
		if tonumber(k) <= pos and tonumber(v) > pos then
        		mp.osd_message("[sponsorblock] skipping to "..tostring(v))
			mp.set_property("time-pos",tonumber(v))
            		return
    		end
	end
end

function file_loaded()
	local video_path = mp.get_property("path")
	local youtube_id1 = string.match(video_path, "https?://youtu%.be/([%w-_]+).*")
	local youtube_id2 = string.match(video_path, "https?://w?w?w?%.?youtube%.com/v/([%w-_]+).*")
	local youtube_id3 = string.match(video_path, "/watch.*[?&]v=([%w-_]+).*")
	local youtube_id4 = string.match(video_path, "/embed/([%w-_]+).*")
	youtube_id = youtube_id1 or youtube_id2 or youtube_id3 or youtube_id4
	if not youtube_id or string.len(youtube_id) < 11 then return end
	youtube_id = string.sub(youtube_id, 1, 11)

	getranges()
	if not ranges then
		mp.unregister_event(file_loaded)
		return
	end

	ON = true
	mp.add_key_binding("b","sponsorblock",toggle)
	mp.observe_property("time-pos", "native", skip_ads)
end

function toggle()
	if ON then
		mp.unobserve_property(skip_ads)
		mp.osd_message("[Sponsorblock] off")
		ON = false
		return
	end
	mp.observe_property("time-pos", "native", skip_ads)
	mp.osd_message("[Sponsorblock] on")
	ON = true
	return
end

mp.register_event("file-loaded", file_loaded)
