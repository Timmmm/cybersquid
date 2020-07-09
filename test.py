#!/usr/bin/env python3

import subprocess
import os

def run_test(file):
    os.makedirs("build", exist_ok=True)

    subprocess.run(["iverilog", "-o", "build/out.vvp", "-I", "source", file], check=True)
    subprocess.run(["vvp", "build/out.vvp"], check=True)
    # subprocess.run(["gtkwave", "build/out.vvp"], check=True)


#run_test("tests/CommandReceiver_TB.v")
#run_test("tests/UARTTransmitter_TB.v")
#run_test("tests/UARTReceiver_TB.v")
#run_test("tests/ClockDivider_TB.v")
#run_test("tests/DataTransmitter_TB.v")
#run_test("tests/SampleRecorder_TB.v")
#run_test("tests/MetadataTransmitter_TB.v")
run_test("tests/Core_TB.v")
