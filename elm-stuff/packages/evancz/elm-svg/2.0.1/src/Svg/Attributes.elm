module Svg.Attributes where
{-|

# Regular attributes
@docs accentHeight, accelerate, accumulate, additive, alphabetic, allowReorder,
  amplitude, arabicForm, ascent, attributeName, attributeType, autoReverse,
  azimuth, baseFrequency, baseProfile, bbox, begin, bias, by, calcMode,
  capHeight, class, clipPathUnits, contentScriptType, contentStyleType, cx, cy,
  d, decelerate, descent, diffuseConstant, divisor, dur, dx, dy, edgeMode,
  elevation, end, exponent, externalResourcesRequired, filterRes, filterUnits,
  format, from, fx, fy, g1, g2, glyphName, glyphRef, gradientTransform,
  gradientUnits, hanging, height, horizAdvX, horizOriginX, horizOriginY, id,
  ideographic, in', in2, intercept, k, k1, k2, k3, k4, kernelMatrix,
  kernelUnitLength, keyPoints, keySplines, keyTimes, lang, lengthAdjust,
  limitingConeAngle, local, markerHeight, markerUnits, markerWidth,
  maskContentUnits, maskUnits, mathematical, max, media, method, min, mode,
  name, numOctaves, offset, operator, order, orient, orientation, origin,
  overlinePosition, overlineThickness, panose1, path, pathLength,
  patternContentUnits, patternTransform, patternUnits, pointOrder, points,
  pointsAtX, pointsAtY, pointsAtZ, preserveAlpha, preserveAspectRatio,
  primitiveUnits, r, radius, refX, refY, renderingIntent, repeatCount,
  repeatDur, requiredExtensions, requiredFeatures, restart, result, rotate,
  rx, ry, scale, seed, slope, spacing, specularConstant, specularExponent,
  speed, spreadMethod, startOffset, stdDeviation, stemh, stemv, stitchTiles,
  strikethroughPosition, strikethroughThickness, string, style, surfaceScale,
  systemLanguage, tableValues, target, targetX, targetY, textLength, title, to,
  transform, type', u1, u2, underlinePosition, underlineThickness, unicode,
  unicodeRange, unitsPerEm, vAlphabetic, vHanging, vIdeographic, vMathematical,
  values, version, vertAdvY, vertOriginX, vertOriginY, viewBox, viewTarget,
  width, widths, x, xHeight, x1, x2, xChannelSelector, xlinkActuate,
  xlinkArcrole, xlinkHref, xlinkRole, xlinkShow, xlinkTitle, xlinkType,
  xmlBase, xmlLang, xmlSpace, y, y1, y2, yChannelSelector, z, zoomAndPan

# Presentation attributes
@docs alignmentBaseline, baselineShift, clipPath, clipRule, clip,
  colorInterpolationFilters, colorInterpolation, colorProfile, colorRendering,
  color, cursor, direction, display, dominantBaseline, enableBackground,
  fillOpacity, fillRule, fill, filter, floodColor, floodOpacity, fontFamily,
  fontSizeAdjust, fontSize, fontStretch, fontStyle, fontVariant, fontWeight,
  glyphOrientationHorizontal, glyphOrientationVertical, imageRendering,
  kerning, letterSpacing, lightingColor, markerEnd, markerMid, markerStart,
  mask, opacity, overflow, pointerEvents, shapeRendering, stopColor,
  stopOpacity, strokeDasharray, strokeDashoffset, strokeLinecap,
  strokeLinejoin, strokeMiterlimit, strokeOpacity, strokeWidth, stroke,
  textAnchor, textDecoration, textRendering, unicodeBidi, visibility,
  wordSpacing, writingMode

-}

import Svg exposing (Attribute)
import VirtualDom exposing (attribute, attributeNS)


-- Regular attributes

{-|-}
accentHeight : String -> Attribute
accentHeight =
  attribute "accent-height"


