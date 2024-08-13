import discordrpc
import sys

args = sys.argv

if (len(args) < 9):
    print("Usage: python discord_rpc.py <details> <state> <startTimestamp> <endTimestamp> <AssetIDLarge> <AssetIDSmall> <largeImgText> <smallImageText>")
    sys.exit(1)

state = args[2]
details = args[1]
ts_start=int(args[3])
ts_end=int(args[4])
large_image=args[5]
large_text=args[7]
small_image=args[6]
small_text=args[8]
rpc = discordrpc.RPC(app_id=1267308900420419664,debug=True,output=True)
rpc.set_activity(
    state = state,
    details = details,
    ts_start=ts_start,
    ts_end=ts_end,
    large_image=large_image,
    large_text=large_text,
    small_image=small_image,
    small_text=small_text,
)
rpc.run()