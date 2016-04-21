module Svg
    ( text, node, Svg, Attribute
    , svg, foreignObject
    , circle, ellipse, image, line, path, polygon, polyline, rect, use
    , animate, animateColor, animateMotion, animateTransform, mpath, set
    , desc, metadata, title
    , a, defs, g, marker, mask, missingGlyph, pattern, switch, symbol
    , altGlyph, altGlyphDef, altGlyphItem, glyph, glyphRef, textPath, text'
    , tref, tspan
    , font, fontFace, fontFaceFormat, fontFaceName, fontFaceSrc, fontFaceUri
    , hkern, vkern
    , linearGradient, radialGradient, stop
    , feBlend, feColorMatrix, feComponentTransfer, feComposite
    , feConvolveMatrix, feDiffuseLighting, feDisplacementMap, feFlood, feFuncA
    , feFuncB, feFuncG, feFuncR, feGaussianBlur, feImage, feMerge, feMergeNode
    , feMorphology, feOffset, feSpecularLighting, feTile, feTurbulence
    , feDistantLight, fePointLight, feSpotLight
    , clipPath, colorProfile, cursor, filter, script, style, view
    ) where
{-|

# SVG Nodes
@docs Svg, Attribute, node, text

# HTML Embedding
@docs svg, foreignObject

# Graphics elements
@docs circle, ellipse, image, line, path, polygon, polyline, rect, use

# Animation elements
@docs animate, animateColor, animateMotion, animateTransform, mpath, set

# Descriptive elements
@docs desc, metadata, title

# Containers
@docs a, defs, g, marker, mask, missingGlyph, pattern, switch, symbol

# Text
@docs altGlyph, altGlyphDef, altGlyphItem, glyph, glyphRef, textPath, text',
  tref, tspan

# Fonts
@docs font, fontFace, fontFaceFormat, fontFaceName, fontFaceSrc, fontFaceUri,
  hkern, vkern

# Gradients
@docs linearGradient, radialGradient, stop

# Filters
@docs feBlend, feColorMatrix, feComponentTransfer, feComposite,
  feConvolveMatrix, feDiffuseLighting, feDisplacementMap, feFlood, feFuncA,
  feFuncB, feFuncG, feFuncR, feGaussianBlur, feImage, feMerge, feMergeNode,
  feMorphology, feOffset, feSpecularLighting, feTile, feTurbulence

# Light source elements
@docs feDistantLight, fePointLight, feSpotLight

# Miscellaneous
@docs clipPath, colorProfile, cursor, filter, script, style, view
-}

import Html
import VirtualDom
import Json.Encode as Json



{-| The core building block to create SVG. This library is filled with helper
functions to create these `Svg` values.

This is backed by `VirtualDom.Node` in `evancz/virtual-dom`, but you do not
need to know any details about that to use this library!
-}
type alias Svg = VirtualDom.Node


{-| Set attributes on your `Svg`.
-}
type alias Attribute = VirtualDom.Property


svgNamespace : Attribute
svgNamespace =
  VirtualDom.property "namespace" (Json.string "http://www.w3.org/2000/svg")


{-| Create any SVG node. To create a `<rect>` helper function, you would write:

    rect : List Attribute -> List Svg -> Svg
    rect attributes children =
        node "rect" attributes children

You should always be able to use the helper functions already defined in this
library though!
-}
node : String -> List Attribute -> List Svg -> Svg
node name =
  \attributes children ->
    VirtualDom.node name (svgNamespace :: attributes) children


{-| A simple text node, no tags at all.

Warning: not to be confused with `text'` which produces the SVG `<text>` tag!
-}
text : String -> Svg
text =
  VirtualDom.text


{-| The root `<svg>` node for any SVG scene. This example shows a scene
containing a rounded rectangle:

    import Html
    import Svg exposing (..)
    import Svg.Attributes exposing (..)

    roundRect : Html.Html
    roundRect =
        svg
          [ width "120", height "120", viewBox "0 0 120 120" ]
          [ rect [ x "10", y "10", width "100", height "100", rx "15", ry "15" ] [] ]
-}
svg : List Html.Attribute -> List Svg -> Html.Html
svg =
  node "svg"


{-|-}
foreignObject : List Attribute -> List Html.Html -> Svg
foreignObject =
  node "foreignObject"


-- Animation elements

{-|-}
animate : List Attribute -> List Svg -> Svg
animate =
  node "animate"


{-|-}
animateColor : List Attribute -> List Svg -> Svg
animateColor =
  node "animateColor"


