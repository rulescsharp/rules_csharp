using System;
using Tests.Integration;

// A friend of ivt_lib, so it compiles against the reference assembly with internals and calls one at run time.
var value = IvtService.Hidden();
if (value != 42)
{
    Console.WriteLine($"FAILED: expected 42, got {value}.");
    return 1;
}

Console.WriteLine("PASSED: a friend named in a different case calls an internal member.");
return 0;
