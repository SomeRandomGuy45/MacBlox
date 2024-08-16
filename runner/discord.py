import sys
import time
from pypresence import Presence

def print_usage_and_exit():
    print("Usage: python discord_rpc.py <details> <state> <startTimestamp> <AssetIDLarge> <AssetIDSmall> <largeImgText> <smallImageText> <button1label> <button2label> <button1url> <button2url> <pipe_location> <timeend>")
    sys.exit(1)

def parse_arguments():
    if len(sys.argv) < 13:
        print_usage_and_exit()

    args = sys.argv
    details = args[1]
    state = args[2]
    ts_start = int(args[3]) if int(args[3]) > 0 else time.time()
    large_image = args[4]
    small_image = args[5]
    large_text = args[6]
    small_text = args[7]
    label1 = args[8]
    label2 = args[9]
    url1 = args[10]
    url2 = args[11]
    pipe_location = args[12]
    ts_end = int(args[13])

    return (details, state, ts_start, ts_end, large_image, small_image, large_text, small_text, label1, label2, url1, url2, pipe_location)

def main():
    (details, state, ts_start, ts_end, large_image, small_image, large_text, small_text, label1, label2, url1, url2, pipe_location) = parse_arguments()

    client_id = '1267308900420419664'
    rpc = Presence(client_id)
    rpc.connect(pathToFile=pipe_location)

    update_params = {
        "details": details,
        "state": state,
        "start": ts_start,
        "large_image": large_image,
        "large_text": large_text,
        "small_image": small_image,
        "small_text": small_text,
        "buttons": [
            {"label": label1, "url": url1},
            {"label": label2, "url": url2},
        ]
    }

    if ts_end != 0:
        update_params["end"] = ts_end

    rpc.update(**update_params)

    while True:
        time.sleep(0)

if __name__ == "__main__":
    main()