{-|-}
accelerate : String -> Attribute
accelerate =
  attribute "accelerate"


{-|-}
accumulate : String -> Attribute
accumulate =
  attribute "accumulate"


{-|-}
additive : String -> Attribute
additive =
  attribute "additive"


{-|-}
alphabetic : String -> Attribute
alphabetic =
  attribute "alphabetic"


{-|-}
allowReorder : String -> Attribute
allowReorder =
  attribute "allowReorder"


{-|-}
amplitude : String -> Attribute
amplitude =
  attribute "amplitude"


{-|-}
arabicForm : String -> Attribute
arabicForm =
  attribute "arabic-form"


{-|-}
ascent : String -> Attribute
ascent =
  attribute "ascent"


{-|-}
attributeName : String -> Attribute
attributeName =
  attribute "attributeName"


{-|-}
attributeType : String -> Attribute
attributeType =
  attribute "attributeType"


{-|-}
autoReverse : String -> Attribute
autoReverse =
  attribute "autoReverse"


{-|-}
azimuth : String -> Attribute
azimuth =
  attribute "azimuth"


{-|-}
baseFrequency : String -> Attribute
baseFrequency =
  attribute "baseFrequency"


{-|-}
baseProfile : String -> Attribute
baseProfile =
  attribute "baseProfile"


{-|-}
bbox : String -> Attribute
bbox =
  attribute "bbox"


{-|-}
begin : String -> Attribute
begin =
  attribute "begin"


{-|-}
bias : String -> Attribute
bias =
  attribute "bias"


{-|-}
by : String -> Attribute
by =
  attribute "by"


{-|-}
calcMode : String -> Attribute
calcMode =
  attribute "calcMode"


{-|-}
capHeight : String -> Attribute
capHeight =
  attribute "cap-height"


{-|-}
class : String -> Attribute
class =
  attribute "class"


{-|-}
clipPathUnits : String -> Attribute
clipPathUnits =
  attribute "clipPathUnits"


{-|-}
contentScriptType : String -> Attribute
contentScriptType =
  attribute "contentScriptType"


{-|-}
contentStyleType : String -> Attribute
contentStyleType =
  attribute "contentStyleType"


{-|-}
cx : String -> Attribute
cx =
  attribute "cx"


{-|-}
cy : String -> Attribute
cy =
  attribute "cy"


{-|-}
d : String -> Attribute
d =
  attribute "d"


{-|-}
decelerate : String -> Attribute
decelerate =
  attribute "decelerate"


{-|-}
descent : String -> Attribute
descent =
  attribute "descent"


{-|-}
diffuseConstant : String -> Attribute
diffuseConstant =
  attribute "diffuseConstant"


{-|-}
divisor : String -> Attribute
divisor =
  attribute "divisor"


{-|-}
dur : String -> Attribute
dur =
  attribute "dur"


{-|-}
dx : String -> Attribute
dx =
  attribute "dx"


{-|-}
dy : String -> Attribute
dy =
  attribute "dy"


{-|-}
edgeMode : String -> Attribute
edgeMode =
  attribute "edgeMode"


{-|-}
elevation : String -> Attribute
elevation =
  attribute "elevation"


{-|-}
end : String -> Attribute
end =
  attribute "end"


{-|-}
exponent : String -> Attribute
exponent =
  attribute "exponent"


{-|-}
externalResourcesRequired : String -> Attribute
externalResourcesRequired =
  attribute "externalResourcesRequired"


{-|-}
filterRes : String -> Attribute
filterRes =
  attribute "filterRes"


{-|-}
filterUnits : String -> Attribute
filterUnits =
  attribute "filterUnits"


{-|-}
format : String -> Attribute
format =
  attribute "format"


{-|-}
from : String -> Attribute
from =
  attribute "from"


{-|-}
fx : String -> Attribute
fx =
  attribute "fx"


