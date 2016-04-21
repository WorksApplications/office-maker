# Material Icons for Elm

This library offers access to all of [Google's Material icons](https://www.google.com/design/icons/) in elm-svg.

All icons functions expect a color and a size, which is used as both the width and the height of the icon.

*Note: The icons are grouped in submodules mirroring the grouping of the icons by the material design folks [in this page](https://www.google.com/design/icons/).*

So, if you want to use some icons, first go to the [google design icons page](https://www.google.com/design/icons/), find the icons you want to use, then search them in this package. Finding them is very simple as naming is respected and spaces are changed to underscores.

For example :

`account balance` in the Action category can be imported as

```elm
import Material.Icons.Action exposing (account_balance)
```
