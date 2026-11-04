using System;
using Google.Protobuf;
using Google.Protobuf.WellKnownTypes;

namespace RulesCsharp.IntegrationTests;

public static class ImportsTest
{
    public static int Main()
    {
        var order = new Shop.Order
        {
            Id = "a1",
            Total = new Shop.Money { Currency = "EUR", Cents = 1250 },
            Placed = Timestamp.FromDateTime(new DateTime(2026, 1, 2, 0, 0, 0, DateTimeKind.Utc)),
        };
        var copy = Shop.Order.Parser.ParseFrom(order.ToByteArray());
        if (copy.Total.Cents != 1250 || copy.Placed.ToDateTime().Day != 2)
        {
            Console.Error.WriteLine($"round trip lost data: {copy}");
            return 1;
        }
        return 0;
    }
}
