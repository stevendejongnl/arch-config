import subprocess
import sys


class ArgumentProcessor:
    def __init__(self, arguments):
        self.arguments = arguments

    def process_arguments(self):
        for arg in self.arguments:
            connect_wifi(arg)


def connect_wifi(network_id):
    subprocess.run(["nmcli", "connection", "up", "id", network_id])


def main():
    arguments = sys.argv[1:]
    if arguments:
        processor = ArgumentProcessor(arguments=arguments)
        processor.process_arguments()
        return

    networks: list[str] = [
            "stanja",
            "CloudSuite",
            "Markant",
            "Steven🍟",
            ]

    print("Available wifi networks:")
    for index, network in enumerate(networks):
        print(f"{index + 1}. {network}")

    choice: int = int(input(f"Select the wifi network you want to connect to [1-{len(networks)}]: "))
    try:
        network: str = networks[choice + 1]
    except Exception:
        print("Invalid choice, Please try again.")
        exit(0)

    connect_wifi(network)


if __name__ == "__main__":
    main()
