using System;
using Tests.Integration;

// Not a friend of ivt_lib, so it compiles against the public reference assembly. It still has to load ivt_lib at run time.
var value = IvtService.Compute();
if (value != 42)
{
    Console.WriteLine($"FAILED: expected 42, got {value}.");
    return 1;
}

Console.WriteLine("PASSED: a non-friend dependent loads a library with internals_visible_to.");
return 0;
