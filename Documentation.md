# Introduction #

SpringJumps is a Mobile Substrate-based extension to iPhone/iPod Touch's SpringBoard application launcher that uses special icons to allow a user to quickly jump to any one of SpringBoard's icon pages.

# Usage #

The SpringJumps package (available via Cydia) includes nine shortcut icons, one for each of SpringBoards available pages. Simply tap on an icon to jump to the associated page. Note that it is not possible to jump to a page that does not yet exist.

# Customization #

The SpringJumps package includes a preferences application that allows for the following customizations:

  * Show page titles
> If this is enabled, every page for which a shortcut exists will display a title at the top, above the icons and below the status bar. The title text will be the same as the name of the shortcut for that page.

  * Enable/disable shortcuts
> In the list of shortcuts, setting a given shortcut's toggle switch to "OFF" will cause that icon to be hidden from SpringBoard. This is useful for people who do not wish to use all of the available shortcuts.

  * Change shortcut names
> In the list of shortcuts, tapping on a shortcut's name will display a popup, within which will be a textfield where a new shortcut name can be entered.

Other customization:

  * Change shortcut icons
> For reasons of simplicity, it was decided not to include icon customization in the preferences application. Instead, it is suggested that one use WinterBoard to create a theme for customizing the shortcut icons.

> To make a theme for use with WinterBoard:
    1. Create a directory in WinterBoard's theme path (e.g. /Library/Themes/MySpringJumpsTheme).
    1. Inside the newly-created theme directory, create a directory named "Bundles".
    1. Inside Bundles, create a directory for each shortcut that is to be themed; the names of the directories should be of the form "jp.ashikase.springjumps.`<x>`", where "`<x>`" should be replaced with the shortcut page number (e.g. "jp.ashikase.springjumps.0").
    1. In each shortcut directory, place the PNG file that is to be used for the icon, making sure to name the file "Icon.png".

> The theme should then be selectable in the WinterBoard settings application.

# Questions & Issue Reporting #

Please first take a look at the [Frequently Asked Questions (FAQ)](FAQ.md) page.

All problems should be reported via the [tracker](http://code.google.com/p/iphone-springjumps/issues/list|Issues). Please provide as much information about the problem as possible, including device type, firmware version, and steps to take to recreate the problem.

# Acknowledgements #

  * saurik, for Mobile Substrate and many things iPhone.
  * BigBoss, for hosting the SpringJumps package.
  * WiFone, for suggesting the name "SpringJumps".