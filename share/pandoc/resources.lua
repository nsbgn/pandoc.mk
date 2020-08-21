-- This filter adds all links and image URLs in the document to the metadata,
-- as long as they are relative paths to the filesystem. See
-- https://pandoc.org/lua-filters.html

local resources = {}

function is_external(str)
    local i, j = str:find("%a+://")
    return (str:sub(1,7) == "mailto:") or
        (i == 1 and j and str:sub(i, j) ~= "file://")
end

function is_absolute(str)
    -- See https://stevedonovan.github.io/Penlight/api/source/path.lua.html and
    -- https://pandoc.org/lua-filters.html#type-commonstate if I ever decide I
    -- want to include absolute paths too
    return str:sub(1, 1) == '/'
end

function add_resource(str)
    if not (is_external(str) or is_absolute(str)) then
        table.insert(resources, pandoc.MetaString(str))
    end
end

return {
    {
        Link = function (a)
            add_resource(a.target)
            return nil
        end,
        Image = function (img)
            add_resource(img.src)
            return nil
        end,
        Meta = function (meta)
            meta.resources = pandoc.MetaList(resources)
            return meta
        end,
    }
}
