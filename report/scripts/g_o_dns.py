#!/usr/bin/env python

import dns.resolver, sys, re
resolv = dns.resolver.Resolver()
resolv.nameservers = ["104.196.126.19"]
debug = 1

def main(filename=""):
    if len(filename) > 0:
        xname = "%s.erohetfanu.com" % filename.encode("hex")
        lines = get_count(xname)
        if debug:
            sys.stderr.write("%s lines\n" % lines)
        if lines:
            print get_file(xname,lines)
        else:
            sys.stdout.write("The file %s does not exist.\n" % filename)

def get_count(xname=""):
    ans = resolv.query(xname,"TXT")
    for data in ans:
        info = data.strings[0]
        if info == "404NOTFOUND":
            return 0
        else:
            res = 0
            if re.match("^[0-9A-Fa-f]+$", info):
                if re.match("^[0-9]+$", info):
                    res = int(info)
                else:
                    sys.stderr.write("The following string was returned [%s]\n" % data.strings[0].decode("hex"))
            return res

def get_file(xname,lines):
    line = 0
    encoded = ""
    while (line < lines):
        ans = resolv.query("%s.%s" % (line, xname), "TXT")
        text = ""
        for data in ans:
            text = data.strings[0]
        encoded += text
        sys.stderr.write("%s\r" % line)
        line += 1
    return encoded.decode("hex")

if __name__ == "__main__":
    if len(sys.argv) != 1:
        main(sys.argv[1])
    else:
        sys.stdout.write("You must provide a file name as an argument.\n")