{-|-}
fy : String -> Attribute
fy =
  attribute "fy"


{-|-}
g1 : String -> Attribute
g1 =
  attribute "g1"


{-|-}
g2 : String -> Attribute
g2 =
  attribute "g2"


{-|-}
glyphName : String -> Attribute
glyphName =
  attribute "glyph-name"


{-|-}
glyphRef : String -> Attribute
glyphRef =
  attribute "glyphRef"


{-|-}
gradientTransform : String -> Attribute
gradientTransform =
  attribute "gradientTransform"


{-|-}
gradientUnits : String -> Attribute
gradientUnits =
  attribute "gradientUnits"


{-|-}
hanging : String -> Attribute
hanging =
  attribute "hanging"


{-|-}
height : String -> Attribute
height =
  attribute "height"


{-|-}
horizAdvX : String -> Attribute
horizAdvX =
  attribute "horiz-adv-x"


{-|-}
horizOriginX : String -> Attribute
horizOriginX =
  attribute "horiz-origin-x"


{-|-}
horizOriginY : String -> Attribute
horizOriginY =
  attribute "horiz-origin-y"


{-|-}
id : String -> Attribute
id =
  attribute "id"


{-|-}
ideographic : String -> Attribute
ideographic =
  attribute "ideographic"


{-|-}
in' : String -> Attribute
in' =
  attribute "in"


{-|-}
in2 : String -> Attribute
in2 =
  attribute "in2"


{-|-}
intercept : String -> Attribute
intercept =
  attribute "intercept"


{-|-}
k : String -> Attribute
k =
  attribute "k"


{-|-}
k1 : String -> Attribute
k1 =
  attribute "k1"


{-|-}
k2 : String -> Attribute
k2 =
  attribute "k2"


{-|-}
k3 : String -> Attribute
k3 =
  attribute "k3"


{-|-}
k4 : String -> Attribute
k4 =
  attribute "k4"


{-|-}
kernelMatrix : String -> Attribute
kernelMatrix =
  attribute "kernelMatrix"


{-|-}
kernelUnitLength : String -> Attribute
kernelUnitLength =
  attribute "kernelUnitLength"


{-|-}
keyPoints : String -> Attribute
keyPoints =
  attribute "keyPoints"


{-|-}
keySplines : String -> Attribute
keySplines =
  attribute "keySplines"


{-|-}
keyTimes : String -> Attribute
keyTimes =
  attribute "keyTimes"


{-|-}
lang : String -> Attribute
lang =
  attribute "lang"


{-|-}
lengthAdjust : String -> Attribute
lengthAdjust =
  attribute "lengthAdjust"


{-|-}
limitingConeAngle : String -> Attribute
limitingConeAngle =
  attribute "limitingConeAngle"


{-|-}
local : String -> Attribute
local =
  attribute "local"


{-|-}
markerHeight : String -> Attribute
markerHeight =
  attribute "markerHeight"


{-|-}
markerUnits : String -> Attribute
markerUnits =
  attribute "markerUnits"


{-|-}
markerWidth : String -> Attribute
markerWidth =
  attribute "markerWidth"


{-|-}
maskContentUnits : String -> Attribute
maskContentUnits =
  attribute "maskContentUnits"


{-|-}
maskUnits : String -> Attribute
maskUnits =
  attribute "maskUnits"


{-|-}
mathematical : String -> Attribute
mathematical =
  attribute "mathematical"


{-|-}
max : String -> Attribute
max =
  attribute "max"


{-|-}
media : String -> Attribute
media =
  attribute "media"


{-|-}
method : String -> Attribute
method =
  attribute "method"


{-|-}
min : String -> Attribute
min =
  attribute "min"


{-|-}
mode : String -> Attribute
mode =
  attribute "mode"


{-|-}
name : String -> Attribute
name =
  attribute "name"


{-|-}
numOctaves : String -> Attribute
numOctaves =
  attribute "numOctaves"


