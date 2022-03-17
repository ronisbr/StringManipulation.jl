StringManipulation.jl Changelog
===============================

Version 0.2.1
-------------

- ![Enhancement][badge-enhancement] The performance was improved by removing
  functions that could trigger runtime dispatch.

Version 0.2.0
-------------

- ![Feature][badge-feature] Functions to split strings were added.
- ![Feature][badge-feature] Functions to search patterns given by regexes were
  added.
- ![Feature][badge-feature] A function to concurrently get and remove
  decorations were added to improve performance in some scenarios.
- ![Feature][badge-feature] The function `textview` can be used to create views
  of a text.
- ![Feature][badge-feature] The function `fit_string_in_field` can be used to
  make a string fit in a field, adding continuation character if required.
- ![Feature][badge-feature] The ANSI parsing function now supports true-color
  (24-bit) in scape sequences.
- ![Enhancement][badge-enhancement] Decorations can now be parsed and updated,
  leading to a more clean result by compiling many escape sequences into one.
- ![Enhancement][badge-enhancement] Pre-compilations statements were added to
  highly improve the package performance.
- ![Enhancement][badge-enhancement] Many performance improvements were applied
  to some functions.

Version 0.1.0
-------------

- Initial version.

[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/Deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/Feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/Enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/Bugfix-purple.svg
[badge-info]: https://img.shields.io/badge/Info-gray.svg
