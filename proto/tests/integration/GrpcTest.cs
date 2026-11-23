using System;
using System.Threading.Tasks;
using Grpc.Core;
using Integration;

namespace RulesCsharp.IntegrationTests;

public static class GrpcTest
{
    private sealed class EchoImpl : EchoService.EchoServiceBase
    {
        public override Task<EchoResponse> Echo(EchoRequest request, ServerCallContext context) =>
            Task.FromResult(new EchoResponse { Message = request.Message });
    }

    // Hands each unary call straight to the service, so the generated client runs without a channel.
    private sealed class LoopbackInvoker(EchoService.EchoServiceBase service) : CallInvoker
    {
        public string? LastMethod;

        public override TResponse BlockingUnaryCall<TRequest, TResponse>(
            Method<TRequest, TResponse> method, string? host, CallOptions options, TRequest request)
        {
            LastMethod = method.FullName;
            return (TResponse)(object)service.Echo((EchoRequest)(object)request, null!).Result;
        }

        public override AsyncUnaryCall<TResponse> AsyncUnaryCall<TRequest, TResponse>(
            Method<TRequest, TResponse> method, string? host, CallOptions options, TRequest request) =>
            throw new NotSupportedException();

        public override AsyncServerStreamingCall<TResponse> AsyncServerStreamingCall<TRequest, TResponse>(
            Method<TRequest, TResponse> method, string? host, CallOptions options, TRequest request) =>
            throw new NotSupportedException();

        public override AsyncClientStreamingCall<TRequest, TResponse> AsyncClientStreamingCall<TRequest, TResponse>(
            Method<TRequest, TResponse> method, string? host, CallOptions options) =>
            throw new NotSupportedException();

        public override AsyncDuplexStreamingCall<TRequest, TResponse> AsyncDuplexStreamingCall<TRequest, TResponse>(
            Method<TRequest, TResponse> method, string? host, CallOptions options) =>
            throw new NotSupportedException();
    }

    public static int Main()
    {
        var invoker = new LoopbackInvoker(new EchoImpl());
        var client = new EchoService.EchoServiceClient(invoker);
        var reply = client.Echo(new EchoRequest { Message = "Hello, gRPC!" });
        if (reply.Message != "Hello, gRPC!" || invoker.LastMethod != "/integration.EchoService/Echo")
        {
            Console.Error.WriteLine($"Unexpected reply {reply.Message} from {invoker.LastMethod}");
            return 1;
        }
        if (EchoService.Descriptor.FullName != "integration.EchoService")
        {
            Console.Error.WriteLine($"Unexpected descriptor {EchoService.Descriptor.FullName}");
            return 1;
        }
        Console.WriteLine($"Echoed {reply.Message} through {invoker.LastMethod}");
        return 0;
    }
}