{-|-}
offset : String -> Attribute
offset =
  attribute "offset"


{-|-}
operator : String -> Attribute
operator =
  attribute "operator"


{-|-}
order : String -> Attribute
order =
  attribute "order"


{-|-}
orient : String -> Attribute
orient =
  attribute "orient"


{-|-}
orientation : String -> Attribute
orientation =
  attribute "orientation"


{-|-}
origin : String -> Attribute
origin =
  attribute "origin"


{-|-}
overlinePosition : String -> Attribute
overlinePosition =
  attribute "overline-position"


{-|-}
overlineThickness : String -> Attribute
overlineThickness =
  attribute "overline-thickness"


{-|-}
panose1 : String -> Attribute
panose1 =
  attribute "panose-1"


{-|-}
path : String -> Attribute
path =
  attribute "path"


{-|-}
pathLength : String -> Attribute
pathLength =
  attribute "pathLength"


{-|-}
patternContentUnits : String -> Attribute
patternContentUnits =
  attribute "patternContentUnits"


{-|-}
patternTransform : String -> Attribute
patternTransform =
  attribute "patternTransform"


{-|-}
patternUnits : String -> Attribute
patternUnits =
  attribute "patternUnits"


{-|-}
pointOrder : String -> Attribute
pointOrder =
  attribute "point-order"


{-|-}
points : String -> Attribute
points =
  attribute "points"


{-|-}
pointsAtX : String -> Attribute
pointsAtX =
  attribute "pointsAtX"


{-|-}
pointsAtY : String -> Attribute
pointsAtY =
  attribute "pointsAtY"


{-|-}
pointsAtZ : String -> Attribute
pointsAtZ =
  attribute "pointsAtZ"


{-|-}
preserveAlpha : String -> Attribute
preserveAlpha =
  attribute "preserveAlpha"


{-|-}
preserveAspectRatio : String -> Attribute
preserveAspectRatio =
  attribute "preserveAspectRatio"


{-|-}
primitiveUnits : String -> Attribute
primitiveUnits =
  attribute "primitiveUnits"


{-|-}
r : String -> Attribute
r =
  attribute "r"


{-|-}
radius : String -> Attribute
radius =
  attribute "radius"


{-|-}
refX : String -> Attribute
refX =
  attribute "refX"


{-|-}
refY : String -> Attribute
refY =
  attribute "refY"


{-|-}
renderingIntent : String -> Attribute
renderingIntent =
  attribute "rendering-intent"


{-|-}
repeatCount : String -> Attribute
repeatCount =
  attribute "repeatCount"


{-|-}
repeatDur : String -> Attribute
repeatDur =
  attribute "repeatDur"


{-|-}
requiredExtensions : String -> Attribute
requiredExtensions =
  attribute "requiredExtensions"


{-|-}
requiredFeatures : String -> Attribute
requiredFeatures =
  attribute "requiredFeatures"


{-|-}
restart : String -> Attribute
restart =
  attribute "restart"


{-|-}
result : String -> Attribute
result =
  attribute "result"


{-|-}
rotate : String -> Attribute
rotate =
  attribute "rotate"


{-|-}
rx : String -> Attribute
rx =
  attribute "rx"


{-|-}
ry : String -> Attribute
ry =
  attribute "ry"


{-|-}
scale : String -> Attribute
scale =
  attribute "scale"


{-|-}
seed : String -> Attribute
seed =
  attribute "seed"


{-|-}
slope : String -> Attribute
slope =
  attribute "slope"


{-|-}
spacing : String -> Attribute
spacing =
  attribute "spacing"


{-|-}
specularConstant : String -> Attribute
specularConstant =
  attribute "specularConstant"


{-|-}
specularExponent : String -> Attribute
specularExponent =
  attribute "specularExponent"


{-|-}
speed : String -> Attribute
speed =
  attribute "speed"


