-- This filter adds all links to images in the document to the metadata.
-- See https://pandoc.org/lua-filters.html

local resources = {}

return {
    {
        Image = function (elem)
            table.insert(resources, pandoc.MetaString(elem.src))
            return nil
        end,
        Meta = function (meta)
            meta.resources = pandoc.MetaList(resources)
            return meta
        end,
    }
}
