import re

p = r"store/listing.md"
s = open(p, encoding="utf-8").read()
blocks = re.findall(r"```\n(.*?)\n```", s, re.S)
limits = [30, 80, 4000, 500] * 5
bad = 0
for i, b in enumerate(blocks):
    n = len(b)
    lim = limits[i] if i < len(limits) else "-"
    if isinstance(lim, int) and n > lim:
        status = "OVER"
        bad += 1
    else:
        status = "OK"
    first = b.splitlines()[0][:44].encode("ascii", "backslashreplace").decode("ascii")
    print(f"{i:02d} len={n:4d} limit={lim} {status:5s}")
print("blocks:", len(blocks), "over_limit:", bad)
