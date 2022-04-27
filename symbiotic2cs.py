#!/bin/python3
import os
import sys
import re
import argparse

class Error_trace:
    def __init__(self,argv = "", pr_stack = True, pr_info = True, pr_nondet = True):
        self.file = "<unknown>"
        self.line = "<unknown>"
        self.summary = "<unknown>"
        self.stack = ""
        self.info = ""
        self.nondet_values = ""
        self.argv = argv
        self.print_stack = pr_stack
        self.print_info = pr_info
        self.print_nondet_values = pr_nondet

    def fix_file(self):
        'Check whether the file is a file from the input package or file from some symbiotic library. If is the laterthis function tries to find a proper file name/line number from the stackinfo'
        if self.stack != "":
            for l in str.splitlines(self.stack):
                match = re.search("\s*note: call stack: function (.*) at: (.*):([0123456789]*)\s*",l)
                if match == None:
                    continue
                else:
                    'TODO this regexp might need some further tweaking'
                    if re.search("/opt/symbiotic", match.group(2)):
                        continue
                    else:
                        self.file = match.group(2)
                        self.line = match.group(3)
                        break

    def __str__(self):
        header = ("Error: SYMBIOTIC_WARNING:\n")
        self.fix_file()
        summary = self.file + ":" + self.line + ": error: " + self.summary +"\n"
        new_info = ""
        if self.print_info:
            for l in str.splitlines(self.info):
                new_info += self.file + ":" + self.line + ": " + l + "\n"
        if self.argv != "" :
            new_argv = self.file + ":" + self.line + ": note: argv: " + self.argv + "\n"
        else:
            new_argv = ""
        return header + summary + new_argv + self.stack + new_info + self.nondet_values

class Parser:
    'state transitions:'
    'start -> error_trace'
    'error_trace -> start | stack | info | nondet_values'
    'stack -> start | info | nondet_values'
    'info -> start | stack | nondet_values'
    'nondet_values -> start | stack | info '
    'trap is currently unused, but is supposed to be used in a case of malformated input'
    'error_trace -> start transition also prints the current error_trace to the output'
    'start -> error_trace transitions initializes the current error_trace'

    def __init__(self):
        self.argv = ""
        'create the states of the FSM'
        self.state_start = self._create_state_start()
        self.state_trap = self._create_state_trap()
        self.state_error_trace = self._create_state_error_trace()
        'I will assume that the following three states, might appear in any order or any of them might be missing, but they might not appear outside of the error trace'

        self.state_stack = self._create_state_stack()
        self.state_info = self._create_state_info()
        self.state_nondet_values = self._create_state_nondet_values()

        'Initialize the generators'
        self.state_start.send(None)
        self.state_trap.send(None)
        self.state_error_trace.send(None)
        self.state_stack.send(None)
        self.state_info.send(None)
        self.state_nondet_values.send(None)

        self.current_state = self.state_start

    def send (self, token):
        self.current_state.send(token)

    def _create_state_start(self):
        while True:
            token = yield
            if re.search("--- Error trace ---", token):
               self.current_trace = Error_trace(argv = self.argv)
               self.current_state = self.state_error_trace
            elif re.search ("RESULT: (ERROR|error)\s*(.*)",token):
                m = re.search ("RESULT: (ERROR|error)\s*(.*)",token)
                print ("Error: SYMBIOTIC_WARNING:\n" + "symbiotic: internal error: " + m.group(2) + "\n" + "note: argv: " + self.argv + "\n")
            elif re.search ("\[DBG\] Argv:\s+(.*)",token):
                self.argv = re.search ("\[DBG\] Argv:\s+(.*)",token)[1]

    def _create_state_error_trace(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Error:\s*(.*)\s*", token):
                self.current_trace.summary = re.search("Error:\s*(.*)\s*", token)[1]
            elif re.search("File:\s*(.*)\s*", token):
                self.current_trace.file = os.path.realpath(re.search("File:\s*(.*)\s*", token)[1])
            elif re.search("Line:\s*(.*)\s*", token):
                self.current_trace.line = re.search("Line:\s*(.*)\s*", token)[1]
            elif re.search("Stack:\s*",token):
                self.current_state = self.state_stack
            elif re.search("Info:\s*",token):
                self.current_state = self.state_info
            elif re.search("--- Sequence of non-deterministic values \[function:file:line:col\] ---",token):
                self.current_state = self.state_nondet_values

    def _create_state_stack(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Info:\s*",token):
                self.current_state = self.state_info
            elif re.search("--- Sequence of non-deterministic values \[function:file:line:col\] ---",token):
                self.current_state = self.state_nondet_values
            elif re.search("\s*\[DBG\].*",token):
                'Skip the debug messages'
            elif re.search("\s+(.*)\s+in\s+(.*)\s+at\s*(.*)\s*", token):
                m = re.search("\s+(.*)\s+in\s+(.*)\s+at\s*(.*)\s*", token)
                self.current_trace.stack += os.path.realpath(m.group(3)) + ": " + "note: call stack: function " + m.group(2) + "\n"

    def _create_state_info(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Stack:\s*", token):
                self.current_state = self.state_stack
            elif re.search("--- Sequence of non-deterministic values \[function:file:line:col\] ---", token):
                self.current_state = self.state_nondet_values
            elif re.search("\s*\[DBG\].*",token):
                'Skip the debug messages'
            elif re.search("\s+(.*)", token):
                m = re.search("\s+(.*)", token)
                if not re.search("^\s+$",token):
                    self.current_trace.info += "note: Additional Info: " + m.group(1) + "\n"

    def _create_state_nondet_values(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Stack:\s*",token):
                self.current_state = self.state_stack
            elif re.search("Info:\s*",token):
                self.current_state = self.state_info
            elif re.search("\s*\[DBG\].*",token):
                'Skip the debug messages'
            elif m := re.search("\s*([^:]*):([^:]*):(\d*):(\d*)( \S*)? :=\s*(.*)\s*", token):
                '__VERIFIER_nondet_int:test-0002.c:9:9 := len 4 bytes, [4 times 0x0] (i32: 0)'
                'TODO: map the group(1) to something more user friendly?'
                offset=m.group(5) if m.group(5) is not None else ""
                self.current_trace.nondet_values += os.path.realpath(m.group(2)) + ":" + m.group(3) + ":" + m.group(4) + ": " + "note: Non-deterministic values: " + m.group(1) +  offset + ": " + m.group(6)  + "\n"

    def _create_state_trap(self):
        while True:
            token = yield

if __name__ == "__main__":
    symbiotic_return_value = 0

    argv_parser = argparse.ArgumentParser(description='Convert the symbiotic output to csgrep format.')
    argv_parser.add_argument('input_files', metavar='FILE', nargs='*',  help='input file to be converted')
    args = argv_parser.parse_args()

    #Input is read from the stdin
    if args.input_files == []:
        input_str = sys.stdin.read()
        input_parser = Parser()
        for l in str.splitlines(input_str):
            input_parser.send(l)
    #The input files are part of the argv
    else:
        for f in args.input_files:
            input_str = open(f,"r")
            input_parser = Parser()
            for l in input_str:
                input_parser.send(l)
    sys.exit(symbiotic_return_value)
