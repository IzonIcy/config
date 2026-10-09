#!/bin/sh
# macOS preferences that make the desktop behave like a Linux workstation.
#
# Idempotent: every setting is written to an explicit value, so re-running is
# harmless. Only the preferences that differ from the macOS factory defaults are
# listed here. Anything that already matches the default is intentionally absent.
#
# Run directly, or via `./install.fish --apply-defaults`.

set -eu

changed=0

apply_bool() {
	domain=$1
	key=$2
	value=$3
	label=$4

	# `defaults read` reports booleans as 1/0 while `defaults write -bool` takes
	# true/false, so compare against both spellings. Without this an already
	# correct setting looks like a change and the run reports a false positive.
	current=$(defaults read "$domain" "$key" 2>/dev/null || echo "unset")
	case "$value" in
	true)
		expected_true=true
		expected_false=1
		;;
	*)
		expected_true=false
		expected_false=0
		;;
	esac

	if [ "$current" = "$expected_true" ] || [ "$current" = "$expected_false" ]; then
		printf '  ok    %s\n' "$label"
		return
	fi

	defaults write "$domain" "$key" -bool "$value"
	printf '  set   %s (was %s)\n' "$label" "$current"
	changed=$((changed + 1))
}

echo "Applying macOS defaults"

# Curly quotes and smart dashes silently corrupt pasted shell commands and break
# quoting in a terminal. This is the most common way macOS gets in the way of
# terminal work, so it is the first thing switched off.
echo "Text handling"
apply_bool -g AppleAutomaticQuoteSubstitutionEnabled false "smart quotes off"
apply_bool -g AppleAutomaticDashSubstitutionEnabled false "smart dashes off"
apply_bool -g AppleAutomaticTextReplacementEnabled false "text replacement off"
apply_bool -g AppleAutomaticSpellingCorrectionEnabled false "autocorrect off"

echo "Clock"
apply_bool -g AppleICUForce24HourTime true "24-hour clock"

echo "Finder"
apply_bool com.apple.finder AppleShowAllExtensions true "show all extensions"
apply_bool com.apple.finder ShowPathbar true "show path bar"
apply_bool com.apple.finder ShowStatusBar true "show status bar"

echo "Accessibility"
apply_bool com.apple.universalaccess reduceTransparency true "reduce transparency"
apply_bool com.apple.universalaccess keyboardNavigation true "full keyboard access"

echo "Dock"
apply_bool com.apple.dock autohide true "auto-hide the Dock"

# Finder and the Dock cache their state, so the defaults above do not reach the
# UI until the owning process is restarted. cfprefsd is the daemon behind
# `defaults read`, and a stale cache can report the old value back afterwards.
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

if [ "$changed" -eq 0 ]; then
	echo "Nothing to change, already applied."
else
	echo "Applied $changed change(s)."
fi
