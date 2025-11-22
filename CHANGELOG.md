StringManipulation.jl Changelog
===============================

Version 0.4.2
-------------

- ![Feature][badge-feature] The function `parse_ansi_string` can be used to parse a string
  and obtain the text and decorations one must apply to obtain the same result as if the
  string was printed to the terminal.

Version 0.4.1
-------------

- ![Bugfix][badge-bugfix] We fixed the tests against the upcoming Julia 1.12.

Version 0.4.0
-------------

- ![BREAKING][badge-breaking] Rename keyword `keep_ansi` to `keep_escape_seq` in
  `fit_string_in_field`.
- ![BREAKING][badge-breaking] Rename `get_padding_for_string_alignment` to
  `padding_for_string_alignment`.
- ![BREAKING][badge-breaking] Rename `get_crop_to_fit_string_in_field` to
  `crop_width_to_fit_string_in_field`.
- ![Feature][badge-feature] The package now supports italics in the decorations.
- ![Feature][badge-feature] The package now fully supports hyperlinks (OSC 8).
- ![Deprecation][badge-deprecation] Drop support for Julia versions lower than 1.10.

Version 0.3.4
-------------

- ![Bugfix][badge-bugfix] The `textview` was providing a wrong decoration if the visual line
  is in a line that needs cropping to fit the view.

Version 0.3.3
-------------

- ![Enhancement][badge-enhancement] Add `sizehint` to `IOBuffer` to reduce the allocations.
- ![Enhancement][badge-enhancement] The `textview` performance was highly improved. This
  enhancement required to rewrite the highlighting algorithm. Now, it is cleaner and avoids
  writing unnecessary escape sequences, meaning that the output is now different. However,
  we do not consider this a breaking change because the output after applying the decoration
  is precisely the same.

Version 0.3.2
-------------

- ![Bugfix][badge-bugfix] The visual line background was not being applied to the frozen
  columns.

Version 0.3.1
-------------

- ![Feature][badge-feature] The function `replace_default_background` can be used to replace
  the default background in a string.
- ![Feature][badge-feature] `textview` can now have visual lines, which are lines that has a
  different default background.
- ![Enhancement][badge-enhancement] The precompilation is now performed by the package
  **PrecompilationTools.jl**.

Version 0.3.0
-------------

- ![Feature][badge-feature] The function `get_padding_for_string_alignment` can be used to
  return the left and right padding required to align a string in a field.
- ![Feature][badge-feature] The function `get_crop_to_fit_string_in_field` can be used to
  return the number of characters we must crop from a string to fit it in a field.
- ![Feature][badge-feature] The keyword `field_margin` can be used in the function
  `fit_string_in_field` to define an additional margin when cropping is required.
- ![Feature][badge-feature] The function `drop_inactive_properties` can be used to change
  inactive properties in a decoration to unchanged. This function is useful to save printing
  escape sequences when a reset was performed.
- ![Enhancement][badge-enhancement] The performance was improved by including some manual
  precompilations statements.
- ![Bugfix][badge-bugfix] The crop algorithm was improved by avoiding cropping if the string
  has the same size of the field.

Version 0.2.1
-------------

- ![Enhancement][badge-enhancement] The performance was improved by removing functions that
  could trigger runtime dispatch.

Version 0.2.0
-------------

- ![Feature][badge-feature] Functions to split strings were added.
- ![Feature][badge-feature] Functions to search patterns given by regexes were added.
- ![Feature][badge-feature] A function to concurrently get and remove decorations were added
  to improve performance in some scenarios.
- ![Feature][badge-feature] The function `textview` can be used to create views of a text.
- ![Feature][badge-feature] The function `fit_string_in_field` can be used to make a string
  fit in a field, adding continuation character if required.
- ![Feature][badge-feature] The ANSI parsing function now supports true-color (24-bit) in
  escape sequences.
- ![Enhancement][badge-enhancement] Decorations can now be parsed and updated, leading to a
  more clean result by compiling many escape sequences into one.
- ![Enhancement][badge-enhancement] Pre-compilations statements were added to highly improve
  the package performance.
- ![Enhancement][badge-enhancement] Many performance improvements were applied to some
  functions.

Version 0.1.0
-------------

- Initial version.

[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/Deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/Feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/Enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/Bugfix-purple.svg
[badge-info]: https://img.shields.io/badge/Info-gray.svg
