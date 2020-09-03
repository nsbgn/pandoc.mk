-- This filter adds all links and image URLs in the document to the metadata,
-- as long as they are relative paths to the filesystem. See
-- https://pandoc.org/lua-filters.html

local resources = {}

function add_resource(url)
    -- Test if URL is local & relative
    if url:sub(1, 1) ~= '/'
    and (url:match("^%a+://") or url:match("^mailto:")) == nil
    then table.insert(resources, pandoc.MetaString(url))
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
