flag.set_flag("isDebug", true)
flag.set_flag("allowDownload", false)

print(getDataFromURL("https://raw.githubusercontent.com/SomeRandomGuy45/MacBlox/main/installer.json")) --prints Downloading Disabled

function loop_Table(arg1)
    for i, v in next, arg1 do
        print(i, v)
        if (type(v) == "table") then
            loop_Table(v)
        end
    end
end

for i, v in next, flag.list_flags() do
    print(i, v)
    if (type(v) == "table") then
        loop_Table(v)
    end
end