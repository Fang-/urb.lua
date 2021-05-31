--  a noun is an atom or a cell
--  an atom is a natural number
--  a cell is an ordered pair of nouns
--
--  a lua noun is a number (direct atom), string (indirect atom), or table (cell)
--  a number (atom) is a natural number that fits in 53 bits  --TODO 32?
--  a string (atom) is a natural number represented as a bytestring, LSB first
--  a table (cell) contains two lua nouns: { h, t }

--  lua atom handling functions should maintain the following invariants:
--  numbers should be no bigger than mit bits
--  strings should be no smaller than mit+1 bits
--  strings should have no leading zero bytes

--TODO
--  don't use strings as intermediate values, instead explicit byte_arrays_,
--    then join with table.concat when done. (strings hashed on-create)
--  (does that even apply to luajit?)
--  stay aware of other perf gotchas...

--NOTE  provided by luajit
--TODO  but... these are 32-bit signed integers. should that be our global max?
local bit = require("bit");

--  mit: max direct atom bit-width
--
local mit = 32;

--  show: noun to string representation
--
function show(n)
  if type(n) == 'table' then
    return '[' .. show(head(n)) .. ' ' .. show(tail(n)) .. ']';
  elseif type(n) == 'string' then
    local o = '';
    local i = #n;
    while i > 0 do
      o = o .. string.format('%02x', string.byte(n, i));
      i = i - 1;
      if i > 0 and i % 2 == 0 then
        o = o .. '.'
      end
    end
    return '0x' .. o;
  elseif type(n) == 'number' then
    return tostring(n);
  else
    assert(false, 'show: not noun');
  end
end

--  cons: make a cell from two lua nouns
--
function cons(h, t)  --TODO  take variable arguments
  return { h = h, t = t };
  --TODO  metatables? tostring, concat, head, tail...
end

--  head: get the head from a cell
--
function head(n)
  assert(type(n) == 'table', 'head: not cell');
  return n.h;
end

--  tail: get the tail from a cell
--
function tail(n)
  assert(type(n) == 'table', 'tail: not cell');
  return n.t;
end

--  curl: string atom to number atom, if it fits
--
function curl(a)
  if type(a) == 'number' then return a; end
  assert(type(a) == 'string', 'curl: not string atom');
  --TODO  check last byte, met(0, a)
  if #a <= math.floor( mit / 8 ) then
    return coil(a);
  else
    return a;
  end
end