{-|-}
animateMotion : List Attribute -> List Svg -> Svg
animateMotion =
  node "animateMotion"


{-|-}
animateTransform : List Attribute -> List Svg -> Svg
animateTransform =
  node "animateTransform"


{-|-}
mpath : List Attribute -> List Svg -> Svg
mpath =
  node "mpath"


{-|-}
set : List Attribute -> List Svg -> Svg
set =
  node "set"


-- Container elements

{-| The SVG Anchor Element defines a hyperlink.
-}
{-|-}
a : List Attribute -> List Svg -> Svg
a =
  node "a"


{-|-}
defs : List Attribute -> List Svg -> Svg
defs =
  node "defs"


{-|-}
g : List Attribute -> List Svg -> Svg
g =
  node "g"


{-|-}
marker : List Attribute -> List Svg -> Svg
marker =
  node "marker"


{-|-}
mask : List Attribute -> List Svg -> Svg
mask =
  node "mask"


{-|-}
missingGlyph : List Attribute -> List Svg -> Svg
missingGlyph =
  node "missingGlyph"


{-|-}
pattern : List Attribute -> List Svg -> Svg
pattern =
  node "pattern"


{-|-}
switch : List Attribute -> List Svg -> Svg
switch =
  node "switch"


{-|-}
symbol : List Attribute -> List Svg -> Svg
symbol =
  node "symbol"



-- Descriptive elements

{-|-}
desc : List Attribute -> List Svg -> Svg
desc =
  node "desc"


{-|-}
metadata : List Attribute -> List Svg -> Svg
metadata =
  node "metadata"


{-|-}
title : List Attribute -> List Svg -> Svg
title =
  node "title"



-- Filter primitive elements

{-|-}
feBlend : List Attribute -> List Svg -> Svg
feBlend =
  node "feBlend"


{-|-}
feColorMatrix : List Attribute -> List Svg -> Svg
feColorMatrix =
  node "feColorMatrix"


{-|-}
feComponentTransfer : List Attribute -> List Svg -> Svg
feComponentTransfer =
  node "feComponentTransfer"


{-|-}
feComposite : List Attribute -> List Svg -> Svg
feComposite =
  node "feComposite"


{-|-}
feConvolveMatrix : List Attribute -> List Svg -> Svg
feConvolveMatrix =
  node "feConvolveMatrix"


{-|-}
feDiffuseLighting : List Attribute -> List Svg -> Svg
feDiffuseLighting =
  node "feDiffuseLighting"


{-|-}
feDisplacementMap : List Attribute -> List Svg -> Svg
feDisplacementMap =
  node "feDisplacementMap"


{-|-}
feFlood : List Attribute -> List Svg -> Svg
feFlood =
  node "feFlood"


{-|-}
feFuncA : List Attribute -> List Svg -> Svg
feFuncA =
  node "feFuncA"


{-|-}
feFuncB : List Attribute -> List Svg -> Svg
feFuncB =
  node "feFuncB"


{-|-}
feFuncG : List Attribute -> List Svg -> Svg
feFuncG =
  node "feFuncG"


{-|-}
feFuncR : List Attribute -> List Svg -> Svg
feFuncR =
  node "feFuncR"


{-|-}
feGaussianBlur : List Attribute -> List Svg -> Svg
feGaussianBlur =
  node "feGaussianBlur"


{-|-}
feImage : List Attribute -> List Svg -> Svg
feImage =
  node "feImage"


{-|-}
feMerge : List Attribute -> List Svg -> Svg
feMerge =
  node "feMerge"


{-|-}
feMergeNode : List Attribute -> List Svg -> Svg
feMergeNode =
  node "feMergeNode"


{-|-}
feMorphology : List Attribute -> List Svg -> Svg
feMorphology =
  node "feMorphology"


{-|-}
feOffset : List Attribute -> List Svg -> Svg
feOffset =
  node "feOffset"


{-|-}
feSpecularLighting : List Attribute -> List Svg -> Svg
feSpecularLighting =
  node "feSpecularLighting"


{-|-}
feTile : List Attribute -> List Svg -> Svg
feTile =
  node "feTile"


{-|-}
feTurbulence : List Attribute -> List Svg -> Svg
feTurbulence =
  node "feTurbulence"



-- Font elements

{-|-}
font : List Attribute -> List Svg -> Svg
font =
  node "font"


{-|-}
fontFace : List Attribute -> List Svg -> Svg
fontFace =
  node "fontFace"