{-|-}
spreadMethod : String -> Attribute
spreadMethod =
  attribute "spreadMethod"


{-|-}
startOffset : String -> Attribute
startOffset =
  attribute "startOffset"


{-|-}
stdDeviation : String -> Attribute
stdDeviation =
  attribute "stdDeviation"


{-|-}
stemh : String -> Attribute
stemh =
  attribute "stemh"


{-|-}
stemv : String -> Attribute
stemv =
  attribute "stemv"


{-|-}
stitchTiles : String -> Attribute
stitchTiles =
  attribute "stitchTiles"


{-|-}
strikethroughPosition : String -> Attribute
strikethroughPosition =
  attribute "strikethrough-position"


{-|-}
strikethroughThickness : String -> Attribute
strikethroughThickness =
  attribute "strikethrough-thickness"


{-|-}
string : String -> Attribute
string =
  attribute "string"


{-|-}
style : String -> Attribute
style =
  attribute "style"


{-|-}
surfaceScale : String -> Attribute
surfaceScale =
  attribute "surfaceScale"


{-|-}
systemLanguage : String -> Attribute
systemLanguage =
  attribute "systemLanguage"


{-|-}
tableValues : String -> Attribute
tableValues =
  attribute "tableValues"


{-|-}
target : String -> Attribute
target =
  attribute "target"


{-|-}
targetX : String -> Attribute
targetX =
  attribute "targetX"


{-|-}
targetY : String -> Attribute
targetY =
  attribute "targetY"


{-|-}
textLength : String -> Attribute
textLength =
  attribute "textLength"


{-|-}
title : String -> Attribute
title =
  attribute "title"


{-|-}
to : String -> Attribute
to =
  attribute "to"


{-|-}
transform : String -> Attribute
transform =
  attribute "transform"


{-|-}
type' : String -> Attribute
type' =
  attribute "type"


{-|-}
u1 : String -> Attribute
u1 =
  attribute "u1"


{-|-}
u2 : String -> Attribute
u2 =
  attribute "u2"


{-|-}
underlinePosition : String -> Attribute
underlinePosition =
  attribute "underline-position"


{-|-}
underlineThickness : String -> Attribute
underlineThickness =
  attribute "underline-thickness"


{-|-}
unicode : String -> Attribute
unicode =
  attribute "unicode"


{-|-}
unicodeRange : String -> Attribute
unicodeRange =
  attribute "unicode-range"


{-|-}
unitsPerEm : String -> Attribute
unitsPerEm =
  attribute "units-per-em"


{-|-}
vAlphabetic : String -> Attribute
vAlphabetic =
  attribute "v-alphabetic"


{-|-}
vHanging : String -> Attribute
vHanging =
  attribute "v-hanging"


{-|-}
vIdeographic : String -> Attribute
vIdeographic =
  attribute "v-ideographic"


{-|-}
vMathematical : String -> Attribute
vMathematical =
  attribute "v-mathematical"


{-|-}
values : String -> Attribute
values =
  attribute "values"


{-|-}
version : String -> Attribute
version =
  attribute "version"


{-|-}
vertAdvY : String -> Attribute
vertAdvY =
  attribute "vert-adv-y"


{-|-}
vertOriginX : String -> Attribute
vertOriginX =
  attribute "vert-origin-x"


{-|-}
vertOriginY : String -> Attribute
vertOriginY =
  attribute "vert-origin-y"


{-|-}
viewBox : String -> Attribute
viewBox =
  attribute "viewBox"


{-|-}
viewTarget : String -> Attribute
viewTarget =
  attribute "viewTarget"


{-|-}
width : String -> Attribute
width =
  attribute "width"


{-|-}
widths : String -> Attribute
widths =
  attribute "widths"


{-|-}
x : String -> Attribute
x =
  attribute "x"


{-|-}
xHeight : String -> Attribute
xHeight =
  attribute "x-height"


