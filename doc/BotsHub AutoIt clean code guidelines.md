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
**Regex:** `;[ \t]*$`

## 6. Avoid magic numbers
Use named constants instead.
**Regex:** `[^a-zA-Z0-9_]([0-9]{2,})`

## 7. Consistent keyword casing
Standardize keywords for readability.
**Regex:** `( |\n|\t)(if|then|elseif|else|endif|func|endfunc|for|next|while|wend|do|until|return|switch|case|endswitch|continueloop|exitloop|select|endselect|true|false|null)( |\n|\t|\()`

## 8. Consistent variable naming
Stick to conventions for variable names.
**Regex:** `((Local|Global|Const)\s+)+\K\$[a-zA-Z_][a-zA-Z0-9_]*`

## 9. Consistent function naming
Use a naming pattern for functions.
**Regex:** `Func[ \t]+\K[a-zA-Z_][a-zA-Z0-9_]*`

## 10. Align line comments properly
Avoid randomly indented comments.
**Regex:** `^[ \t]*;`

## 11. Separate code from comments with tabs
Avoid inline clutter.
**Regex:** `[^\t\n]+;`

## 12. Handle TODOs, FIXMEs, and NOTEs
Resolve them or document properly.
**Regex:** `(?i)\b(TODO|FIXME|NOTE)\b`

## 13. Describe all functions
Every function should be documented.
**Regex Patterns:**
- `\r\n\r\nFunc`
- `^;[^~].*\r\nFunc`
- `^[^;].*\r\nFunc`

## 14. Prefer While/WEnd loops
Avoid `Do/Until` for clarity.
**Regex:** `until`

## 15. Review and clean logging calls
Remove or standardize debug outputs.
**Regex:** `(Out|Debug|Info|Notice|Warn|Error)\(`
