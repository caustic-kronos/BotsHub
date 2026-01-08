# 🧼 BotsHub AutoIt clean code guidelines – *The 15 Laws*

## 1. Use single quotes (unless escaping required)
Prevents confusion with escape characters.
**Regex:** `"`

## 2. Use tabulations for indentation only
No spaces for alignment.
**Regex:** `^ +`

## 3. Trim trailing whitespace
Avoid tabs/spaces at the end of lines.
**Regex:** `[ \t]+$`

## 4. Don’t mix tabs and spaces
Maintain consistent layout across editors.
**Regex:** `( +\t)|(\t +)`

## 5. No stray semicolons at end of lines
Don’t leave useless `;` behind.
**Regex:** `^.+;[ \t]*$`

## 6. Consistent keyword casing
Standardize keywords for readability.
**Regex:** `( |\n|\t)(if|then|elseif|else|endif|func|endfunc|for|next|while|wend|do|until|return|switch|case|endswitch|continueloop|exitloop|select|endselect|true|false|null)( |\n|\t|\()`

## 7. Consistent variable naming
Stick to conventions for variable names.
**Regex:** `((Local|Global|Const)\s+)+\$[a-zA-Z_][a-zA-Z0-9_]*`

## 8. Consistent function naming
Use a naming pattern for functions.
**Regex:** `Func[ \t]+[a-zA-Z_][a-zA-Z0-9_]*`

## 9. No inline comments
Inline comments are clutter. Comment on top of code.
**Regex:** `^.*[a-zA-Z]+.*;`

## 10. Handle TODOs, FIXMEs, and NOTEs
Resolve them or document properly.
**Regex:** `\b(TODO|FIXME|NOTE)\b`

## 11. Prefer While/WEnd loops
Avoid `Do/Until` for clarity.
**Regex:** `until`

## 12. Review and clean logging calls
Remove or standardize debug outputs.
**Regex:** `(Out|Debug|Info|Notice|Warn|Error)\(`

## 13. Avoid magic numbers
Use named constants instead.

## 14. Document all functions
Every function should be documented.

## 15. Align comments properly
Avoid randomly indented comments.

## 16. Separate code from inline comments with tabs
Avoid inline comments. If it does make sense, then separate with tabs.