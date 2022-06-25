--- Colors library for embedded color processing in the FANDOM environment.
--  It ports and extends functionality in the Colors JS library written by
--  [[User:Pecoes|Pecoes]]. The module supports HSL, RGB and hexadecimal web
--  colors.
--  
--  The module offers numerous features:
--   * Color parameter support in Lua modules.
--   * Color parameter insertion in wiki templates.
--   * Color variable parsing for style templating.
--   * Color item creation and conversion utilities.
--   * A vast array of color processing methods.
--   * Alpha and boolean support for flexible color logic.
--  
--  **This module will not work as expected on UCP wikis.**
--  
--  @module             colors
--  @alias              p
--  @release            unmaintained
--  @author             [[User:Speedit|Speedit]]
--  @version            2.5.2
--  @require            Module:I18n
--  @require            Module:Yesno
--  @require            Module:Entrypoint
--  <nowiki>

-- Module package.
local p, utils, Color = {}, {}

-- Module utilites, configuration/cache variables.
local yesno = require('Dev:Yesno')
local entrypoint = require('Dev:Entrypoint')
local sassParams = mw.site.sassParams or {}

-- Web color RGB presets.
local presets = mw.loadData('Dev:Colors/presets')

-- Error message data.
local i18n = require('Dev:I18n').loadMessages('Colors')

-- Validation ranges for color types and number formats.
local ranges = {
    rgb         = {    0, 255 },
    hsl         = {    0,   1 },
    hue         = {    0, 360 },
    percentage  = { -100, 100 },
    prop        = {    0, 100 },
    degree      = { -360, 360 }
}

-- Internal color utilities.

--- Boundary validation for color types.
--  @function           utils.check
--  @param              {string} t Range type.
--  @param              {number} n Number to validate.
--  @error[65]          {string} 'invalid color value input: type($n) "$n"'
--  @error[67]          {string} 'color value $n out of $t bounds'
--  @return             {boolean} Validity of number.
--  @local
function utils.check(t, n)
    local min = ranges[t][1] -- Boundary variables
    local max = ranges[t][2]

    if type(n) ~= 'number' then
        error(i18n:msg('invalid-value', type(n), tostring(n)))
    elseif n < min or n > max then
        error(i18n:msg('out-of-bounds', n, t))
    end
end

--- Rounding utility for color tuples.
--  @function           utils.round
--  @param              {number} tup Color tuple.
--  @param[opt]         {number} dec Number of decimal places.
--  @return             {number} Rounded tuple value.
--  @local
function utils.round(tup, dec)
    local ord = 10^(dec or 0)
    return math.floor(tup * ord + 0.5) / ord
end

--- Cloning utility for color items.
--  @function           utils.clone
--  @param              {table} clr Color instance.
--  @param              {string} typ Color type of clone.
--  @return             {table} New (clone) color instance.
--  @local
function utils.clone(clr, typ)
    local c = Color:new( clr.tup, clr.typ, clr.alp ) -- new color
    utils.convert(c, typ) -- conversion
    return c -- output
end

--- Range limiter for color processing.
--  @function           utils.limit
--  @param              {number} val Numeric value to limit.
--  @param              {number} max Maximum value for limit boundary.
--  @return             {number} Limited value.
--  @local
function utils.limit(val, max)
    return math.max(0, math.min(val, max))
end

--- Circular spatial processing for ranges.
--  @function           utils.circle
--  @param              {number} val Numeric value to cycle.
--  @param              {number} max Maximum value for cycle boundary.
--  @return             {number} Cyclical positive value below max.
--  @local
function utils.circle(val, max)
    if val < 0 then        -- negative; below cycle minimum
        val = val + max
    elseif val > max then  -- exceeds cycle maximum
        val = val - max
    end
    return val -- output
end

