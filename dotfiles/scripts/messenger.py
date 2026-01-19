import subprocess


def find_pid_by_window_class(window_class):
    try:
        wmctrl_process = subprocess.Popen(["wmctrl", "-lpx"], stdout=subprocess.PIPE)
        wmctrl_output = wmctrl_process.communicate()[0].decode()

        for line in wmctrl_output.split("\n"):
            if window_class in line:
                parts = line.split()
                window_id = parts[0]
                pid = get_pid_by_window_id(window_id)
                if pid:
                    return pid

        return None

    except Exception as e:
        print(f"An error occurred: {e}")
        return None


def get_pid_by_window_id(window_id):
    try:
        xprop_process = subprocess.Popen(["xprop", "-id", window_id, "_NET_WM_PID"], stdout=subprocess.PIPE)
        xprop_output = xprop_process.communicate()[0].decode()
        pid = xprop_output.split('=')[1].strip()
        return pid

    except Exception as e:
        print(f"An error occurred while getting PID for window ID {window_id}: {e}")
        return None


def kill_process_by_pid(pid):
    try:
        subprocess.run(["kill", "-9", pid])
        print(f"Killed process with PID: {pid}")
    except Exception as e:
        print(f"An error occurred while killing process with PID {pid}: {e}")


def start_messenger(messenger: str) -> None:
    try:
        if messenger == "google-chat-linux":
            subprocess.Popen(["google-chat-linux"])

        elif messenger == "whatsapp-nativefier-d40211":
            subprocess.Popen(["whatsapp-nativefier"])

        elif messenger == "slack":
            subprocess.Popen(["slack"])

        else:
            print(f"No command specified for messenger '{messenger}'")

    except Exception as e:
        print(f"An error occurred while starting process for messenger '{messenger}': {e}")


def reset_messengers(messengers: list[str] = []) -> None:
    for messenger in messengers:
        pid = find_pid_by_window_class(messenger)
        if pid:
            print(f"PID found for window class '{messenger}': {pid}")
            kill_process_by_pid(pid=pid)
        else:
            print(f"No PID found for window class '{messenger}'")

        start_messenger(messenger=messenger)


if __name__ == "__main__":
    messengers: list[str] = [
            "google-chat-linux",
            "whatsapp-nativefier-d40211",
            "slack",
            ]
    reset_messengers(messengers=messengers)
