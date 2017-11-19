xdt99-wrapper: Wrapper Classes for xdt99
========================================

The **[xdt99 Wrapper Classes][2]** (xdt99-wrapper) contains actually a collection of Objective-C classes that wraps all necessary Python classes of the [TI 99 Cross-Development Tools][5] project (xdt99) to make them available for native Objective-C software development under the Cocoa framework.   
In future there can be make additionally wrapper for Swift, C/C++ or other programming languages.

These Objective-C classes will be released bundled together with the necessary xdt99 Python scripts (xas99, xbas99 and xga99) as a library for easy to use and easy integrating into native Cocoa applications for your Mac under macOS 10.8 and later. You just have to add the XDTools99.framework to your XCode project.   
This wrapper collection additionally contains a XCode project for an simple sample application (named SimpleXDT99IDE) that will show you how to use the wrapper library.

The complete source of the xdt99-wrapper and its sample App is available on [GitHub][2] and is released under the [GNU Lesser General Public License, Version 2.1][1] (GNU LGPLv2.1).


Download and Installation
-------------------------

Clone the entire xdt99-wrapper GitHub [repository][2] and checkout [tag 'v0.4'][3] on the master branch. To open the project files of XDTools99 and SimpleXDT99IDE, you will need to install XCode 8 from Apples AppStore before.  
To run the sample application off the XCode environment and to build a binary release, you will also need to checkout the [xdt99 repository][5]. This can be done by opening the corresponding git submodule. If you want to use the HEAD of the branch (instead any of the tags), another submodule is also necessary for a successful build: My custom branch of [NoodleKit][8] (which is forked from [MrNoodle][9]) provides a NoodleLineNumberView class for using line numbering in the source code editor.

The wrapper classes of the library (and so the sample IDE) are tested and based with
* version 1.7.0 of xas99,
* version 1.5.0 of xbas99 and
* version 1.7.0 of xga99

which are all part of the [release 1.7.0][6] of xdt99. Later versions of that tools may not be compatible when the API of the Python scripts changes.


Contact Information
-------------------

The xdt99-warpper classes are released under the GNU LGPLv2.1, in the hope that Mac and TI 99
enthusiasts may find them useful.

Please report feedback and all bugs to the [developer][7] by [creating][4] an issue at GitHub.

[1]: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
[2]: https://github.com/endlos99/xdt99-wrapper
[3]: https://github.com/endlos99/xdt99-wrapper/tree/v0.4
[4]: https://github.com/endlos99/xdt99-wrapper/issues
[5]: https://github.com/endlos99/xdt99
[6]: https://github.com/endlos99/xdt99/releases/tag/1.7.0
[7]: https://github.com/henrik-w
[8]: https://github.com/henrik-w/NoodleKit
[9]: https://github.com/MrNoodle/NoodleKit
