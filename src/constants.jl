# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Declaration of constants.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# This regex match all the ANSI escape sequences that defines decorations.
const _REGEX_ANSI_SEQUENCES = r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"
