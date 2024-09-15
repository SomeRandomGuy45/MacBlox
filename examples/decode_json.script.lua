local data = decodeJSON(getDataFromURL("https://raw.githubusercontent.com/SomeRandomGuy45/MacBlox/main/installer.json"))
print(data["title"]) -- Make sure 'title' exists and is the correct key