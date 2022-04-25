UnloadScript( GetScriptName() )


local myfont = draw.CreateFont( "Verdana", 16, 800 )
draw.SetFont(myfont)

local lmaoboxTexture = draw.CreateTexture[[C:\Users\localuser\Desktop\test.png]] -- in %localappdata% folder

callbacks.Register("Draw", "fuckyo", function()
    local w, h = draw.GetScreenSize()
    local tw, th = draw.GetTextureSize( lmaoboxTexture )

    draw.TexturedRect( lmaoboxTexture, w/2 - tw/2, h/2 - th/2, w/2 + tw/2, h/2 + th/2 )
end)


callbacks.Register( 'Unload', function()
    draw.DeleteTexture( lmaoboxTexture )
end )

