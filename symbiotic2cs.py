#!/bin/python3
import sys
import re

class Error_trace:
    def __init__(self):
        self.file = "<Unknown>"
        self.line = "<Unknown>"
        self.summary = "<Unknown>"
        self.stack = ""
        self.info = ""
        self.nondet_values = ""

    def fix_file(self):
        'Check whether the file is a file from the input package or file from some symbiotic library. If is the laterthis function tries to find a proper file name/line number from the stackinfo'
        'TODO'

    def __str__(self):
        header = ("Error: SYMBIOTIC_WARNING:\n")
        summary = self.file + ":" + self.line + ": " + self.summary +"\n"
        self.fix_file()
        new_stack = ""
        for l in str.splitlines(self.stack):
            new_stack += self.file + ":" + self.line + ": " + l + "\n"
        return header + summary + new_stack

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
               self.current_trace = Error_trace()
               self.current_state = self.state_error_trace


    def _create_state_error_trace(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Error:\s*(.*)\s*", token):
                self.current_trace.summary = re.search("Error:\s*(.*)\s*", token)[1]
            elif re.search("File:\s*(.*)\s*", token):
                self.current_trace.file = re.search("File:\s*(.*)\s*", token)[1]
            elif re.search("Line:\s*(.*)\s*", token):
                self.current_trace.line = re.search("Line:\s*(.*)\s*", token)[1]
            elif re.search("Stack:\s*",token):
                self.current_state = self.state_stack
            elif re.search("Info:\s*",token):
                self.current_state = self.state_info
            elif re.search("--- Sequence of non-deterministic values [function:file:line:col] ---",token):
                self.current_state = self.state_nondet_values

    def _create_state_stack(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Info:\s*",token):
                self.current_state = self.state_info
            elif re.search("--- Sequence of non-deterministic values [function:file:line:col] ---",token):
                self.current_state = self.state_nondet_values
            elif re.search("\s+(.*)\s+in\s+(.*)\s+at\s*(.*)\s*", token):
                m = re.search("\s+(.*)\s+in\s+(.*)\s+at\s*(.*)\s*", token)
                self.current_trace.stack += "note: call stack: function " + m.group(2) + " at: " + m.group(3) + "\n"

    def _create_state_info(self):
        while True:
            token = yield
            if re.search("--- ----------- ---", token):
               self.current_state = self.state_start
               print(self.current_trace)
            elif re.search("Stack:\s*",token):
                self.current_state = self.state_stack
            elif re.search("--- Sequence of non-deterministic values [function:file:line:col] ---",token):
                self.current_state = self.state_nondet_values

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

    def _create_state_trap(self):
        while True:
            token = yield

if __name__ == "__main__":
    symbiotic_return_value = 0
    input_str = sys.stdin.read()
    parser = Parser()
    for l in str.splitlines(input_str):
        parser.send(l)
    sys.exit(symbiotic_return_value)
