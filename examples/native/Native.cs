using System;
using System.Runtime.InteropServices;

Console.WriteLine($"2 + 3 = {Add(2, 3)}");

// Finds libadd.so, libadd.dylib or add.dll next to the app.
[DllImport("add", EntryPoint = "add")]
static extern int Add(int a, int b);
