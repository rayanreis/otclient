ThingCategoryItem = 0
ThingCategoryCreature = 1
ThingCategoryEffect = 2
ThingCategoryMissile = 3
ThingInvalidCategory = 4
ThingExternalTexture = 5
ThingLastCategory = ThingInvalidCategory

ThingAttrGround = 0
ThingAttrGroundBorder = 1
ThingAttrOnBottom = 2
ThingAttrOnTop = 3
ThingAttrContainer = 4
ThingAttrStackable = 5
ThingAttrForceUse = 6
ThingAttrMultiUse = 7
ThingAttrWritable = 8
ThingAttrWritableOnce = 9
ThingAttrFluidContainer = 10
ThingAttrSplash = 11
ThingAttrNotWalkable = 12
ThingAttrNotMoveable = 13
ThingAttrBlockProjectile = 14
ThingAttrNotPathable = 15
ThingAttrPickupable = 16
ThingAttrHangable = 17
ThingAttrHookSouth = 18
ThingAttrHookEast = 19
ThingAttrRotateable = 20
ThingAttrLight = 21
ThingAttrDontHide = 22
ThingAttrTranslucent = 23
ThingAttrDisplacement = 24
ThingAttrElevation = 25
ThingAttrLyingCorpse = 26
ThingAttrAnimateAlways = 27
ThingAttrMinimapColor = 28
ThingAttrLensHelp = 29
ThingAttrFullGround = 30
ThingAttrLook = 31
ThingAttrCloth = 32
ThingAttrMarket = 33
ThingAttrNoMoveAnimation = 253 -- >= 1010, value = 16
ThingAttrChargeable = 254 -- deprecated
ThingLastAttr = 255

SpriteMaskRed = 1
SpriteMaskGreen = 2
SpriteMaskBlue = 3
SpriteMaskYellow = 4

function Thing:isTile()
  return false
end

-- Gold, platinum, and crystal coins convert by using themselves, not "use with".
local GOLD_CONVERSION_IDS = {
  [3031] = true, -- gold coin
  [3035] = true, -- platinum coin
  [3043] = true, -- crystal coin
}

function Thing:isGoldConversionItem()
  return self:isItem() and GOLD_CONVERSION_IDS[self:getId()] or false
end

if not Thing._nativeIsMultiUse then
  Thing._nativeIsMultiUse = Thing.isMultiUse
end

function Thing:isMultiUse()
  if self:isGoldConversionItem() then
    return false
  end
  return Thing._nativeIsMultiUse(self)
end
