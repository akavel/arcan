function main(arg)
    local gen = assert(gen[arg[1] or 'html'], 'unknown output type: ' .. tostring(arg[1]))
    -- print(arg[1])
    local funcs = scangroups 'src/engine/arcan_lua.c'
    -- for _, g in ipairs(funcs) do
    --     print(g[1], g[2], g[3])
    -- end


    -- Scan funcs docs
    for i, g in ipairs(funcs) do
        -- FIXME(akavel): emit group name as header
        local f = scandoc(g.lua)
        f.section = g.group
        f.name = g.lua
        funcs[i] = f
    end

    -- Generate ToC with group names
    gen.toc_start()
    local last_group
    for _, f in ipairs(funcs) do
        if f.section ~= last_group then
            gen.toc_group(f.section)
            last_group = f.section
        end
        gen.toc(f)
    end
    gen.toc_end()

    for _, f in ipairs(funcs) do
        gen.func(f)
    end
end

-- Parse the C binding file, look for our preprocessor
-- markers, extract the group, lua symbol, and c symbol.
-- Return a table of the results.
function scangroups(cfile)
    local groups = {}
    local in_grp = nil
    local fh = assert(io.open(cfile))
    for l in fh:lines() do
        local open = l:match '#define%s+EXT_MAPTBL_(%w+)'
        if open then
            in_grp = open
        end
        local close = l:match '#undef%s+EXT_MAPTBL_(%w+)'
        if close then
            in_grp = nil
        end
        local id_lua, id_c = l:match '{"([a-z0-9_]+)",%s*([a-z0-9_]+)%s*}'
        if in_grp and id_lua and id_c then
            groups[#groups+1] = {
                group = in_grp,
                lua = id_lua,
                c = id_c,
            }
        end
    end
    fh:close()
    return groups
end

function scandoc(funcname)
    local res = {}
    local fh = assert(io.open('doc/'..funcname..'.lua'))

    -- Skip first line containing func name
    assert(fh:read '*l')

    local line
    -- Parse comments
    local in_group = nil
    while true do
        line = fh:read '*l'
        if not line then
            break
        end
        if not line:match '^%-%-' then
            break
        end
        local group, rest = line:match '^%-%- @([^:]+):%s*(.*)$'
        if group then
            in_group = group
            local t = res[group] or {}
            t[#t+1] = rest
            res[group] = t
        else
            local t = res[in_group]
            if line == '--' or line:match'^%-%- %. ' then
                t[#t+1] = ''
            end
            -- print('MCDBG ' ..funcname..' '..in_group)
            -- t[#t] = t[#t] .. line:sub(3)
            t[#t] = t[#t] .. line:match'^%-%-(.*)$'
        end
    end

    -- TODO(akavel): Parse examples

    fh:close()
    return res
end

local function printf(fmt, ...)
    io.write(fmt:format(...))
end
local function any(v)
    return v and
        type(v) == 'table' and
        #v > 0 and
        not (#v==1 and v[1]=='')
end

gen = {
    html = {
        toc_start = function()
            print('<html><head>')
            print('<title>Arcan Lua API</title>')
            print('<style type="text/css">html{margin:1em 20%}</style>')
            print('</head><body>')
            print('<h2>Index:</h2>\n<ul>')
        end,
        toc_group = function(g)
            printf('</ul><em>%s</em><ul>\n', g)
        end,
        toc = function(f)
            printf('<li><a href="#f_%s">%s</a> &mdash; %s</li>\n', f.name, f.name, f.short[1])
        end,
        toc_end = function()
            print('</ul>')
        end,
        func = function(f)
            printf('<hr><h3 id="f_%s">%s &mdash; %s</h3>\n', f.name, f.name, f.short[1])
            printf('<ul><li><em>returns:</em> ')
            if any(f.outargs) then
                -- printf('<em>' .. table.concat(f.outargs, ', ') .. '</em>')
                printf(table.concat(f.outargs, ', '))
            else
                -- printf('<em>nil</em>')
                printf('nil')
            end
            printf('</li>')
            for _, a in ipairs(f.inargs or {''}) do
                printf('<li>(%s)</li>\n', a
                    :gsub('%*([%w_:]+)%*', '<b>%1</b>')
                )
            end
            print('</ul>')

            if f.longdescr then
                printf('<p>%s</p>\n',
                    table.concat(f.longdescr, '</p>\n<p>')
                    :gsub('%*([%w_:]+)%*', '<b>%1</b>')
                    :gsub('%f[%w_]ref:([%w_]+)%f[^%w_]', '<a href="#f_%1">%1</a>')
                    -- :gsub('\n\n', '</p><p>')
                )
            end

            if any(f.notes) then
                for _, n in ipairs(f.notes) do
                    printf('<p><strong>Note:</strong> %s</p>\n', n)
                end
            end

            if any(f.related) then
                print('<p><strong>See also:</strong><p><ul>')
                for r in f.related[1]:gmatch '([%w_]+)' do
                    printf('<li><a href="#f_%s">%s</a></li>\n', r, r)
                end
                print('</ul>')
            end
            -- print(f.name, f.group and f.group[1] or '???')
        end,
    },
}

main(arg)
