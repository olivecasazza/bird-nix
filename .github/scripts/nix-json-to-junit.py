#!/usr/bin/env python3
"""Convert bird-nix Nix test JSON output to JUnit XML.

Usage:
    nix eval .#tests.json --impure --raw | python3 nix-json-to-junit.py > results.xml

Input JSON shape:
    { "name": str, "total": int, "passed": int, "failed": int, "ok": bool,
      "suites": [{ "name": str, "total": int, "passed": int, "failed": int,
                    "ok": bool, "failureMessages": [str] }] }
"""

import json
import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom


def to_junit(data: dict) -> str:
    testsuites = ET.Element("testsuites")
    testsuites.set("name", data["name"])
    testsuites.set("tests", str(data["total"]))
    testsuites.set("failures", str(data["failed"]))

    for suite in data["suites"]:
        ts = ET.SubElement(testsuites, "testsuite")
        ts.set("name", suite["name"])
        ts.set("tests", str(suite["total"]))
        ts.set("failures", str(suite["failed"]))

        passed_count = suite["passed"]
        failed_msgs = suite.get("failureMessages", [])

        # Emit one <testcase> per passed test
        for i in range(passed_count):
            tc = ET.SubElement(ts, "testcase")
            tc.set("name", f"{suite['name']} #{i + 1}")
            tc.set("classname", suite["name"])

        # Emit one <testcase> per failure with <failure> child
        for i, msg in enumerate(failed_msgs):
            tc = ET.SubElement(ts, "testcase")
            tc.set("name", f"{suite['name']} failure #{i + 1}")
            tc.set("classname", suite["name"])
            failure = ET.SubElement(tc, "failure")
            failure.set("message", msg)
            failure.text = msg

    rough = ET.tostring(testsuites, encoding="unicode", xml_declaration=False)
    dom = minidom.parseString(rough)
    return dom.toprettyxml(indent="  ", encoding=None)


def main():
    data = json.load(sys.stdin)
    print(to_junit(data))


if __name__ == "__main__":
    main()
