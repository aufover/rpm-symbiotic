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

    cc_info = ""

#7.0.0-dev-llvm-9.0.1-symbiotic:c7cabf85-dg:8fd21926-sbt-slicer:ce747eca-sbt-instrumentation:ff5d8b3f-klee:e773a1f8
#cc: /tmp/foo.c:3:31: error: expected ';' at end of declaration

#RESULT: ERROR (Compiling source '/tmp/foo.c' failed)
#ERROR:  == FAILURE ==
#Compiling source '/tmp/foo.c' failed

    #compilation failure
    e_cc_info_re = re.compile('cc:[ \t](.*)')
    e_error_compile_re = re.compile('RESULT: ERROR \(Compiling source \'(.*)\' failed\)')

    e_start_re = re.compile('--- Error trace ---')
    e_end_re = re.compile('--- ----------- ---')
    e_file_re = re.compile('File:\s*(\S*)\s*')
    e_line_re = re.compile('Line:\s*(\S*)\s*')
    e_desc_re = re.compile('Error:\s*(.*)\s*')

    e_stack_start_re = re.compile('Stack:\s*')
    e_stack_line_re = re.compile('\s+(.*)\s+in\s+(.*)\s+at\s*(.*)\s*')

    e_info_start_re = re.compile('Info:\s*')
    e_info_line_re = re.compile('\s+(.*)\s*')

    e_unknown_re = re.compile('RESULT: unknown \((.*)\)')
    for l in str.splitlines():
        if (e_cc_info_re.match(l) != None):
            cc_info += e_cc_info_re.search(l).group(1)+"\n"
        if (e_error_compile_re.match(l) != None):
            print ("Error: CLANG_WARNING:")
            print (cc_info, end='')
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
            elif (e_unknown_re.search(l) != None):
                e = e_unknown_re.search(l).group(1)
                print ("Error: SYMBIOTIC_WARNING:")
                print ("<unknonwn>: internal warning: " +e)
        elif (state == "error"):
            if (e_end_re.search(l) != None):
                state = "start"
                print ("Error: SYMBIOTIC_WARNING:")
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
