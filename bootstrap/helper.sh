#/bin/zsh

PASSWORD=$(osascript -e 'Tell application "System Events" to display dialog "Enter your password:" default answer "" with hidden answer buttons {"OK"} default button "OK"' -e 'text returned of result')
echo "$PASSWORD" | sudo -S rm -rf /Library/Caches/com.apple.iconservices.store