--- Color space converter.
--  @function           utils.convert
--  @param              {table} clr Color instance.
--  @param              {string} typ Color type to output.
--  @return             {table} Converted color instance.
--  @local
function utils.convert(clr, typ)
    if clr.typ ~= typ then
        clr.typ   = typ
        if typ == 'rgb' then
            clr.tup = utils.hslToRgb(clr.tup)
        else
            clr.tup = utils.rgbToHsl(clr.tup)
        end
    end

    for i, t in ipairs(clr.tup) do
        if clr.typ == 'rgb' then
            clr.tup[i] = utils.round(clr.tup[i], 0)
        elseif clr.typ == 'hsl' then
            clr.tup[i] = i == 1
                and utils.round(clr.tup[i], 0)
                or  utils.round(clr.tup[i], 2)
        end
    end
end

--- RGB-HSL tuple converter.
--  @function           utils.rgbToHsl
--  @param              {table} rgb Tuple table of RGB values.
--  @return             {table} Tuple table of HSL values.
--  @see                http://www.easyrgb.com/en/math.php#m_rgb_hsl
--  @local
function utils.rgbToHsl(rgb)
    for i, t in ipairs(rgb) do
        rgb[i] = t/255
    end
    local r,g,b = rgb[1], rgb[2], rgb[3]

    local min = math.min(r, g, b)
    local max = math.max(r, g, b)
    local d = max - min

    local h, s, l = 0, 0, ((min + max) / 2)

    if d > 0 then
        s = l < 0.5 and d / (max + min) or d / (2 - max - min)

        h = max == r and (g - b) / d or
            max == g and 2 + (b - r)/d or
            max == b and 4 + (r - g)/d
        h = utils.circle(h/6, 1)
    end

    return { h * 360, s, l }
end

--- HSL component conversion subroutine to RGB.
--  @function           utils.hueToRgb
--  @param              {number} p Temporary variable 1.
--  @param              {number} q Temporary variable 2.
--  @param              {number} t Modifier for primary color.
--  @return             {number} HSL component.
--  @see                http://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
--  @local
function utils.hueToRgb(p, q, t)
    if t < 0 then
        t = t + 1
    elseif t > 1 then
        t = t - 1
    end

    if t < 1/6 then
        return p + (q - p) * 6 * t
    elseif t < 1/2 then
        return q
    elseif t < 2/3 then
        return p + (q - p) * (2/3 - t) * 6
    else
        return p
    end
end

--- HSL-RGB tuple converter.
--  @function           utils.hslToRgb
--  @param              {table} hsl Tuple table of HSL values.
--  @return             {table} Tuple table of RGB values.
--  @local
function utils.hslToRgb(hsl)
    local h, s, l = hsl[1]/360, hsl[2], hsl[3]
    local r
    local g
    local b
    local p
    local q

    if s == 0 then
        r, g, b = l, l, l

    else
        q = l < 0.5 and l * (1 + s) or l + s - l * s

        p = 2 * l - q

        r = utils.hueToRgb(p, q, h + 1/3)
        g = utils.hueToRgb(p, q, h)
        b = utils.hueToRgb(p, q, h - 1/3)
    end

    return { r * 255, g * 255, b * 255 }
end

--- Percentage-number conversion utility.
--  @function       utils.np
--  @param          {string} str Number string.
--  @param          {number} mul Upper bound number multiplier.
--  @return         {number} Bounded number.
--  @local
function utils.np(str, mul)
    str = str:match('^%s*([^%%]+)%%%s*$')
    local pct = tonumber(str)
    return pct * mul
end

--- CSS color functional notation parser.
--  @function       utils.parseColorSpace
--  @param          {string} str Color string.
--  @param          {string} spc Color function name.
--  @param          {table} mul Tuple color multipliers.
--  @return         {table} Color space tuple.
--  @return         {table} Color alpha value.
--  @local
function utils.parseColorSpace(str, spc, mul)
    local PTN = '^' .. spc .. 'a?%(([%d%s%%.,]+)%)$'
    local tup = mw.text.split(str:match(PTN), '[%s,]+')

    tup[4] = tup[4] or '1'
    local alp = tup[4]:find('%%$')
        and utils.np(tup[4], 1/100)
        or  tonumber(tup[4])
    table.remove(tup, 4)

    for i, t in ipairs(tup) do
        tup[i] = t:find('%%$')
            and utils.np(t, mul[i])
            or  tonumber(t)
    end

    return tup, alp
