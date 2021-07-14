import argparse
import sys

from azkaban_service import AzkabanService, AzkabanException


def main():
    try:
        azkaban = azkaban_service(command_line_arguments())
        executing = azkaban.currently_running()
        for project, flows in executing.items():
            for flow, execution_ids in flows.items():
                for execution_id in execution_ids:
                    print(f"{project},{flow},{execution_id}")
    except AzkabanException as e:
        sys.stderr.write(e.message)
        raise e


def azkaban_service(arguments):
    return AzkabanService(arguments.azkaban_url, session_id=arguments.session_id) if arguments.session_id else \
        AzkabanService(arguments.azkaban_url, username=arguments.user_name, password=arguments.password)


def command_line_arguments():
    parser = argparse.ArgumentParser(description="Show jobs running on azkaban")
    parser.add_argument("--user-name", help="The azkaban user's name.")
    parser.add_argument("--password", help="The azkaban user's password.")
    parser.add_argument("--session-id",
                        help="An azkaban session id which can be provided instead of a username and password.")
    parser.add_argument("azkaban_url")
    return parser.parse_args()


if __name__ == "__main__":
    main()
