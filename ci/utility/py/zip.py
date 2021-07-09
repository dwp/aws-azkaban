import argparse
import zipfile


def main():
    args = command_line_args()
    with zipfile.ZipFile(args.zipfile, mode='w') as zipped:
        for file in args.files:
            zipped.write(file)


def command_line_args():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('zipfile', help="The zip file to create")
    parser.add_argument('files', help="The files to put in the zip", nargs="+")
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    main()
