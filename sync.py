import sys
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import subprocess
class MyH(FileSystemEventHandler):
    def on_any_event(self, event):
        print("reload")
        subprocess.call(
            ["julia", "-e",  r"""using Pkg; Pkg.develop(path="."); Pkg.rm("DIO"); Pkg.develop(path="."); using DIO; @info :ok"""])

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else '.'
    observer = Observer()
    observer.schedule(MyH(), path, recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()