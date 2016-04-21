# elm-svg

Use SVG in Elm.

This is based on the [virtual-dom][] approach used by [elm-html][]. You can
read more about the performance improvements this gives you
[here](http://elm-lang.org/blog/Blazing-Fast-Html.elm)

[virtual-dom]: http://package.elm-lang.org/packages/evancz/virtual-dom/latest
[elm-html]: http://package.elm-lang.org/packages/evancz/elm-html/latest

This library also aims to be the most basic API. In some cases it is possible
to use [union types](http://elm-lang.org/learn/Union-Types.elm) to build nicer
abstractions, but this starts bringing personal taste into things and has some
additional maintainance cost if the underlying spec changes. I think it is
best to build such abstractions on top of this library as a separate package.