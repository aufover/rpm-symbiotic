#!/bin/python3
import sys
import re

def parse_input(str):
    state = "start"

    file = ""
    line = ""
    description = ""
    stack = ""
    info = ""

    e_start_re = re.compile('--- Error trace ---')
    e_end_re = re.compile('--- ----------- ---')
    e_file_re = re.compile('File:\s*(\S*)\s*')
    e_line_re = re.compile('Line:\s*(\S*)\s*')
    e_desc_re = re.compile('Error:\s*(.*)\s*')

    e_stack_start_re = re.compile('Stack:\s*')
    e_stack_line_re = re.compile('\s+(.*)\s+in\s+(.*)\s+at\s*(.*)\s*')

    e_info_start_re = re.compile('Info:\s*')
    e_info_line_re = re.compile('\s+(.*)\s*')

    for l in str.splitlines():
        #stack state is not part of the elif chain
        if (state == "stack"):
            if (e_stack_line_re.match(l) != None):
               stack += e_stack_line_re.search(l).group(3) + ": note: call stack: " + e_stack_line_re.search(l).group(2) + "\n"
            #this is the reason for no elif
            else:
               state = "error"
        if (state == "info"):
            if (e_info_line_re.match(l) != None):
               info += l + "\n"
            #this is the reason for no elif
            else:
               state = "error"
        if (state == "start"):
            if (e_start_re.search(l) != None):
                state = "error"
        elif (state == "error"):
            if (e_end_re.search(l) != None):
                state = "start"
                print ("Error: SYMBIOTIC_ERROR:")
                print (file + ":" +line +": error: " + description)
                print(stack, end='')
                #print(info)

                file = ""
                line = ""
                description = ""
                stack = ""
                info = ""
            elif (e_info_start_re.search(l) != None):
                state = "info"
            elif (e_stack_start_re.search(l) != None):
                state = "stack"
            elif (e_file_re.search(l) != None):
                file = e_file_re.search(l).group(1)
            elif (e_desc_re.search(l) != None):
                description = e_desc_re.search(l).group(1)
            elif (e_line_re.search(l) != None):
                line = e_line_re.search(l).group(1)
    return str

if __name__ == "__main__":
    input_str = sys.stdin.read()
    parse_input(input_str)
    sys.exit(0)
