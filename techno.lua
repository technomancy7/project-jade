-- Library of my custom tweaks

function Trand(tb)
	math.randomseed( os.time() )
	return tb[math.random(#tb)]
end

function Sleep(n)  -- seconds
  local clock = os.clock
  local t0 = clock()
  while clock() - t0 <= n do end
end

function FileExists(name)
  if type(name)~="string" then return false end
  return os.rename(name,name) and true or false
end

function IsFile(name)
  if type(name)~="string" then return false end
  if not FileExists(name) then return false end
  local f = io.open(name)
  if f then
      f:close()
      return true
  end
  return false
end

function IsDir(name)
  return (FileExists(name) and not IsFile(name))
end

function table.has_value(tab, val)
  for _, value in ipairs(tab) do if value == val then return true end end
  return false
end


function table.has_key(tab, val)
  for key, _ in pairs(tab) do if key == val then return true end end
  return false
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end


function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.toStr( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.toStr( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end


function table.slice(tbl, first, last, step)
	local sliced = {}

	for i = first or 1, last or #tbl, step or 1 do
	  sliced[#sliced+1] = tbl[i]
	end
 
	return sliced
end

local meta = getmetatable("") -- get the string metatable

meta.__add = function(a,b) -- the + operator
    return a..b
end

meta.__sub = function(a,b) -- the - operator
    return a:gsub(b,"")
end

meta.__mul = function(a,b) -- the * operator
    return a:rep(b)
end

-- if you have string.explode (check out the String exploding snippet) you can also add this:
meta.__div = function(a,b) -- the / operator
    return a:SplitStr(b)
end

meta.__index = function(a,b) -- if you attempt to do string[id]
    if type(b) ~= "number" then
        return string[b]
    end
    return a:sub(b,b)
end

function string.contains(s, v)
	if s:find(v, 1, true) then return true else return false end
end

function string.starts_with(str, start)
   return str:sub(1, #start) == start
end

function string.ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function string.capfirst(inStr)
    local out = inStr:gsub("^%l",string.upper)
    return out
end

function string.split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function string.getind(s, ind) return s:sub(ind,ind) end

function string.repind(s, ind, news)
  local l = s:sub(1, ind-1)
  local r = s:sub(ind+1, #s)
  return l..news..r
end

function string.insert(s, ind, news)
  local l = s:sub(1, ind)
  local r = s:sub(ind+1, #s)
  return l..news..r
end

function string.getFileExt( path )
	return path:match( "%.([^%.]+)$" )
end

function string.stripFileExt( path )
	local i = path:match( ".+()%.%w+$" )
	if ( i ) then return path:sub( 1, i - 1 ) end
	return path
end

function string.parseFilePath( path )
	return path:match( "^(.*[/\\])[^/\\]-$" ) or ""
end

function string.parseFileName( path )
	if not (path:find( "\\" ) and path:find( "/" ) ) then return path end 
	return path:match( "[\\/]([^/\\]+)$" ) or ""
end

function string.Plural( str, quantity )
	return str .. ( ( quantity ~= 1 ) and "s" or "" )
end

function string.Left( str, num ) return string.sub( str, 1, num ) end
function string.Right( str, num ) return string.sub( str, -num ) end

function string.Replace( str, tofind, toreplace )
	local tbl = string.SplitStr( tofind, str )
	if ( tbl[ 1 ] ) then return table.concat( tbl, toreplace ) end
	return str
end


-- Note: These use Lua index numbering, not what you'd expect
-- ie they start from 1, not 0.

function string.SetChar( s, k, v )

	local start = s:sub( 0, k - 1 )
	local send = s:sub( k + 1 )

	return start .. v .. send

end

function string.GetChar( s, k )

	return s:sub( k, k )

end

function math.Rand( low, high )
	return low + ( high - low ) * math.random()
end

function math.round(float)
    return float % 1 >= 0.5 and math.ceil(float) or math.floor(float)
end

function ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function Implement(orig)
    return DeepCopy(orig)
end
