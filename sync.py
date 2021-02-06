import sys
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import subprocess
from threading import Lock
e_lock = Lock()
events = [0]

def run_build():
    subprocess.call(
        ["julia", "-e",  r"""using Pkg; Pkg.develop(path="."); Pkg.rm("DIO"); Pkg.develop(path="."); using DIO; @info :ok"""])

class MyH(FileSystemEventHandler):
    def on_any_event(self, event):
        with e_lock:
            events[0] += 1
            print("modified")
        
if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else '.'
    observer = Observer()
    observer.schedule(MyH(), path, recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(1)
            with e_lock:
                if events[0]:
                    run_build()
                events[0] = 0
    except KeyboardInterrupt:
        observer.stop()
    observer.join()