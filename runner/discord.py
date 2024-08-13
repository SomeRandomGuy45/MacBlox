'''

    TODO:
        Refactor this shit. Like holy cow it looks bad

'''
import sys
from pypresence import Presence
import time
args = sys.argv
print(args)
if (len(args) < 11):
    print("Usage: python discord_rpc.py <details> <state> <startTimestamp> <AssetIDLarge> <AssetIDSmall> <largeImgText> <smallImageText> <button1label> <button2label> <button1url> <button2url>")
    sys.exit(1)

state = args[2]
details = args[1]
ts_start=int(args[3])
if ts_start <= 0:
    ts_start = time.time()
large_image=args[4]
large_text=args[6]
small_image=args[5]
small_text=args[7]
label1=args[8]
label2=args[9]
print(args[8],args[9],args[10],args[11])
url1=args[10]
url2=args[11]
client_id = '1267308900420419664'
print(args)
RPC = Presence(client_id)
RPC.connect(
    pathToFile=args[12]
)


RPC.update(
    details=details,
    state=state,
    start=ts_start,
    large_image=large_image,
    large_text=large_text,
    small_image=small_image,
    small_text=small_text,
    buttons=[
        {"label": label1, "url" : url1},
        {"label": label2, "url" : url2},
    ]
)

while True:
    time.sleep(0)