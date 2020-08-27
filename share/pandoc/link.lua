-- When this filter encounters a link with empty content, the content should be
-- set to the host of the target link, e.g.:
-- `[](https://link.com/page)` -> [`link.com`](https://link.com/page)

function host(str)
    str = str:gsub("^%a+://","")
    str = str:gsub("www.","")
    str = str:gsub("mailto:","")
    str = str:gsub("/[^/]+","")
    str = str:gsub("/$","")
    return str
end

return {
    {
        Link = function (a)
            if #a.content == 0 then
                a.content = { pandoc.Code(host(a.target)) }
            end
            return a
        end,
    }
}
