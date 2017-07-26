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
--------------------------------------------------------------------------------

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
    padr = padr * 65536
    padr = padr + urb.nom.wordtonum(nome:sub(lent-5, lent))
    padr = urb.nom.fend(padr)
    if syls == 4 then
      return padr
    end
    local addr = 0
    for i = 0, syls-6, 2 do
      addr = addr + urb.nom.wordtonum(nome:sub(i*3+1, i*3+6))
      addr = addr * 65536
    end
    return (addr * 65536) + padr
  -- anything else
  else
    local addr = bn(0)
    for i = 0, syls-2, 2 do
      addr = addr * 65536
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
    local padr = (addr % 4294967296)
    local nadr = urb.nom.feen(padr)
    addr = addr - padr + nadr
  end
  for i = 0, bytes-1 do
    local byte = (addr % 256):asnumber()
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
    addr = addr / 256
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
    addr = addr * 256
    addr = addr + urb.nom.getsuffixindex(word:sub(4, 6))
    return addr
  else
    error("weird word "..word)
  end
end

function urb.nom.feen(pyn)
  if pyn >= 65536 and pyn <= 4294967295 then
    return 65536 + urb.nom.fice(pyn - 65536)
  end
  if pyn >= 4294967296 and pyn <= bn("18446744073709552000") then
    local lo = pyn & 4294967295
    local hi = pyn & bn("18446744069414584000")
    return hi | urb.nom.feen(lo)
  end
  return pyn
end

function urb.nom.fend(cry)
  if cry >= 65536 and cry <= 4294967295 then
    return 65536 + urb.nom.teil(cry - 65536)
  end
  if cry >= 4294967296 and cry <= bn("18446744073709552000") then
    local lo = cry & 4294967295
    local hi = cry & bn("18446744069414584000")
    return hi | urb.nom.fend(lo)
  end
  return cry
end

function urb.nom.fice(nor)
  local sel = {nor % 65535, nor / 65536}
  for i = 0, 3 do
    sel = urb.nom.rynd(i, sel[1], sel[2])
  end
  return 65535 * sel[1] + sel[2]
end

function urb.nom.teil(vip)
  local sel = {vip % 65535, vip / 65536}
  for i = 3, 0, -1 do
    sel = urb.nom.rund(i, sel[1], sel[2])
  end
  return 65535 * sel[1] + sel[2]
end

function urb.nom.rynd(n, l, r)
  local res = {r, 0}
  local m = 65536
  if n % 2 == 0 then
    m = 65535
  end
  res[2] = (l + urb.nom.muk(urb.nom.raku[n], r)) % m
  return res
end

function urb.nom.rund(n, l, r)
  local res = {r, 0}
  local m = 65536
  if n % 2 == 0 then
    m = 65535
  end
  local h = urb.nom.muk(urb.nom.raku[n], r)
  res[2] = (m + l - (h%m)) % m
  return res
end

function urb.nom.muk(syd, key)
  key = bn(key)
  local lo = key & 255
  local hi = (key & 65280) / 256
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
  local roundedEnd = length & 4294967292
  for i = 0, roundedEnd-1, 4 do
    k1 = bn(data:byte(i+1) & 255)
         | ((data:byte(i+2) & 255) << 8)
         | ((data:byte(i+3) & 255) << 16)
         | ((data:byte(i+4) or 0) << 24)
    k1 = k1 * c1
    k1 = (k1 << 15) | ((k1 & 4294967295) >> 17)
    k1 = k1 * c2
    h1 = h1 ~ k1
    h1 = (h1 << 13) | ((h1 & 4294967295) >> 19)
    h1 = h1 * 5 + 3864292196
  end
  k1 = 0
  local val = length & 3
  if val == 3 then
    k1 = bn(data:byte(roundedEnd+3) & 255) << 16
  end
  if val == 3 or val == 2 then
    k1 = k1 | (bn(data:byte(roundedEnd+2) & 255) << 8)
  end
  if val == 3 or val == 2 or val == 1 then
    k1 = k1 | (data:byte(roundedEnd+1) & 255)
    k1 = k1 * c1
    k1 = (k1 << 15) | ((k1 & 4294967295) >> 17)
    k1 = k1 * c2
    h1 = h1 ~ k1
  end
  h1 = h1 ~ length
  h1 = h1 ~ ((h1 & 4294967295) >> 16)
  h1 = h1 * 2246822507
  h1 = h1 ~ ((h1 & 4294967295) >> 13)
  h1 = h1 * 3266489909
  h1 = h1 ~ ((h1 & 4294967295) >> 16)
  return h1 & 4294967295
end

-- urb.nom ---------------------------------------------------------------------

return urb
