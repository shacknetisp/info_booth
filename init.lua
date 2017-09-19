info_booth = bgml.mod.begin()

info_booth.tables = {}

-- Add a page.
function info_booth.set_page(category, page, title, content, top)
    if not info_booth.tables[category] then
        info_booth.tables[category] = {
            pages = {},
            titles = {},
            order = {},
        }
    end
    info_booth.tables[category].pages[page] = content
    info_booth.tables[category].titles[page] = title
    if top then
        table.insert(info_booth.tables[category].order, 1, page)
    else
        table.insert(info_booth.tables[category].order, page)
    end
end

local players = {}

-- Display a page.
function info_booth.display(category, page, name)
    local sel = 1
    for i,p in ipairs(info_booth.tables[category].order) do
        if p == page then
            sel = i
            break
        end
    end
    local n = {}
    for _,p in ipairs(info_booth.tables[category].order) do
        local title = info_booth.tables[category].titles[p]
        table.insert(n, engine.formspec_escape(title))
    end

    -- Text processing borrowed from Wuzzy's MIT-licensed doc mod.
    local TEXT_LINELENGTH = 80

    -- Inserts line breaks into a single paragraph and collapses all whitespace (including newlines)
    -- into spaces
    local linebreaker_single = function(text, linelength)
         if linelength == nil then
                 linelength = TEXT_LINELENGTH
         end
         local remain = linelength
         local res = {}
         local line = {}
         local split = function(s)
                 local res = {}
                 for w in string.gmatch(s, "%S+") do
                         res[#res+1] = w
                 end
                 return res
         end

         for _, word in ipairs(split(text)) do
                 if string.len(word) + 1 > remain then
                         table.insert(res, table.concat(line, " "))
                         line = { word }
                         remain = linelength - string.len(word)
                 else
                         table.insert(line, word)
                         remain = remain - (string.len(word) + 1)
                 end
         end

         table.insert(res, table.concat(line, " "))
         return table.concat(res, "\n")
    end

    -- Inserts automatic line breaks into an entire text and preserves existing newlines
    local linebreaker = function(text, linelength)
         local out = ""
         for s in string.gmatch(text, "([^\n]*)") do
                 local l = linebreaker_single(s, linelength)
                 out = out .. l
                 if(string.len(l) == 0) then
                         out = out .. "\n"
                 end
         end
         -- Remove last newline
         if string.len(out) >= 1 then
                 out = string.sub(out, 1, string.len(out) - 1)
         end
         return out
    end

    -- Inserts text suitable for a textlist (including automatic word-wrap)
    local text_for_textlist = function(text, linelength)
         text = linebreaker(text, linelength)
         text = minetest.formspec_escape(text)
         text = string.gsub(text, "\n", ",")
         return text
    end

    local formspec = "size[12,7]"
        .. "textlist[-0.25,0;4,7;page;" .. table.concat(n, ",") .. ";" .. sel .. "]"
        .. "tablecolumns[text]"
        .. "tableoptions[background=#000000FF;highlight=#000000FF;border=false]"
        .. "table[4,0;8,7;text;" .. text_for_textlist(info_booth.tables[category].pages[page]) .. "]"
    players[name] = category
    engine.show_formspec(name, "info_booth:display", formspec)
end

-- Register a booth node.
function info_booth.register(node, category, main, title)
    engine.register_node(node, {
        description = title,
        tiles = {"info_booth_side.png", "info_booth_side.png", "info_booth_side.png", "info_booth_side.png", "info_booth_side.png", "info_booth_front.png"},
        paramtype2 = "facedir",
        groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 2},
        sounds = default.node_sound_wood_defaults(),
        on_construct = function(pos)
            local meta = engine.get_meta(pos)
            meta:set_string("infotext", title)
        end,
        on_rightclick = function(pos, _, clicker)
            info_booth.display(category, main, clicker:get_player_name())
        end,
    })
end

engine.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "info_booth:display" then
        return false
    end

    if fields.page then
        local index = engine.explode_textlist_event(fields.page).index
        local category = players[player:get_player_name()]
        local page = info_booth.tables[category].order[index]
        if page then
            info_booth.display(category, page, player:get_player_name())
        end
    end

    return true
end)

info_booth.ready()