--  coil: string atom to number atom
--
function coil(a)
  if type(a) == 'number' then return a; end
  assert(type(a) == 'string', 'coil: not string atom');
  --TODO  check last byte, met(0, a)
  assert(#a <= math.floor( mit / 8 ), 'coil: atom too big');
  local b = 0;
  for i=1,#a do
    b = b + ( string.byte(a, i) * math.pow(256, i-1) );
  end
  return b;
end

--  grow: number atom to string atom
--
function grow(a)
  if type(a) == 'string' then return a; end  --TODO  trim leading zeroes?
  assert(type(a) == 'number', 'grow: not number atom');
  local b = '';
  while a > 0 do
    b = b .. string.char(a % 256);
    a = math.floor(a / 256);
  end
  return b;
end

--  add: integer addition
--
function add(a, b)
  a = grow(a);
  b = grow(b);
  local i = 1;
  local c = 0;
  local o = '';
  while i <= #a or i <= #b or c > 0 do
    c = c + (string.byte(a, i) or 0) + (string.byte(b, i) or 0);
    o = o .. string.char(c % 256);
    if c < 256 then
      c = 0;
    else
      c = 1;
    end
    i = i + 1;
  end
  return curl(o);
end

--  sub: integer subtraction
--
function sub(a, b)
  if type(a) == 'number' and type(b) == 'number' then
    assert(a >= b, 'sub: underflow');
    return a - b;
  else
    a = grow(a);
    b = grow(b);
    local i = 1;
    local c = 0;
    local o = '';
    while i <= #a or i <= #b or c > 0 do
      c = ( c + (string.byte(a, i) or 0) ) - (string.byte(b, i) or 0);
      if c >= 0 then
        o = o .. string.char(c);
        c = 0;
      else
        o = o .. string.char( 256 + c );
        c = -1;
      end
      i = i + 1;
    end
    assert(c >= 0, 'sub: underflow');
    return curl(o);
  end
end

--  div: integer division
--
function div(a, b)
  if type(a) == 'number' and type(b) == 'number' then
    assert(b ~= 0, 'div: by zero');
    return math.floor(a / b);
  else
    a = grow(a);
    b = grow(b);
    assert(false, 'div: todo');
  end
end

--  mod: modulus
--
function mod(a, b)
  if type(b) == 'number' then
    if type(a) == 'number' then
      return a % b;
    elseif type(a) == 'string' then
      return coil( ned(cons(3, met(3, b)), a) ) % b;
    else
      assert(false, 'mod: a not atom');
    end
  elseif type(b) == 'string' then
    if type(a) == 'number' then
      return a;  --NOTE  relies on string atom hygeine
    elseif type(a) == 'string' then
      assert(false, 'mod: todo');
      --TODO  coil
    else
      assert(false, 'mod: a not atom');
    end
  else
    assert(false, 'mod: b not atom');
  end
end

--  mul: multiply
--
function mul(a, b)
  local o = 0;
  --TODO  lol
  if lte(a, b) then
    while a ~= 0 do
      o = add(o, b);
      a = sub(a, 1);
    end
  else
    while b ~= 0 do
      o = add(o, a);
      b = sub(b, 1);
    end
  end
  return o;
end

function lte(a, b)
  if type(a) == 'number' and type(b) == 'number' then
    return a <= b;
  else
    a = grow(a);
    b = grow(b);
    if #a ~= #b then
      return #a < #b;
    else
      local i = #a;
      while i > 0 do
        local c = string.byte(a, i);
        local d = string.byte(b, i);
        if c ~= d then
          return c <= d;
        end
        i = i - 1;
      end
      return true;  --  equal
    end
  end
end

--  bex: binary exponent
--
function bex(a)
  if a == 0 then return 1; end
  return mul(2, bex(sub(a, 1)));  --TODO  dec?
end

--  bix: bits in bite
--
function bix(b)
  if type(b) ~= 'table' then
    return bex(b);
  else
    return mul(bex(head(b)), tail(b));
  end
end

--  rsh: right-shift bite-wise
--
function rsh(b, a)
  local z = bix(b);
  if type(a) == 'number' then
    return math.floor( a / bex( z ) );
  elseif type(a) == 'string' then
    if mod(z, 8) == 0 then
      return string.sub(a, add(1, div(z, 8)));
    else
      return div(a, bex(z));
    end
  else
    assert(false, 'rsh: not atom');
  end
end

--  lsh: left-shift an atom
--
function lsh(b, a)
  local z = bix(b);
  if type(a) == 'number' then
    if (met(0, a) + z) > mit then
      return lsh(b, grow(a));
    else
      return bit.lshift(a, z);
    end
  elseif type(a) == 'string' then
    if mod(z, 8) == 0 then
      return string.rep('\0', div(z, 8)) .. a;  --TODO  safe, right?
    else
      return mul(a, bex(z));
    --   local i = 1;
    --   local c = 0;
    --   local o = '';
    --   while i <= #a do
    --     c = add(c, mul(string.byte(i), bex(z)));
    --     o = o .. string.char(mod(c, 256));
    --     c = div(c, 256) --TODO
    --     i = i + 1;
    --   end
    end
  else
    assert(false, 'lsh: not atom');
  end
end

--  ned: tail bites (end)
--
function ned(b, a)
  if type(b) ~= 'table' then
    b = cons(b, 1);
  end
  if type(a) == 'number' then
    return a % bex( bix(b) );
  elseif type(a) == 'string' then
    if head(b) == 3 and type(tail(b)) == 'number' then
      return string.sub(a, 1, tail(b));
    else
      local r = bix(b)
    end
  else
    assert(false, 'end: not atom');
  end
end

--  cut: slice bites
--
function cut(b, c, d, a)
  return ned(cons(b, d), rsh(cons(b, c), a));
end

--  cat: concatenate
--
function cat(b, a, c)
  local s = met(b, a);
  return add(a, lsh(cons(b, s), c));
end

--  mix: binary xor
--
function mix(a, b)
  if type(a) == 'number' and type(b) == 'number' then
    return bit.bxor(a, b);
  else
    a = grow(a);
    b = grow(b);
    local i = 1;
    local o = '';
    while i <= #a or i <= #b do
      local c = string.byte(a, i) or 0;
      local d = string.byte(b, i) or 0;
      o = o .. string.char(bit.bxor(c, d));
      i = i + 1;
    end
    return curl(o);
  end
end

--  met: measure blocwidth
--
function met(b, a)
  if type(a) == 'number' then
    local c = 0;
    while a ~= 0 do
      a = rsh(b, a);
      c = c + 1;
    end
    return c;
  elseif type(a) == 'string' then
    local w8 = #a;
    if b == 3 then
      return w8;  --NOTE  relies on string atom hygeine!
    else
      local lead = met(0, string.byte(a, w8));
      --NOTE  larger blocsizes don't need
      if b > 3 then
        local bits = ((w8-1) * 8) + lead;
        return math.ceil( bits / bex(b) );
      else
        local bits = add(mul(sub(w8, 1), 8), lead);  --TODO  dec?
        return div(bits, bex(b));
      end
    end
  else
    assert(false, 'met: not atom');
  end
end

--  mat: length-encode (result, bitlength)
--
function mat(a)
  assert(type(a) == 'number' or type(a) == 'string', 'mat: not atom');
  if a == 0 then
    return 1, 1;
  end
  local b = met(0, a);
  local c = met(0, b);
  local d = cons(0, c-1);
  return add(add(c, c), b),
         cat(0, bex(c), mix( ned(d, b), lsh(d, a) ));
end

--  rub: length-decode (value, bitlength)
--
function rub(a, b)
  assert(type(a) == 'number' or type(a) == 'string', 'rub: a not atom');
  assert(type(b) == 'number' or type(b) == 'string', 'rub: b not atom');
  local c = 0;
  local m = met(0, b);
  assert(lte(c, m), 'rub: invalid?');
  while 0 == cut(0, add(a, c), 1, b) do
    assert(lte(c, m), 'rub: invalid?');
    c = add(c, 1);
  end
  if c == 0 then
    return 0, 1;
  end
  local d = add(a, add(c, 1));  --TODO  inc
  local e = add(bex(sub(c, 1)), cut(0, d, sub(c, 1), b)); --TODO  dec
  return cut(0, add(d, sub(c, 1)), e, b),
         add(add(c, c), e);
end

--  jam: pack a lua noun into a lua atom
--
function jam(n, i, m)
  i = i or 0;
  m = m or {};
  if m[n] then
    if type(n) ~= 'table' and lte(met(0, n), met(0, m[n])) then
      local p, q = mat(n);
      return lsh(0, q), add(1, p), m;
    else
      local p, q = mat(m[n]);
      return mix(3, lsh(cons(0, 2), q)), add(2, p), m;
    end
  elseif type(n) == 'number' or type(n) == 'string' then
    m[n] = i;
    local p, q = mat(n);
    return lsh(0, q), add(1, p), m;
  elseif type(n) == 'table' then
    --TODO  figure out how to use cells as keys so we can deduplicate them
    --      perhaps just use the jam value?
    --      but then we'd have to do that for atoms too, which is a bit sad...
    i = add(i, 2);
    local jh, ih, m = jam(head(n), i, m);
    local jt, it, m = jam(tail(n), add(i, ih), m);
    return mix(1, lsh(cons(0, 2), cat(0, jh, jt))),
           add(2, add(ih, it)),
           m;
  else
    assert(false, 'jam: not noun');
  end
end

--  cue: unpack a lua atom into a lua noun
--
function cue(a, i, m)
  assert(type(a) == 'number' or type(a) == 'string', 'cue: not atom');
  i = i or 0;
  m = m or {};

  if 0 == cut(0, i, 1, a) then
    local p, q = rub(add(i, 1), a);
    m[i] = p;
    return p, add(q, 1), m;
  end
  local c = add(2, i);
  if 0 == cut(0, add(i, 1), 1, a) then
    local dh, ih, m = cue(a, c, m);
    local dt, it, m = cue(a, add(ih, c), m);
    local n = cons(dh, dt);
    m[i] = n;
    return n, add(2, add(ih, it)), m;
  else
    local p, q = rub(c, a);
    assert(m[p], 'cue: nil ref');
    return m[p], add(2, q), m;
  end
end


local j = jam(0);
local c = cue(j);
print(show(j), show(c));

local j = jam(5);
local c = cue(j);
print(show(j), show(c));

local j = jam(cons(5, 5));
local c = cue(j);
print(show(j), show(c));

local j = jam(cons(0xffffffffff, 0xffffffffff));
local c = cue(j);
print(show(j), show(c));


return 0;