{-|-}
x1 : String -> Attribute
x1 =
  attribute "x1"


{-|-}
x2 : String -> Attribute
x2 =
  attribute "x2"


{-|-}
xChannelSelector : String -> Attribute
xChannelSelector =
  attribute "xChannelSelector"


{-|-}
xlinkActuate : String -> Attribute
xlinkActuate =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:actuate"


{-|-}
xlinkArcrole : String -> Attribute
xlinkArcrole =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:arcrole"


{-|-}
xlinkHref : String -> Attribute
xlinkHref =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:href"


{-|-}
xlinkRole : String -> Attribute
xlinkRole =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:role"


{-|-}
xlinkShow : String -> Attribute
xlinkShow =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:show"


{-|-}
xlinkTitle : String -> Attribute
xlinkTitle =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:title"


{-|-}
xlinkType : String -> Attribute
xlinkType =
  attributeNS "http://www.w3.org/1999/xlink" "xlink:type"


{-|-}
xmlBase : String -> Attribute
xmlBase =
  attributeNS "http://www.w3.org/XML/1998/namespace" "xml:base"


{-|-}
xmlLang : String -> Attribute
xmlLang =
  attributeNS "http://www.w3.org/XML/1998/namespace" "xml:lang"


{-|-}
xmlSpace : String -> Attribute
xmlSpace =
  attributeNS "http://www.w3.org/XML/1998/namespace" "xml:space"


{-|-}
y : String -> Attribute
y =
  attribute "y"


{-|-}
y1 : String -> Attribute
y1 =
  attribute "y1"


{-|-}
y2 : String -> Attribute
y2 =
  attribute "y2"


{-|-}
yChannelSelector : String -> Attribute
yChannelSelector =
  attribute "yChannelSelector"


{-|-}
z : String -> Attribute
z =
  attribute "z"


{-|-}
zoomAndPan : String -> Attribute
zoomAndPan =
  attribute "zoomAndPan"



-- Presentation attributes

{-|-}
alignmentBaseline : String -> Attribute
alignmentBaseline =
  attribute "alignment-baseline"


{-|-}
baselineShift : String -> Attribute
baselineShift =
  attribute "baseline-shift"


{-|-}
clipPath : String -> Attribute
clipPath =
  attribute "clip-path"


{-|-}
clipRule : String -> Attribute
clipRule =
  attribute "clip-rule"


{-|-}
clip : String -> Attribute
clip =
  attribute "clip"


{-|-}
colorInterpolationFilters : String -> Attribute
colorInterpolationFilters =
  attribute "color-interpolation-filters"


{-|-}
colorInterpolation : String -> Attribute
colorInterpolation =
  attribute "color-interpolation"


{-|-}
colorProfile : String -> Attribute
colorProfile =
  attribute "color-profile"


{-|-}
colorRendering : String -> Attribute
colorRendering =
  attribute "color-rendering"


{-|-}
color : String -> Attribute
color =
  attribute "color"


{-|-}
cursor : String -> Attribute
cursor =
  attribute "cursor"


{-|-}
direction : String -> Attribute
direction =
  attribute "direction"


{-|-}
display : String -> Attribute
display =
  attribute "display"


{-|-}
dominantBaseline : String -> Attribute
dominantBaseline =
  attribute "dominant-baseline"


{-|-}
enableBackground : String -> Attribute
enableBackground =
  attribute "enable-background"


{-|-}
fillOpacity : String -> Attribute
fillOpacity =
  attribute "fill-opacity"


{-|-}
fillRule : String -> Attribute
fillRule =
  attribute "fill-rule"


{-|-}
fill : String -> Attribute
fill =
  attribute "fill"


{-|-}
filter : String -> Attribute
filter =
  attribute "filter"


{-|-}
floodColor : String -> Attribute
floodColor =
  attribute "flood-color"


{-|-}
floodOpacity : String -> Attribute
floodOpacity =
  attribute "flood-opacity"