{-|-}
fontFaceFormat : List Attribute -> List Svg -> Svg
fontFaceFormat =
  node "fontFaceFormat"


{-|-}
fontFaceName : List Attribute -> List Svg -> Svg
fontFaceName =
  node "fontFaceName"


{-|-}
fontFaceSrc : List Attribute -> List Svg -> Svg
fontFaceSrc =
  node "fontFaceSrc"


{-|-}
fontFaceUri : List Attribute -> List Svg -> Svg
fontFaceUri =
  node "fontFaceUri"


{-|-}
hkern : List Attribute -> List Svg -> Svg
hkern =
  node "hkern"


{-|-}
vkern : List Attribute -> List Svg -> Svg
vkern =
  node "vkern"



-- Gradient elements

{-|-}
linearGradient : List Attribute -> List Svg -> Svg
linearGradient =
  node "linearGradient"


{-|-}
radialGradient : List Attribute -> List Svg -> Svg
radialGradient =
  node "radialGradient"


{-|-}
stop : List Attribute -> List Svg -> Svg
stop =
  node "stop"



-- Graphics elements

{-| The circle element is an SVG basic shape, used to create circles based on
a center point and a radius.

  circle [ cx "60", cy "60", r "50" ] []
-}
{-|-}
circle : List Attribute -> List Svg -> Svg
circle =
  node "circle"


{-|-}
ellipse : List Attribute -> List Svg -> Svg
ellipse =
  node "ellipse"


{-|-}
image : List Attribute -> List Svg -> Svg
image =
  node "image"


{-|-}
line : List Attribute -> List Svg -> Svg
line =
  node "line"


{-|-}
path : List Attribute -> List Svg -> Svg
path =
  node "path"


{-|-}
polygon : List Attribute -> List Svg -> Svg
polygon =
  node "polygon"


{-| The polyline element is an SVG basic shape, used to create a series of
straight lines connecting several points. Typically a polyline is used to
create open shapes.

  polyline [ fill "none", stroke "black", points "20,100 40,60 70,80 100,20" ] []
-}
{-|-}
polyline : List Attribute -> List Svg -> Svg
polyline =
  node "polyline"


{-|-}
rect : List Attribute -> List Svg -> Svg
rect =
  node "rect"


{-|-}
use : List Attribute -> List Svg -> Svg
use =
  node "use"



-- Light source elements

{-|-}
feDistantLight : List Attribute -> List Svg -> Svg
feDistantLight =
  node "feDistantLight"


{-|-}
fePointLight : List Attribute -> List Svg -> Svg
fePointLight =
  node "fePointLight"


{-|-}
feSpotLight : List Attribute -> List Svg -> Svg
feSpotLight =
  node "feSpotLight"


-- Text content elements

{-|-}
altGlyph : List Attribute -> List Svg -> Svg
altGlyph =
  node "altGlyph"


{-|-}
altGlyphDef : List Attribute -> List Svg -> Svg
altGlyphDef =
  node "altGlyphDef"


{-|-}
altGlyphItem : List Attribute -> List Svg -> Svg
altGlyphItem =
  node "altGlyphItem"


{-|-}
glyph : List Attribute -> List Svg -> Svg
glyph =
  node "glyph"


{-|-}
glyphRef : List Attribute -> List Svg -> Svg
glyphRef =
  node "glyphRef"


{-|-}
textPath : List Attribute -> List Svg -> Svg
textPath =
  node "textPath"


{-|-}
text' : List Attribute -> List Svg -> Svg
text' =
  node "text"


{-|-}
tref : List Attribute -> List Svg -> Svg
tref =
  node "tref"


{-|-}
tspan : List Attribute -> List Svg -> Svg
tspan =
  node "tspan"


-- Uncategorized elements

{-|-}
clipPath : List Attribute -> List Svg -> Svg
clipPath =
  node "clipPath"


{-|-}
colorProfile : List Attribute -> List Svg -> Svg
colorProfile =
  node "colorProfile"


{-|-}
cursor : List Attribute -> List Svg -> Svg
cursor =
  node "cursor"


{-|-}
filter : List Attribute -> List Svg -> Svg
filter =
  node "filter"


{-|-}
script : List Attribute -> List Svg -> Svg
script =
  node "script"


{-|-}
style : List Attribute -> List Svg -> Svg
style =
  node "style"


{-|-}
view : List Attribute -> List Svg -> Svg
view =
  node "view"