end

--- Color item class, used for color processing.
--  The class provides color prop getter-setters, procedures for color computation,
--  compositing methods and serialisation into CSS color formats.
--  @type               Color
Color = {}
Color.__index = Color
Color.__tostring = function() return 'Color' end

--- Color tuple.
--  @table              Color.tup
Color.tup = {}

--- Color space type.
--  @member             {string} Color.typ
Color.typ = ''

--- Color alpha channel value.
--  @member             {number} Color.alp
Color.alp = 1

--- Color instance constructor.
--  @function           Color:new
--  @param              {string} typ Color space type (`'hsl'` or `'rgb'`).
--  @param              {table} tup Color tuple in HSL or RGB
--  @param              {number} alp Alpha value range (`0` - `1`).
--  @error[304]         {string} 'no color data provided'
--  @error[309]         {string} 'invalid color type "$1" specified'
--  @return             {Color} Color instance.
function Color:new(tup, typ, alp)
    local o = {}
    setmetatable(o, self)

    -- is color tuple valid?
    if type(tup) ~= 'table' or #tup ~= 3 then
        error(i18n:msg('no-data'))
    end

    -- is color type valid?
    if typ ~= 'rgb' and typ ~= 'hsl' then
        error(i18n:msg('invalid-type', typ))
    end

    -- are color tuple entries valid?
    for n = 1, 3 do
        utils.check( (n == 1 and typ == 'hsl') and 'hue' or typ, tup[n])
    end
    utils.check('hsl', alp)

    o.tup = tup
    o.typ = typ
    o.alp = alp
    return o
end

--- Color string default output.
--  @function           Color:string
--  @return             {string} Hexadecimal 6-digit or HSLA color string.
--  @usage              colors.parse('hsl(214, 15%, 30%)'):string() == '#404a57'
--  @usage              colors.parse('#404a5780'):string() == 'hsl(214, 15%, 30%, 0.5)'
function Color:string()
    return self.alp ~= 1 and self:hsl() or self:hex()
end

--- Color hexadecimal string output.
--  @function           Color:hex
--  @return             {string} Hexadecimal color string.
--  @usage              colors.parse('hsl(214, 15%, 30%)'):hex() == '#404a57'
function Color:hex()
    local this = utils.clone(self, 'rgb')
    local hex = '#'

    for i, t in ipairs(this.tup) do
        -- Hexadecimal conversion.
        hex = #string.format('%x', t) == 1 -- leftpad
            and hex .. '0' .. string.format('%x', t)
            or hex .. string.format('%x', t)
    end

    local alp = string.format('%x', this.alp * 255)
    if alp ~= 'ff' then
        hex = #alp == 1 and hex .. '0' .. alp or hex .. alp
    end

    return hex
end

--- RGBA functional color string output.
--  @function           Color:rgb
--  @return             {string} RGBA color string.
--  @see                https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#rgb()_and_rgba()
--  @usage              colors.parse('hsl(214, 15%, 30%)'):rgb() == 'rgb(64, 74, 87)'
function Color:rgb()
    local this = utils.clone(self, 'rgb')

    return this.alp ~= 1
        and 'rgba(' .. table.concat(this.tup, ', ') .. ', ' .. this.alp .. ')'
        or  'rgb(' .. table.concat(this.tup, ', ') .. ')'
end

