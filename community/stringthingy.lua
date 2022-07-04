local strMagic = "([%^%$%(%)%%%.%[%]%*%+%-%?])"    -- UTF-8 replacement for "(%W)"

-- Hide magic pattern symbols  ^ $ ( ) % . [ ] * + - ?
function plain(strTxt)
  -- Prefix every magic pattern character with a % escape character,
  -- where %% is the % escape, and %1 is the original character capture.
  strTxt = tostring(strTxt or ""):gsub(strMagic,"%%%1")
  return strTxt
end -- function plain

-- matches is plain text version of string.match()
function matches(strTxt,strFind,intInit)
  strFind = tostring(strFind or ""):gsub(strMagic,"%%%1")  -- Hide magic pattern symbols
  return tostring(strTxt or ""):match(strFind,tonumber(intInit))
end -- function matches

-- replace is plain text version of string.gsub()
function replace(strTxt,strOld,strNew,intNum)
  strOld = tostring(strOld or ""):gsub(strMagic,"%%%1")  -- Hide magic pattern symbols
  return tostring(strTxt or ""):gsub(strOld,function() return strNew end,tonumber(intNum))  -- Hide % capture symbols
end -- function replace

-- convert is pattern without captures version of string.gsub()
function convert(strTxt,strOld,strNew,intNum)
  return tostring(strTxt or ""):gsub(tostring(strOld or ""),function() return strNew end,tonumber(intNum))  -- Hide % capture symbols
end -- function convert


    local strInput = "abc 90% xyz"
    local strMatch = "90%"
    local strPlain = "75%"
    print( strInput:plain() )            -->>  abc% 90%%% xyz
    print( strInput:gsub( string.plain(strMatch), strPlain:plain() ) )  -->>  abc 75% xyz  1
    print( strInput:matches(strMatch, 3) )          -->>  90%
    print( strInput:replace(strMatch,strPlain) )        -->>  abc 75% xyz  1
    print( strInput:convert( "%d+.", strPlain) )        -->>   abc 75% xyz  1

    -- https://fhug.org.uk/kb/code-snippet/plain-text-substitution/