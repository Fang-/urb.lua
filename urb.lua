local bn = require("lib/bn")  -- in urb.nom

local urb = {
  _VERSION     = "urb.lua v0.1.0",
  _DESCRIPTION = "Urbit things, in Lua.",
  _URL         = "https://github.com/Fang-/urb.lua",
  _LICENSE     = "MIT License"
}

--------------------------------------------------------------------------------
-- core, urbit http communication
--------------------------------------------------------------------------------
--TODO some code for this already exists, but auth isn't actually functional and
--     %eyre may or may not be conforming to its own spec. will provide a proper
--     urbit-comms module once the http api stabilizes.
--------------------------------------------------------------------------------

-- ...

-- urb core ------------------------------------------------------------------------

--------------------------------------------------------------------------------
urb.nom = {} -- ship names & numbers
-- special thanks to asssaf for writing a similar ++ob implementation in python:
-- https://github.com/asssaf/urbit-shipyard/blob/master/ob/ob.py
--------------------------------------------------------------------------------
-- nume ( ship name )
--   => address number
-- nome ( address number )
--   => ship name
-- clan ( ship name or address number (int or bn) )
--   => "galaxy", "star", "planet", "moon" or "comet"
-- sein ( ship name or address number (int or bn) )
--   => parent name or address number
--------------------------------------------------------------------------------

function urb.nom.clan(our)
  local lent
  if type(our) == "string" then
    lent = our:gsub("-", ""):gsub("~", ""):len()
    if lent % 3 ~= 0 then error("weird name "..our) end
  -- assume integer or bn
  else
    our = bn(our)
    lent = our:len_bytes() * 3
  end
  if     lent <= 3  then return "galaxy"
  elseif lent <= 6  then return "star"
  elseif lent <= 12 then return "planet"
  elseif lent <= 24 then return "moon"
  else                   return "comet"
  end
end

function urb.nom.sein(our)
  local clan = urb.nom.clan(our)
  local typ = type(our)
  if typ == "string" then
    our = urb.nom.nume(our)
  end
  our = bn(our)
  local bys
  if     clan == "galaxy" then bys = 0
  elseif clan == "star"   then bys = 2
  elseif clan == "planet" then bys = 4
  elseif clan == "moon"   then bys = 6
  end
  local res = bn(0)
  if bys then
    res = bn("0x"..our:ashex():sub(-bys))
  end
  if typ == "string" then
    return urb.nom.nome(res)
  end
  return res
end

function urb.nom.nume(name)
  local nome = name:gsub("-", ""):gsub("~", "")
  local lent = nome:len()
  if lent % 3 ~= 0 then error("weird name "..name) end
  local syls = lent / 3
  if syls > 1 and syls % 2 ~= 0 then error("weird name "..name) end
  -- galaxy
  if syls == 1 then
    return bn(urb.nom.wordtonum(nome))
  -- planet or moon
  elseif syls >= 4 and syls <= 8 then
    local padr = urb.nom.wordtonum(nome:sub(lent-11, lent-6))
    padr = padr * 0x10000
    padr = padr + urb.nom.wordtonum(nome:sub(lent-5, lent))
    padr = urb.nom.fend(padr)
    if syls == 4 then
      return padr
    end
    local addr = 0
    for i = 0, syls-6, 2 do
      addr = addr + urb.nom.wordtonum(nome:sub(i*3+1, i*3+6))
      addr = addr * 0x10000
    end
    return (addr * 0x10000) + padr
  -- anything else
  else
    local addr = bn(0)
    for i = 0, syls-2, 2 do
      addr = addr * 0x10000
      addr = addr + urb.nom.wordtonum(nome:sub(i*3+1, i*3+6))
    end
    return addr
  end
end

function urb.nom.nome(addr)
  addr = bn(addr)
  local bytes = addr:len_bytes()
  if bytes > 1 and bytes % 2 == 1 then bytes = bytes + 1 end
  local name = ""
  -- unscramble planet/moon
  if bytes >= 4 and bytes <= 8 then
    local padr = (addr % 0x100000000)
    local nadr = urb.nom.feen(padr)
    addr = addr - padr + nadr
  end
  for i = 0, bytes-1 do
    local byte = (addr % 0x100):asnumber()
    local syllable
    if i % 2 == 1 then
      syllable = urb.nom.getprefix(byte)
    else
      syllable = urb.nom.getsuffix(byte)
    end
    if i > 0 and i % 2 == 0 then
      name = "-" .. name
    end
    if i > 0 and i % 8 == 0 then
      name = "-" .. name
    end
    name = syllable .. name
    addr = addr / 0x100
  end
  return name
