import sys
import time
from pypresence import Presence

class DiscordRPC:
    def __init__(self):
        self.client_id = '1267308900420419664'

    def print_usage_and_exit(self):
        print("Usage: python discord_rpc.py <details> <state> <startTimestamp> <AssetIDLarge> <AssetIDSmall> <largeImgText> <smallImageText> <button1label> <button2label> <button1url> <button2url> <pipe_location> <timeend>")
        sys.exit(1)

    def parse_arguments(self):
        if len(sys.argv) < 13:
            self.print_usage_and_exit()

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

    def connect(self, pipe_location):
        self.rpc = Presence(self.client_id)
        self.rpc.connect(pathToFile=pipe_location)

    def update_presence(self, details, state, ts_start, ts_end, large_image, small_image, large_text, small_text, label1, label2, url1, url2):
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

        self.rpc.update(**update_params)

    def run(self):
        (details, state, ts_start, ts_end, large_image, small_image, large_text, small_text, label1, label2, url1, url2, pipe_location) = self.parse_arguments()

        self.connect(pipe_location)
        self.update_presence(details, state, ts_start, ts_end, large_image, small_image, large_text, small_text, label1, label2, url1, url2)

        while True:
            time.sleep(0)

if __name__ == "__main__":
    discord_rpc = DiscordRPC()
    discord_rpc.run()