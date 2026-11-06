using System;

static int Add(int a, int b) => checked(a + b);

Console.WriteLine(Add(1, 2));
try
{
    Console.WriteLine(Add(int.MaxValue, 1));
}
catch (OverflowException)
{
    Console.WriteLine("overflow");
}