end

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

urb.nom.raku = {
  [0] = 3077398253,
  [1] = 3995603712,
  [2] = 2243735041,
  [3] = 1261992695
}

urb.nom.prefix = "dozmarbinwansamlitsighidfidlissogdirwacsabwissibrigsoldopmodfoglidhopdardorlorhodfolrintogsilmirholpaslacrovlivdalsatlibtabhanticpidtorbolfosdotlosdilforpilramtirwintadbicdifrocwidbisdasmidloprilnardapmolsanlocnovsitnidtipsicropwitnatpanminritpodmottamtolsavposnapnopsomfinfonbanmorworsipronnorbotwicsocwatdolmagpicdavbidbaltimtasmalligsivtagpadsaldivdactansidfabtarmonranniswolmispallasdismaprabtobrollatlonnodnavfignomnibpagsopralbilhaddocridmocpacravripfaltodtiltinhapmicfanpattaclabmogsimsonpinlomrictapfirhasbosbatpochactidhavsaplindibhosdabbitbarracparloddosbortochilmactomdigfilfasmithobharmighinradmashalraglagfadtopmophabnilnosmilfopfamdatnoldinhatnacrisfotribhocnimlarfitwalrapsarnalmoslandondanladdovrivbacpollaptalpitnambonrostonfodponsovnocsorlavmatmipfip"

urb.nom.suffix = "zodnecbudwessevpersutletfulpensytdurwepserwylsunrypsyxdyrnuphebpeglupdepdysputlughecryttyvsydnexlunmeplutseppesdelsulpedtemledtulmetwenbynhexfebpyldulhetmevruttylwydtepbesdexsefwycburderneppurrysrebdennutsubpetrulsynregtydsupsemwynrecmegnetsecmulnymtevwebsummutnyxrextebfushepbenmuswyxsymselrucdecwexsyrwetdylmynmesdetbetbeltuxtugmyrpelsyptermebsetdutdegtexsurfeltudnuxruxrenwytnubmedlytdusnebrumtynseglyxpunresredfunrevrefmectedrusbexlebduxrynnumpyxrygryxfeptyrtustyclegnemfermertenlusnussyltecmexpubrymtucfyllepdebbermughuttunbylsudpemdevlurdefbusbeprunmelpexdytbyttyplevmylwedducfurfexnulluclennerlexrupnedlecrydlydfenwelnydhusrelrudneshesfetdesretdunlernyrsebhulrylludremlysfynwerrycsugnysnyllyndyndemluxfedsedbecmunlyrtesmudnytbyrsenwegfyrmurtelreptegpecnelnevfes"

function urb.nom.getsyllable(s, i)
  return s:sub(i*3 + 1, i*3 + 3)
end

function urb.nom.getprefix(i)
  return urb.nom.getsyllable(urb.nom.prefix, i)
end

function urb.nom.getsuffix(i)
  return urb.nom.getsyllable(urb.nom.suffix, i)
end

function urb.nom.getsyllableindex(str, syl)
  local i = str:find(syl)
  if not i then error("unknown syllable "..syl) end
  return (i-1)/3
end

function urb.nom.getprefixindex(syl)
  return urb.nom.getsyllableindex(urb.nom.prefix, syl)
end

function urb.nom.getsuffixindex(syl)
  return urb.nom.getsyllableindex(urb.nom.suffix, syl)
end

function urb.nom.wordtonum(word)
  if word:len() == 3 then
    return 1 * urb.nom.getsuffixindex(word)
  elseif word:len() == 6 then
    local addr = urb.nom.getprefixindex(word:sub(1, 3))
    addr = addr * 0x100
    addr = addr + urb.nom.getsuffixindex(word:sub(4, 6))
    return addr
  else
    error("weird word "..word)
  end
end

