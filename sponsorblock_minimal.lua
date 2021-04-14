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
    	local sponsors = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})

    	if string.match(sponsors.stdout,"%[(.-)%]") then
		ranges = {}
		for i in string.gmatch(string.sub(sponsors.stdout,2,-2),"%[(.-)%]") do
			k,v = string.match(i,"(%d+.?%d*),(%d+.?%d*)")
			ranges[k] = v
		end
	end
	return
end

function skip_ads(name,pos)
	if pos ~= nil then
		for k,v in pairs(ranges) do
			if tonumber(k) <= pos and tonumber(v) > pos then
				--this message may sometimes be wrong
				--it only seems to be a visual thing though
        			mp.osd_message("[sponsorblock] skipping forward "..math.floor(tonumber(v)-mp.get_property("time-pos")).."s")
				--need to do the +0.01 otherwise mpv will start spamming skip sometimes
				--example: https://www.youtube.com/watch?v=4ypMJzeNooo
				mp.set_property("time-pos",tonumber(v)+0.01)
            			return
    			end
		end
	end
	return
end

function file_loaded()
	local video_path = mp.get_property("path", "")
	local video_referer = string.match(mp.get_property("http-header-fields", ""), "Referer:([^,]+)") or ""

	local urls = {
	    "https?://youtu%.be/([%w-_]+).*",
	    "https?://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
	    "/watch.*[?&]v=([%w-_]+).*",
	    "/embed/([%w-_]+).*",
	    "-([%w-_]+)%."
	}
	youtube_id = nil
	for i,url in ipairs(urls) do
	    youtube_id = youtube_id or string.match(video_path, url) or string.match(video_referer, url)
	end

	if not youtube_id or string.len(youtube_id) < 11 then return end
	youtube_id = string.sub(youtube_id, 1, 11)

	getranges()
	if ranges then
		ON = true
		mp.add_key_binding("b","sponsorblock",toggle)
		mp.observe_property("time-pos", "native", skip_ads)
	end
	return
end

function toggle()
	if ON then
		mp.unobserve_property(skip_ads)
		mp.osd_message("[sponsorblock] off")
		ON = false
		return
	end
	mp.observe_property("time-pos", "native", skip_ads)
	mp.osd_message("[sponsorblock] on")
	ON = true
	return
end

mp.register_event("file-loaded", file_loaded)
