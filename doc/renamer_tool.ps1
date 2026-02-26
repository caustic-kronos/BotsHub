param(
	[string]$rootPath = ".",
	[string[]]$extensions = @("*.au3")
)

Write-Host "RootPath:" (Resolve-Path $rootPath)
Write-Host "Extensions:" ($extensions -join ", ")
Write-Host ""

# 1. Collect all target files
$files = Get-ChildItem -Path $rootPath -Recurse -Include $extensions -File -ErrorAction Stop

Write-Host "Files found:" $files.Count
foreach ($f in $files) {
	Write-Host "	-" $f.FullName
}
Write-Host ""

# 2. Extract Global Const variables
$constMap = @{}
$constRegex = '^\s*Global\s+Const\s+\$(\w+)'

foreach ($file in $files) {
	Write-Host "Scanning:" $file.FullName
	$lineNumber = 0
	foreach ($line in Get-Content $file.FullName) {
		$lineNumber++
		if ($line -match $constRegex) {
			$name = $matches[1]
			$upper = $name.ToUpper()

			Write-Host "	Found Global Const at line $lineNumber -> `$${name}"

			if ($name -cne $upper) {
				$constMap[$name] = $upper
			}
		}
	}
}

Write-Host ""
Write-Host "Constants collected:" $constMap.Count
foreach ($k in $constMap.Keys) {
	Write-Host "	$k -> $($constMap[$k])"
}

if ($constMap.Count -eq 0) {
	Write-Host ""
	Write-Host "No Global Const variables found. Aborting."
	return
}

Write-Host ""
Write-Host "Starting replacements..."
Write-Host ""

# 3. Replace declarations and usages
foreach ($file in $files) {
	Write-Host "Processing file:" $file.FullName
	$text = Get-Content $file.FullName -Raw
	$original = $text
	$changes = 0

	foreach ($entry in $constMap.GetEnumerator()) {
		$oldPattern = '\$' + [regex]::Escape($entry.Key) + '\b'
		$newText = '$' + $entry.Value

		# Perform replacement
		$before = $text
		$text = [regex]::Replace($text, $oldPattern, $newText)
		if ($text -cne $before) {
			$changes++
			# Count actual matches
			$matchCount = ([regex]::Matches($before, $oldPattern)).Count
			Write-Host "	Replaced $matchCount occurrence(s) in this file"
		}
	}

	if ($text -cne $original) {
		Set-Content $file.FullName $text -NoNewline
		Write-Host "	File updated ($changes replacement(s))"
	} else {
		Write-Host "	No changes made"
	}
	Write-Host ""
}

Write-Host "All files processed."