function urb.nom.feen(pyn)
  if pyn >= 0x10000 and pyn <= 0xFFFFFFFF then
    return 0x10000 + urb.nom.fice(pyn - 0x10000)
  end
  if pyn >= 0x100000000 and pyn <= bn("18446744073709552000") then
    local lo = pyn & 0xFFFFFFFF
    local hi = pyn & bn("18446744069414584000")
    return hi | urb.nom.feen(lo)
  end
  return pyn
end

function urb.nom.fend(cry)
  if cry >= 0x10000 and cry <= 0xFFFFFFFF then
    return 0x10000 + urb.nom.teil(cry - 0x10000)
  end
  if cry >= 0x100000000 and cry <= bn("18446744073709552000") then
    local lo = cry & 0xFFFFFFFF
    local hi = cry & bn("18446744069414584000")
    return hi | urb.nom.fend(lo)
  end
  return cry
end

function urb.nom.fice(nor)
  local sel = {nor % 0xFFFF, nor / 0x10000}
  for i = 0, 3 do
    sel = urb.nom.rynd(i, sel[1], sel[2])
  end
  return 0xFFFF * sel[1] + sel[2]
end

function urb.nom.teil(vip)
  local sel = {vip % 0xFFFF, vip / 0x10000}
  for i = 3, 0, -1 do
    sel = urb.nom.rund(i, sel[1], sel[2])
  end
  return 0xFFFF * sel[1] + sel[2]
end

function urb.nom.rynd(n, l, r)
  local res = {r, 0}
  local m = 0x10000
  if n % 2 == 0 then
    m = 0xFFFF
  end
  res[2] = (l + urb.nom.muk(urb.nom.raku[n], r)) % m
  return res
end

function urb.nom.rund(n, l, r)
  local res = {r, 0}
  local m = 0x10000
  if n % 2 == 0 then
    m = 0xFFFF
  end
  local h = urb.nom.muk(urb.nom.raku[n], r)
  res[2] = (m + l - (h%m)) % m
  return res
end

function urb.nom.muk(syd, key)
  key = bn(key)
  local lo = key & 0xFF
  local hi = (key & 0xFF00) / 0x100
  return urb.nom.murmur3(
           string.char(lo:asnumber())
           .. string.char(hi:asnumber()),
           syd)
end

function urb.nom.murmur3(data, seed)
  seed = seed or 0
  seed = bn(seed)
  local c1 = 3432918353
  local c2 = 461845907
  local length = data:len()
  local h1 = seed
  local k1
  local roundedEnd = length & 0xFFFFFFFC
  for i = 0, roundedEnd-1, 4 do
    k1 = bn(data:byte(i+1) & 0xFF)
         | ((data:byte(i+2) & 0xFF) << 8)
         | ((data:byte(i+3) & 0xFF) << 16)
         | ((data:byte(i+4) or 0) << 24)
    k1 = k1 * c1
    k1 = (k1 << 15) | ((k1 & 0xFFFFFFFF) >> 17)
    k1 = k1 * c2
    h1 = h1 ~ k1
    h1 = (h1 << 13) | ((h1 & 0xFFFFFFFF) >> 19)
    h1 = h1 * 5 + 3864292196
  end
  k1 = 0
  local val = length & 3
  if val == 3 then
    k1 = bn(data:byte(roundedEnd+3) & 0xFF) << 16
  end
  if val == 3 or val == 2 then
    k1 = k1 | (bn(data:byte(roundedEnd+2) & 0xFF) << 8)
  end
  if val == 3 or val == 2 or val == 1 then
    k1 = k1 | (data:byte(roundedEnd+1) & 0xFF)
    k1 = k1 * c1
    k1 = (k1 << 15) | ((k1 & 0xFFFFFFFF) >> 17)
    k1 = k1 * c2
    h1 = h1 ~ k1
  end
  h1 = h1 ~ length
  h1 = h1 ~ ((h1 & 0xFFFFFFFF) >> 16)
  h1 = h1 * 2246822507
  h1 = h1 ~ ((h1 & 0xFFFFFFFF) >> 13)
  h1 = h1 * 3266489909
  h1 = h1 ~ ((h1 & 0xFFFFFFFF) >> 16)
  return h1 & 0xFFFFFFFF
end

-- urb.nom ---------------------------------------------------------------------

return urb
