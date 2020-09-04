-- DRY-links.
-- When this filter encounters a link with empty content, the content is set to
-- the target URL. Alternatively, if it consists ONLY of single characters
-- prefixed with a `%`, then it should be set to the corresponding URL fragment
-- (see the `dissect` function for relevant characters).
--
-- Example:
--    [%d](https://sub.domain.com:80/page/file.ext?arg1=1&arg2=2#anchor) 
-- →  [`domain.com`](https://sub.domain.com:80/page/file.ext?arg1=1&arg2=2#anchor)

local function take(pattern, string)
  local output = ''
  local i, j = string:find(pattern)
  if i and j then
    output = string:sub(i, j)
    string = string:sub(1, i-1) .. string:sub(j+1)
  end
  return output, string
end

local function subst(string, substitution)
  for k, v in pairs(substitution) do
    string = string:gsub('%%' .. k, v)
  end
  return string
end

local function dissect(url)
  protocol, url = take('^%a+:/*', url)
  host, url = take('^[^:/]+', url)
  port, url = take('^:[^/]+', url)
  path, url = take('^/[^%?]*', url)
  query, url = take('^?[^#]+', url)
  anchor, url = take('^#.+', url)
  file = path:match('[^/]+$') or ''
  domain = host:match('[^%.]+%.[^%.]+$') or host

  return {
    t = protocol, -- 'https://'
    h = host,     -- 'sub.domain.com'
    d = domain,   -- 'domain.com'
    P = port,     -- ':80'
    p = path,     -- '/directory/file.ext'
    f = file,     -- 'file.ext'
    q = query,    -- '?param1=true&param2=string'
    a = anchor    -- '#hash-fragment'
  }
end

return {
  {
    Link = function(a)
      if #a.content == 0 then
        local url = a.target:gsub('^mailto:', '')
        a.content = { pandoc.Code(url) }
      elseif #a.content == 1 and a.content[1].t == 'Str'
          and a.content[1].text:gsub('%%%a','') == '' then
        a.content = {
          pandoc.Code(subst(a.content[1].text, dissect(a.target)))
        }
      end
      return a
    end,
  }
}