--- HSL functional color string output.
--  @function           Color:hsl
--  @return             {string} HSLA color string.
--  @see                https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#hsl()_and_hsla()
--  @usage              colors.parse('rgb(64, 74, 87)'):hsl() == 'hsl(214, 15%, 30%)'
function Color:hsl()
    local this = utils.clone(self, 'hsl')

    for i, t in ipairs(this.tup) do
        if i == 2 or i == 3 then
            this.tup[i] = tostring(t*100) .. '%'
        end
    end

    return this.alp ~= 1
        and 'hsla(' .. table.concat(this.tup, ', ') .. ', ' .. this.alp .. ')'
        or  'hsl(' .. table.concat(this.tup, ', ') .. ')' 
end

--- Red color property getter-setter.
--  @function           Color:red
--  @param[opt]         {number} val Red value to set (`1` - `255`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#000000'):red(255):string() == '#ff0000'
function Color:red(val)
    local this = utils.clone(self, 'rgb')
    if val then
        utils.check('rgb', val)

        this.tup[1] = val
        return this -- chainable
    else
        return this.tup[1]
    end
end

--- Green color property getter-setter.
--  @function           Color:green
--  @param[opt]         {number} val Green value to set (`1` - `255`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ffffff'):green(1):string() == '#ff00ff'
function Color:green(val)
    local this = utils.clone(self, 'rgb')
    if val then
        utils.check('rgb', val)

        this.tup[2] = val
        return this -- chainable
    else
        return this.tup[2]
    end
end

--- Blue color property getter-setter.
--  @function           Color:blue
--  @param[opt]         {number} val Blue value to set (`1` - `255`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#00ff00'):blue(255):string() == '#00ffff'
function Color:blue(val)
    local this = utils.clone(self, 'rgb')
    if val then
        utils.check('rgb', val)

        this.tup[3] = val
        return this -- chainable
    else
        return this.tup[3]
    end
end

--- Hue color property getter-setter.
--  @function           Color:hue
--  @param[opt]         {number} val Hue value to set (`0` - `360`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff0000'):hue(180):string() == '#00ffff'
function Color:hue(val) 
    local this = utils.clone(self, 'hsl')
    if val then
        utils.check('hue', val)

        this.tup[1] = val
        return this -- chainable
    else
        return this.tup[1]
    end
end

--- Saturation color property getter-setter.
--  @function           Color:sat
--  @param[opt]         {number} val Saturation value to set (`0` - `100`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff0000'):sat(0):string() == '#808080'
function Color:sat(val)
    local this = utils.clone(self, 'hsl')
    if val then
        val = val / 100
        utils.check('hsl', val)

        this.tup[2] = val
        return this -- chainable
    else
        return this.tup[2]
    end
end

--- Lightness color property getter-setter.
--  @function           Color:lum
--  @param[opt]         {number} val Luminosity value to set (`0` - `100`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff0000'):lum(0):string() == '#000000'
function Color:lum(val)
    local this = utils.clone(self, 'hsl')
    if val then
        val = val / 100
        utils.check('hsl', val)

        this.tup[3] = val
        return this -- chainable
    else
        return this.tup[3]
    end
end

--- Alpha getter-setter for color compositing.
--  @function           Color:alpha
--  @param              {number} val Modifier 0 - 100.
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ffffff'):alpha(0):string() == 'hsla(0, 0%, 0%, 0)'
function Color:alpha(val)
    if val then
        utils.check('prop', val)
        self.alp = val / 100

        return self
    else
        return self.alp
    end
end

--- Post-processing operator for color hue rotation.
--  @function           Color:rotate
--  @param              {number} mod Modifier (`-360` - `360`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff0000'):rotate(60):string() == '#ffff00'
function Color:rotate(mod) 
    utils.check('degree', mod)
    local this = utils.clone(self, 'hsl')
    this.tup[1] = utils.circle(this.tup[1] + mod, 360)
    return this
end

--- Post-processing operator for web color saturation.
--  @function           Color:saturate
--  @param              {number} mod Modifier (`-100` - `100`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff0000'):saturate(-25):string() == '#df2020'
function Color:saturate(mod)
    utils.check('percentage', mod)
    local this = utils.clone(self, 'hsl')
    this.tup[2] = utils.limit(this.tup[2] + (mod / 100), 1)
    return this
end

--- Post-processing operator for web color lightness.
--  @function           Color:lighten
--  @param              {number} mod Modifier (`-100` - `100`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff0000'):lighten(25):string() == '#ff8080'
function Color:lighten(mod)
    utils.check('percentage', mod)
    local this = utils.clone(self, 'hsl')
    this.tup[3] = utils.limit(this.tup[3] + (mod / 100), 1)
    return this
end

--- Opacification utility for color compositing.
--  @function           Color:opacify
--  @param              {number} mod Modifier (`-100` - `100`).
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ffffff'):opacify(-25):string() == 'hsla(0, 0%, 100%, 0.75)'
function Color:opacify(mod)
    utils.check('percentage', mod)
    self.alp = utils.limit(self.alp + (mod / 100), 1)
    return self
end

--- Color additive mixing utility.
--  @function           Color:mix
--  @param              {string|table} other Module-compatible color string or instance.
--  @param[opt]         {number} weight Color weight of original (`0` - `100`). Default: `50`.
--  @return             {Color} Color instance.
--  @usage              colors.parse('#fff'):mix('#000', 80):hex() == '#cccccc'
function Color:mix(other, weight)
    if not p.instance(other) then
        other = p.parse(other)
        utils.convert(other, 'rgb')
    else
        other = utils.clone(other, 'rgb')
    end

    weight = weight or 50
    utils.check('prop', weight)
    weight = weight/100
    local this = utils.clone(self, 'rgb')

    for i, t in ipairs(this.tup) do
        this.tup[i] = t * weight + other.tup[i] * (1 - weight)
        this.tup[i] = utils.limit(this.tup[i], 255)
    end
    return this
end

--- Color inversion utility.
--  @function           Color:invert
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ffffff'):invert():hex() == '#000000'
function Color:invert()
    local this = utils.clone(self, 'rgb')

    for i, t in ipairs(this.tup) do
        this.tup[i] = 255 - t
    end
    return this
end

--- Complementary color utility.
--  @function           Color:complement
--  @return             {Color} Color instance.
--  @usage              colors.parse('#ff8000'):complement():hex() == '#0080ff'
function Color:complement()
    return self:rotate(180)
end

--- Color brightness status testing.
--  @function           Color:bright
--  @param[opt]         {number} lim Luminosity threshold. Default: `50`.
--  @return             {boolean} Boolean for tone beyond threshold.
--  @usage              colors.parse('#ff8000'):bright() == true
--  @usage              colors.parse('#ff8000'):bright(60) == false
function Color:bright(lim)
    lim = lim and tonumber(lim)/100 or 0.5
    local this = utils.clone(self, 'hsl')
    return this.tup[3] >= lim
end

--- Color luminance status testing.
--  @function            Color:luminant
--  @param[opt]          {number} lim Luminance threshold. Default: `50`.
--  @return              {boolean} Boolean for luminance beyond threshold.
--  @see                 [[wikipedia:Relative luminance|Relative luminance (Wikipedia)]]
--  @usage               colors.parse('#ffff00'):luminant() == true
--  @usage               colors.parse('#ffff00'):luminant(95) == false
function Color:luminant(lim)
    lim = lim and tonumber(lim)/100 or 0.5
    utils.check('hsl', lim)

    local hsl = utils.clone(self, 'hsl')
    local sat = hsl.tup[2]
    local lum = hsl.tup[3]
    local rgb = utils.clone(self, 'rgb').tup

    for i, t in ipairs(rgb) do
        rgb[i] = t > 0.4045 and
            math.pow(((t + 0.05) / 1.055), 2.4) or
            t / 12.92
    end

    local rel =
        rgb[1] * 0.2126 +
        rgb[2] * 0.7152 +
        rgb[3] * 0.0722

    local quo = sat * (0.2038 * (rel - 0.5) / 0.5)

    return (lum >= (lim - quo))
end

--- Color saturation and visibility status testing.
--  @function           Color:chromatic
--  @return             {boolean} Boolean for color status.
--  @usage              colors.parse('#ffff00'):chromatic() == true
function Color:chromatic()
    local this = utils.clone(self, 'hsl')
    return this.tup[2] ~= 0 and -- sat   = not 0
           this.tup[3] ~= 0 and -- lum   = not 0
           this.alp ~= 0        -- alpha = not 0
end

-- Package methods and members.

--- Creation of RGB color instances.
--  @function           p.fromRgb
--  @param              {number} r Red value (`0` - `255`).
--  @param              {number} g Green value (`0` - `255`).
--  @param              {number} b Blue (`0` - `255`).
--  @param[opt]         {number} a Alpha value (`0` - `1`).
--  @return             {Color} Color instance.
--  @usage              colors.fromRgb(255, 255, 255, 0.2)
--  @see                Color:new
function p.fromRgb(r, g, b, a)
    return Color:new({ r, g, b }, 'rgb', a or 1);
end

--- Creation of HSL color instances.
--  @function           p.fromHsl
--  @param              {number} h Hue value (`0` - `360`)
--  @param              {number} s Saturation value (`0` - `1`). 
--  @param              {number} l Luminance value (`0` - `1`).
--  @param[opt]         {number} a Alpha channel (`0` - `1`).
--  @return             {Color} Color instance.
--  @usage              colors.fromHsl(0, 0, 1, 0.2)
--  @see                Color:new
function p.fromHsl(h, s, l, a)
    return Color:new({ h, s, l }, 'hsl', a or 1);
end

--- Parsing logic for color strings.
--  @function           p.parse
--  @param              {string} str Valid color string.
--  @error[756]         {string} 'cannot parse $str'
--  @return             {Color} Color instance.
--  @see                Color:new
--  @usage              colors.parse('#ffffff')
function p.parse(str)
    local typ
    local tup = {}
    local alp = 1
    str = mw.text.trim(str)

    local VAR_PTN = '^%$([%w-]+)$'
    if p.params and p.params[str:match(VAR_PTN) or ''] then
        str = p.params[str:match(VAR_PTN)]
    end

    -- Hexadecimal color patterns.
    local HEX_PTN_3 = '^%#(%x)(%x)(%x)$'
    local HEX_PTN_4 = '^%#(%x)(%x)(%x)(%x)$'
    local HEX_PTN_6 = '^%#(%x%x)(%x%x)(%x%x)$'
    local HEX_PTN_8 = '^%#(%x%x)(%x%x)(%x%x)(%x%x)$'

    -- Hexadecimal color parsing.
    if
        str:match('^%#[%x]+$')  and
        (#str == 4 or #str == 5 or -- #xxxx?
        #str == 7 or #str == 9)    -- #xxxxxxx?x?
    then
        if #str == 4 then
            tup[1], tup[2], tup[3] = str:match(HEX_PTN_3)
        elseif #str == 5 then
            tup[1], tup[2], tup[3], alp = str:match(HEX_PTN_4)
            alp = alp .. alp
        elseif #str == 7 then
            tup[1], tup[2], tup[3] = str:match(HEX_PTN_6)
            alp = 1
        elseif #str == 9 then
            tup[1], tup[2], tup[3], alp = str:match(HEX_PTN_8)
        end

        for i, t in ipairs(tup) do
            tup[i] = tonumber(#t == 2 and t or t .. t, 16)
        end
        if #str == 5 or #str == 9 then
            alp = tonumber(alp, 16)
        end
        typ = 'rgb'

    -- Color functional notation parsing.
    elseif str:find('rgba?%([%d%s,.%%]+%)') then
        tup, alp = utils.parseColorSpace(str, 'rgb', { 255, 255, 255 })
        typ = 'rgb'

    elseif str:find('hsla?%([%d%s,.%%]+%)') then
        tup, alp = utils.parseColorSpace(str, 'hsl', { 360, .01, .01 })
        typ = 'hsl'

    -- Named color parsing.
    elseif presets[str] then
        local p = presets[str]
        tup = { p[1], p[2], p[3] }
        typ = 'rgb'

    -- Transparent color parsing.
    elseif str == 'transparent' then
        tup = {    0,    0,    0 }
        typ = 'rgb'
        alp = 0

    else error(i18n:msg('unparse', (str or ''))) end

    return Color:new(tup, typ, alp)
end

--- Instance test function for colors.
--  @function           p.instance
--  @param              {Color|string} item Color item or string.
--  @return             {boolean} Whether the color item was instantiated.
--  @usage              colors.instance('#ffffff')
function p.instance(item)
    return tostring(item) == 'Color'
end

--- Color SASS parameter access utility for templating.
--  @function           p.wikia
--  @param              {table} frame Frame invocation object.
--  @error[778]         {string} 'invalid SASS parameter name supplied'
--  @return             {string} Color string aligning with parameter.
--  @usage              {{colors|wikia|key}}
function p.wikia(frame)
    if not frame or not frame.args[1] then
        error(i18n:msg('invalid-param'))
    end

    local key = mw.text.trim(frame.args[1])
    local val = p.params[key]
        and p.params[key]
        or  '<Dev:Colors: ' .. i18n:msg('invalid-param') .. '>'

    return mw.text.trim(val)
end

--- Color parameter parser for inline styling.
--  @function           p.css
--  @param              {table} frame Frame invocation object.
--  @param              {string} frame.args[1] Inline CSS stylesheet.
--  @error[799]         {string} 'no styling supplied'
--  @return             {string} CSS styling with $parameters from
--                      @{colors.params}.
--  @usage              {{colors|css|styling}}
function p.css(frame)
    if not frame.args[1] then
        error(i18n:msg('no-style'))
    end

    local styles = mw.text.trim(frame.args[1])

    local o = styles:gsub('%$([%w-]+)', p.params)

    return o
end

--- Color generator for high-contrast text.
--  @function           p.text
--  @param              {table} frame Frame invocation object.
--  @param              {string} frame.args[1] Color to process.
--  @param[opt]         {string} frame.args[2] Dark color to return.
--  @param[opt]         {string} frame.args[3] Light color to return.
--  @param[opt]         {string} frame.args.lum Whether luminance is used.
--  @error[822]         {string} 'no color supplied'
--  @return             {string} Color string `'#000000'`/$2 or
--                      `'#ffffff'`/$3.
--  @usage              {{colors|text|bg|dark color|light color}}
function p.text(frame)
    if not frame or not frame.args[1] then
        error(i18n:msg('no-color'))
    end

    local str = mw.text.trim(frame.args[1])
    local clr = {
        (mw.text.trim(frame.args[2] or '#000000')),
        (mw.text.trim(frame.args[3] or '#ffffff')),
    }

    local b = yesno(frame.args.lum, false)
        and p.parse(str):luminant()
        or  p.parse(str):bright()

    return b and clr[1] or clr[2]
end

--- SASS color parameter table for Lua modules.
--  These can be accessed elsewhere in the module:
--   * @{colors.wikia} acts as a template getter.
--   * @{colors.css}, @{colors.text} & @{colors.parse} accept
--  `$parameter` syntax.
--  @table              p.params
--  @field              {string} background-dynamic Whether the background is split. Default: `'false'`.
--  @field              {string} background-image Background image URL. Default: `''`.
--  @field              {string} background-image-height Background image height. Default: `0`.
--  @field              {string} background-image-width Background image width. Default: `0`.
--  @field              {string} color-body Background color.
--  @field              {string} color-body-middle Background split color.
--  @field              {string} color-buttons Button color.
--  @field              {string} color-community-header Community header color.
--  @field              {string} color-header Legacy wiki header color.
--  @field              {string} color-links Wiki link color.
--  @field              {string} color-page Page color.
--  @field              {string} color-text Page text color.
--  @field              {string} color-contrast Page contrast color.
--  @field              {string} color-page-border In-page border color.
--  @field              {string} color-button-highlight Button highlight color.
--  @field              {string} color-button-text Button text color.
--  @field              {string} infobox-background Infobox background color.
--  @field              {string} infobox-section-header-background Infobox section header color.
--  @field              {string} color-community-header-text Infobox section header color.
--  @field              {string} dropdown-background-color Dropdown background color.
--  @field              {string} dropdown-menu-highlight Dropdown menu highlight color.
--  @field              {string} is-dark-wiki Whether the wiki has a dark theme (`'true'` or `'false'`).
--  @usage              colors.params['key']
p.params = {
    ['background-dynamic'] = sassParams['background-dynamic'] or 'false',
    ['background-image'] = sassParams['background-image'] or '',
    ['background-image-height'] = sassParams['background-image-height'] or '0',
    ['background-image-width'] = sassParams['background-image-width'] or '0',
    ['color-body'] = sassParams['color-body'] or '#f6f6f6',
    ['color-body-middle'] = sassParams['color-body-middle'] or '#f6f6f6',
    ['color-buttons'] = sassParams['color-buttons'] or '#a7d7f9',
    ['color-community-header'] = sassParams['color-community-header'] or '#f6f6f6',
    ['color-header'] = sassParams['color-header'] or '#f6f6f6',
    ['color-links'] = sassParams['color-links'] or '#0b0080',
    ['color-page'] = sassParams['color-page'] or '#ffffff'
}

-- Theme Designer color variables.

-- Brightness conditionals (post-processing).
local page_bright = p.parse('$color-page'):bright()
local page_bright_90 = p.parse('$color-page'):bright(90)
local header_bright = p.parse('$color-community-header'):bright()
local buttons_bright = p.parse('$color-buttons'):bright()

-- Derived opacity values.
local pi_bg_o = page_bright and 90 or 85

-- Derived colors and variables.

-- Main derived parameters.
p.params['color-text'] = page_bright and '#3a3a3a' or '#d5d4d4'
p.params['color-contrast'] = page_bright and '#000000' or '#ffffff'
p.params['color-page-border'] = page_bright
    and p.parse('$color-page'):mix('#000', 80):string()
    or  p.parse('$color-page'):mix('#fff', 80):string()
p.params['color-button-highlight'] = buttons_bright
    and p.parse('$color-buttons'):mix('#000', 80):string()
    or  p.parse('$color-buttons'):mix('#fff', 80):string()
p.params['color-button-text'] = buttons_bright and '#000000' or '#ffffff'

-- PortableInfobox color parameters.
local is_fandom = mw.site.server:match('%.fandom%.com$')
p.params['infobox-background'] = is_fandom
    and p.parse('$color-page'):mix('$color-links', pi_bg_o):string()
    or  '#f8f9fa'
p.params['infobox-section-header-background'] = is_fandom
    and p.parse('$color-page'):mix('$color-links', 75):string()
    or  '#eaecf0'

-- CommunityHeader color parameters.
p.params['color-community-header-text'] = header_bright
    and '#000000'
    or  '#ffffff'
p.params['dropdown-background-color'] = (function(clr)
    if page_bright_90 then
        return '#ffffff'
    elseif page_bright then
        return clr:mix('#fff', 90):string()
    else
        return clr:mix('#000', 90):string()
    end
end)(p.parse('$color-page'))
p.params['dropdown-menu-highlight'] = p.parse('$color-links'):alpha(10):rgb()

-- Custom SASS parameters.
p.params['is-dark-wiki'] = tostring(not page_bright)

--- Template entrypoint for [[Template:Colors]] access.
--  @function           p.main
--  @param              {table} f Frame object in module (child) context.
--  @return             {string} Module output in template (parent) context.
--  @usage              {{#invoke:colors|main}}
p.main = entrypoint(p)

return p