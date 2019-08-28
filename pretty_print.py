#!/bin/python3

import subprocess
import sys


def parse_output(output):
    result, path, file, line, error, function = "", "", "", 0, "", ""
    lines = output.split('\n')

    for i in range(len(lines)):
        if lines[i].startswith("RESULT: "):
            result = lines[i][8:]
        elif lines[i].startswith("Error: "):
            error = lines[i][7:]
        elif lines[i].startswith("File: "):
            path = lines[i][6:]
            file = path.split('/')[-1]
        elif lines[i].startswith("Line: "):
            line = int(lines[i][6:])
        elif lines[i].startswith("Stack: "):
            function = lines[i+1].split()[2]
        else:
            pass

    return result, path, file, line, error, function


def bold(string):
    return '\033[1m' + string + '\033[0m'
def red(string):
    return '\033[91m' + string + '\033[0m'
def green(string):
    return '\033[92m' + string + '\033[0m'
def yellow(string):
    return '\033[93m' + string + '\033[0m'


def print_result(result, file, line, error, source, function, output):
    if result.startswith("true"):
        print(bold("symbiotic:"), green(result))

    elif result.startswith("false"):
        print(bold(file) + ": In function " + bold("'" + function + "'") + ":")
        print(bold(file + ":" + str(line) + ": ") + red("error: ") + error)
        print("    %d | %s" % (line, source.rstrip()))

    elif result.startswith("unknown"):
        print(bold("symbiotic:"), yellow(result))

    elif result.startswith("ERROR"):
        print(bold("symbiotic:"), red(result))

    elif result.startswith("timeout"):
        print(bold("symbiotic:"), yellow("timeout"))

    else:
        print(output)


def main():
    output = subprocess.run("sh /opt/symbiotic/bin/symbiotic",
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            universal_newlines=True
                            ).stdout

    result, path, file, line, error, function = parse_output(output)
    source = ""
    if path:
        with open(path, "r") as f:
            for i, code in enumerate(f):
                if i == line - 1:
                    source = code
                    break

    print_result(result, file, line, error, source, function, output)


if __name__ == '__main__':
    main()
