#!/usr/bin/python3
import os
import sys
import xml.etree.ElementTree as ET


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: cppcheck_review.py <cppcheck_report.xml>")
        sys.exit(2)

    REPORT_FILE = sys.argv[1].strip(" \n\r[]")
    if not os.path.isfile(REPORT_FILE):
        print(f"cppcheck: report file not found: {REPORT_FILE}")
        sys.exit(2)

    print(f"{REPORT_FILE=:}")
    try:
        tree = ET.parse(REPORT_FILE)
    except ET.ParseError as ex:
        print(f"cppcheck: invalid XML report ({ex})")
        sys.exit(2)

    if tree:
        root = tree.getroot()
        errors = root.find("errors")
        issuesCount = 0

        for currentError in errors.iter("error"):
            # NOTE: there is a crash in misra.py. fixed in 2.8+ (b444c00)
            #       misra plugin couldn't handle passing string literal to a function with variadic arguments
            if ("id" not in currentError.attrib) or (currentError.attrib["id"] != "internalError"):
                issuesCount += 1
                ET.dump(currentError)

        if issuesCount > 0:
            print("cppcheck: FOUND ISSUES")
            exit(1)
        else:
            print("cppcheck: no issues found")