{-|-}
fontFamily : String -> Attribute
fontFamily =
  attribute "font-family"


{-|-}
fontSizeAdjust : String -> Attribute
fontSizeAdjust =
  attribute "font-size-adjust"


{-|-}
fontSize : String -> Attribute
fontSize =
  attribute "font-size"


{-|-}
fontStretch : String -> Attribute
fontStretch =
  attribute "font-stretch"


{-|-}
fontStyle : String -> Attribute
fontStyle =
  attribute "font-style"


{-|-}
fontVariant : String -> Attribute
fontVariant =
  attribute "font-variant"


{-|-}
fontWeight : String -> Attribute
fontWeight =
  attribute "font-weight"


{-|-}
glyphOrientationHorizontal : String -> Attribute
glyphOrientationHorizontal =
  attribute "glyph-orientation-horizontal"


{-|-}
glyphOrientationVertical : String -> Attribute
glyphOrientationVertical =
  attribute "glyph-orientation-vertical"


{-|-}
imageRendering : String -> Attribute
imageRendering =
  attribute "image-rendering"


{-|-}
kerning : String -> Attribute
kerning =
  attribute "kerning"


{-|-}
letterSpacing : String -> Attribute
letterSpacing =
  attribute "letter-spacing"


{-|-}
lightingColor : String -> Attribute
lightingColor =
  attribute "lighting-color"


{-|-}
markerEnd : String -> Attribute
markerEnd =
  attribute "marker-end"


{-|-}
markerMid : String -> Attribute
markerMid =
  attribute "marker-mid"


{-|-}
markerStart : String -> Attribute
markerStart =
  attribute "marker-start"


{-|-}
mask : String -> Attribute
mask =
  attribute "mask"


{-|-}
opacity : String -> Attribute
opacity =
  attribute "opacity"


{-|-}
overflow : String -> Attribute
overflow =
  attribute "overflow"


{-|-}
pointerEvents : String -> Attribute
pointerEvents =
  attribute "pointer-events"


{-|-}
shapeRendering : String -> Attribute
shapeRendering =
  attribute "shape-rendering"


{-|-}
stopColor : String -> Attribute
stopColor =
  attribute "stop-color"


{-|-}
stopOpacity : String -> Attribute
stopOpacity =
  attribute "stop-opacity"


{-|-}
strokeDasharray : String -> Attribute
strokeDasharray =
  attribute "stroke-dasharray"


{-|-}
strokeDashoffset : String -> Attribute
strokeDashoffset =
  attribute "stroke-dashoffset"


{-|-}
strokeLinecap : String -> Attribute
strokeLinecap =
  attribute "stroke-linecap"


{-|-}
strokeLinejoin : String -> Attribute
strokeLinejoin =
  attribute "stroke-linejoin"


{-|-}
strokeMiterlimit : String -> Attribute
strokeMiterlimit =
  attribute "stroke-miterlimit"


{-|-}
strokeOpacity : String -> Attribute
strokeOpacity =
  attribute "stroke-opacity"


{-|-}
strokeWidth : String -> Attribute
strokeWidth =
  attribute "stroke-width"


{-|-}
stroke : String -> Attribute
stroke =
  attribute "stroke"


{-|-}
textAnchor : String -> Attribute
textAnchor =
  attribute "text-anchor"


{-|-}
textDecoration : String -> Attribute
textDecoration =
  attribute "text-decoration"


{-|-}
textRendering : String -> Attribute
textRendering =
  attribute "text-rendering"


{-|-}
unicodeBidi : String -> Attribute
unicodeBidi =
  attribute "unicode-bidi"


{-|-}
visibility : String -> Attribute
visibility =
  attribute "visibility"


{-|-}
wordSpacing : String -> Attribute
wordSpacing =
  attribute "word-spacing"


{-|-}
writingMode : String -> Attribute
writingMode =
  attribute "writing-mode"

