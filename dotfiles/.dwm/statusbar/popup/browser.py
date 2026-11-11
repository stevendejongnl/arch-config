"""Open work links (Google Meet, Google Calendar, Keito) in the work profile of Chromium, not in the default one."""
import shutil
import subprocess

BROWSER = "chromium"
WORK_PROFILE = "Profile 1"  # "CloudSuite" in chrome://version


def open_work(url):
    if shutil.which(BROWSER):
        cmd = [BROWSER, f"--profile-directory={WORK_PROFILE}", url]
    else:
        cmd = ["xdg-open", url]
    subprocess.Popen(cmd, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
