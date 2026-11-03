"""Checks NuGet packages against the contentHash in packages.lock.json."""

# Every byte value in order. repository_ctx.read returns one char per byte,
# and Starlark has no ord() or chr(), so this table maps between the two.
_BYTES = "\000\001\002\003\004\005\006\007\010\011\012\013\014\015\016\017\020\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037\040\041\042\043\044\045\046\047\050\051\052\053\054\055\056\057\060\061\062\063\064\065\066\067\070\071\072\073\074\075\076\077\100\101\102\103\104\105\106\107\110\111\112\113\114\115\116\117\120\121\122\123\124\125\126\127\130\131\132\133\134\135\136\137\140\141\142\143\144\145\146\147\150\151\152\153\154\155\156\157\160\161\162\163\164\165\166\167\170\171\172\173\174\175\176\177\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277\300\301\302\303\304\305\306\307\310\311\312\313\314\315\316\317\320\321\322\323\324\325\326\327\330\331\332\333\334\335\336\337\340\341\342\343\344\345\346\347\350\351\352\353\354\355\356\357\360\361\362\363\364\365\366\367\370\371\372\373\374\375\376\377"

_ORD = {c: i for i, c in enumerate(_BYTES.elems())}

_SIGNATURE = ".signature.p7s"

def _u16(data, pos):
    return _ORD[data[pos]] | _ORD[data[pos + 1]] << 8

def _u32(data, pos):
    return _u16(data, pos) | _u16(data, pos + 2) << 16

def _le(value, size):
    return "".join([_BYTES[(value >> (8 * i)) & 0xff] for i in range(size)])

def _end_record(data):
    # The end record is the last end signature whose comment length runs
    # exactly to the end of the file. A comment can hold the same 4 bytes.
    pos = len(data)
    for _ in range(len(data)):
        pos = data.rfind("PK\005\006", 0, pos)
        if pos < 0:
            break
        if pos + 22 <= len(data) and pos + 22 + _u16(data, pos + 20) == len(data):
            return pos
    fail("not a zip archive")

def strip_signature(data):
    """Returns the package zip without its signature entry.

    NuGet computes the contentHash of a signed package over the zip with the
    `.signature.p7s` entry removed and the central directory and end record
    fixed up to match (SignedPackageArchiveUtility in NuGet.Client). Every
    package on nuget.org is signed. An unsigned package is returned as is.

    Args:
      data: the .nupkg bytes as returned by repository_ctx.read.

    Returns:
      The bytes whose sha512 is the package's contentHash.
    """
    eocd = _end_record(data)
    count = _u16(data, eocd + 10)
    cd_size = _u32(data, eocd + 12)
    cd_offset = _u32(data, eocd + 16)
    if count == 0xffff or cd_size == 0xffffffff or cd_offset == 0xffffffff:
        fail("zip64 packages are not supported")

    records = []
    pos = cd_offset
    for _ in range(count):
        if data[pos:pos + 4] != "PK\001\002":
            fail("bad central directory record at offset %d" % pos)
        name_len = _u16(data, pos + 28)
        size = 46 + name_len + _u16(data, pos + 30) + _u16(data, pos + 32)
        records.append(struct(
            name = data[pos + 46:pos + 46 + name_len],
            offset = _u32(data, pos + 42),
            raw = data[pos:pos + size],
        ))
        pos += size

    signature = [r for r in records if r.name == _SIGNATURE]
    if not signature:
        return data
    if len(signature) > 1:
        fail("more than one %s entry" % _SIGNATURE)
    start = signature[0].offset

    # The signature's local entry runs up to the next local entry, or up to
    # the central directory when it is the last one.
    end = min([r.offset for r in records if r.offset > start] + [cd_offset])
    removed = end - start

    cd = "".join([
        r.raw if r.offset < start else r.raw[:42] + _le(r.offset - removed, 4) + r.raw[46:]
        for r in records
        if r.name != _SIGNATURE
    ])
    tail = data[eocd:]
    eocd_record = (
        tail[:8] +
        _le(count - 1, 2) +
        _le(count - 1, 2) +
        _le(len(cd), 4) +
        _le(cd_offset - removed, 4) +
        tail[20:]
    )
    return data[:start] + data[end:cd_offset] + cd + eocd_record

_BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

_HEX = "0123456789abcdef"

_URL_SAFE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/:"

def file_url(path):
    """Returns a file:// URL for an absolute path, with each other byte percent-encoded."""
    path = path.replace("\\", "/")
    if not path.startswith("/"):
        # A Windows drive path, C:/feed becomes file:///C:/feed.
        path = "/" + path
    return "file://" + "".join([
        c if c in _URL_SAFE else "%" + _HEX[_ORD[c] >> 4].upper() + _HEX[_ORD[c] & 0xf].upper()
        for c in path.elems()
    ])

def base64_to_hex(value):
    """Returns the lowercase hex form of a base64 value such as a contentHash."""
    bits = 0
    width = 0
    out = []
    for c in value.rstrip("=").elems():
        digit = _BASE64.find(c)
        if digit < 0:
            fail("not base64: " + value)
        bits = bits << 6 | digit
        width += 6
        if width >= 8:
            width -= 8
            byte = bits >> width & 0xff
            out.append(_HEX[byte >> 4] + _HEX[byte & 0xf])
            bits = bits & ((1 << width) - 1)
    return "".join(out)

def build_references(text):
    """Returns the names of the unconditional <Reference> items in an MSBuild props or targets file.

    A package's build/ files can add a dll from build/<tfm>/ as a compile reference.
    MSTest.TestFramework does this for TestFramework.Extensions, which holds TestContext.
    Items under a Condition or a When are left out, since they only apply to opt-in modes.
    """
    for _ in range(len(text)):
        start = text.find("<!--")
        if start < 0:
            break
        end = text.find("-->", start)
        text = text[:start] + (text[end + 3:] if end >= 0 else "")

    names = []
    conditioned = [False]
    for chunk in text.split("<")[1:]:
        tag = chunk.split(">", 1)[0].strip()
        if not tag or tag[0] in "!?":
            continue
        if tag.startswith("/"):
            if len(conditioned) > 1:
                conditioned.pop()
            continue
        element = tag.rstrip("/").replace("\t", " ").replace("\r", " ").replace("\n", " ").split(" ")[0]
        here = conditioned[-1] or "Condition" in tag or element in ("When", "Otherwise")
        if element == "Reference" and not here:
            include = tag.split("Include=", 1)
            if len(include) == 2 and include[1][:1] in ("\"", "'"):
                quote = include[1][0]
                names.append(include[1][1:].split(quote, 1)[0].split(",", 1)[0].strip())
        if not tag.endswith("/"):
            conditioned.append(here)
    return names

def sha512_files(ctx, paths):
    """Returns the lowercase hex sha512 of each file, in order.

    Bazel can only check a hash on bytes it downloads, and a download goes to
    --experimental_remote_downloader when one is set. So hash the files on disk
    with the host tool every supported OS ships: sha512sum (GNU coreutils),
    shasum (macOS) or certutil (Windows).
    """
    if not paths:
        return []
    if ctx.os.name.startswith("windows"):
        hashes = []
        for p in paths:
            result = ctx.execute(["certutil", "-hashfile", str(p), "SHA512"])
            lines = result.stdout.splitlines()
            if result.return_code != 0 or len(lines) < 2:
                fail("certutil -hashfile {} SHA512 failed:\n{}{}".format(p, result.stdout, result.stderr))
            hashes.append(lines[1].replace(" ", "").lower())
        return hashes

    tool = ctx.which("sha512sum")
    cmd = [tool] if tool else [ctx.which("shasum"), "-a", "512"]
    if not cmd[0]:
        fail("hashing NuGet packages needs sha512sum or shasum on PATH")
    result = ctx.execute(cmd + ["--"] + [str(p) for p in paths])
    lines = result.stdout.splitlines()
    if result.return_code != 0 or len(lines) != len(paths):
        fail("{} failed:\n{}{}".format(" ".join([str(c) for c in cmd]), result.stdout, result.stderr))
    return [line.split(" ")[0].lstrip("\\").lower() for line in lines]
