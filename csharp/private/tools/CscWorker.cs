using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Resources;
using System.Runtime.Loader;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace RulesCsharp.Tools
{
    public static class CscWorker
    {
        private static MethodInfo? _compilerEntryPoint;
        private static readonly object _compileLock = new object();
        private static readonly object _outputLock = new object();

        public static int Main(string[] args)
        {
            bool persistentWorker = false;
            string? roslynDir = null;
            var passthroughArgs = new List<string>();

            for (int i = 0; i < args.Length; i++)
            {
                if (args[i] == "--persistent_worker")
                {
                    persistentWorker = true;
                }
                else if (args[i].StartsWith("--roslyn-dir="))
                {
                    roslynDir = args[i].Substring("--roslyn-dir=".Length);
                }
                else if (args[i] == "--roslyn-dir" && i + 1 < args.Length)
                {
                    roslynDir = args[++i];
                }
                else
                {
                    passthroughArgs.Add(args[i]);
                }
            }

            InitRoslyn(roslynDir, passthroughArgs);

            if (persistentWorker)
            {
                int requestsHandled = RunWorkerLoop();
                if (requestsHandled == 0 && passthroughArgs.Count > 0)
                {
                    var (exitCode, output) = ExecuteCompilation(passthroughArgs.ToArray());
                    if (!string.IsNullOrEmpty(output))
                    {
                        Console.Error.Write(output);
                    }
                    return exitCode;
                }
                return 0;
            }
            else
            {
                var (exitCode, output) = ExecuteCompilation(passthroughArgs.ToArray());
                if (!string.IsNullOrEmpty(output))
                {
                    Console.Error.Write(output);
                }
                return exitCode;
            }
        }

        private static void InitRoslyn(string? explicitRoslynDir, List<string> args)
        {
            string? roslynDir = explicitRoslynDir;

            if (string.IsNullOrEmpty(roslynDir))
            {
                roslynDir = Environment.GetEnvironmentVariable("ROSLYN_BINCORE_DIR");
            }

            // Look in args for csc.dll
            if (string.IsNullOrEmpty(roslynDir))
            {
                for (int i = 0; i < args.Count; i++)
                {
                    if (args[i].EndsWith("csc.dll", StringComparison.OrdinalIgnoreCase))
                    {
                        roslynDir = Path.GetDirectoryName(args[i]);
                        args.RemoveAt(i);
                        break;
                    }
                }
            }

            // Fallback searches relative to app directory or environment
            if (string.IsNullOrEmpty(roslynDir) || !Directory.Exists(roslynDir))
            {
                string baseDir = AppContext.BaseDirectory;
                string[] candidates = new[]
                {
                    Path.Combine(baseDir, "Roslyn", "bincore"),
                    Path.Combine(baseDir, "..", "Roslyn", "bincore"),
                    Path.Combine(baseDir, "..", "..", "Roslyn", "bincore"),
                };
                foreach (var c in candidates)
                {
                    if (Directory.Exists(c))
                    {
                        roslynDir = c;
                        break;
                    }
                }

                if (string.IsNullOrEmpty(roslynDir) || !Directory.Exists(roslynDir))
                {
                    string sdkDir = Path.Combine(baseDir, "sdk");
                    if (Directory.Exists(sdkDir))
                    {
                        foreach (var s in Directory.GetDirectories(sdkDir))
                        {
                            string r = Path.Combine(s, "Roslyn", "bincore");
                            if (Directory.Exists(r))
                            {
                                roslynDir = r;
                                break;
                            }
                        }
                    }
                }
            }

            if (string.IsNullOrEmpty(roslynDir) || !Directory.Exists(roslynDir))
            {
                throw new InvalidOperationException($"Could not locate Roslyn bincore directory. Checked '{roslynDir}'.");
            }

            string csharpDll = Path.Combine(roslynDir, "Microsoft.CodeAnalysis.CSharp.dll");
            string cscDll = Path.Combine(roslynDir, "csc.dll");

            AssemblyLoadContext.Default.Resolving += (context, assemblyName) =>
            {
                string candidate = Path.Combine(roslynDir, assemblyName.Name + ".dll");
                if (File.Exists(candidate))
                {
                    return context.LoadFromAssemblyPath(candidate);
                }
                return null;
            };

            if (File.Exists(csharpDll))
            {
                AssemblyLoadContext.Default.LoadFromAssemblyPath(csharpDll);
            }

            if (!File.Exists(cscDll))
            {
                throw new FileNotFoundException($"csc.dll not found at '{cscDll}'");
            }

            var cscAssembly = AssemblyLoadContext.Default.LoadFromAssemblyPath(cscDll);
            var programType = cscAssembly.GetType("Microsoft.CodeAnalysis.CSharp.CommandLine.Program")
                              ?? cscAssembly.EntryPoint?.DeclaringType;

            _compilerEntryPoint = programType?.GetMethod("Main", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static)
                                 ?? cscAssembly.EntryPoint;

            if (_compilerEntryPoint == null)
            {
                throw new InvalidOperationException("Could not find compiler entry point in csc.dll");
            }
        }

        private static int RunWorkerLoop()
        {
            var stdin = Console.OpenStandardInput();
            var stdout = Console.OpenStandardOutput();
            int count = 0;

            while (true)
            {
                byte[]? frame = ReadVarintDelimited(stdin);
                if (frame == null)
                {
                    break; // EOF
                }

                count++;
                var request = ParseWorkRequest(frame);
                var (exitCode, output) = ExecuteCompilation(request.Arguments.ToArray());
                SendWorkResponse(stdout, request.RequestId, exitCode, output);
            }

            return count;
        }

        private static (int exitCode, string output) ExecuteCompilation(string[] compileArgs)
        {
            if (_compilerEntryPoint == null)
            {
                return (1, "Compiler entry point not initialized.");
            }

            compileArgs = PreprocessArgs(compileArgs);

            lock (_compileLock)
            {
                var prevOut = Console.Out;
                var prevErr = Console.Error;
                using var sw = new StringWriter();

                try
                {
                    Console.SetOut(sw);
                    Console.SetError(sw);

                    object? result = _compilerEntryPoint.Invoke(null, new object[] { compileArgs });
                    int exitCode = result is int code ? code : 0;
                    return (exitCode, sw.ToString());
                }
                catch (TargetInvocationException tie)
                {
                    return (1, tie.InnerException?.ToString() ?? tie.ToString());
                }
                catch (Exception ex)
                {
                    return (1, ex.ToString());
                }
                finally
                {
                    Console.SetOut(prevOut);
                    Console.SetError(prevErr);
                }
            }
        }

        private static string[] PreprocessArgs(string[] compileArgs)
        {
            var processed = new List<string>(compileArgs.Length);
            foreach (var arg in compileArgs)
            {
                if (arg.StartsWith("-resource:") || arg.StartsWith("/resource:"))
                {
                    string prefix = arg.Substring(0, 10);
                    string spec = arg.Substring(10);
                    string[] parts = spec.Split(',', 2);
                    string resPath = parts[0];
                    string? logicalName = parts.Length > 1 ? parts[1] : null;

                    if (resPath.EndsWith(".resx", StringComparison.OrdinalIgnoreCase) && File.Exists(resPath))
                    {
                        string compiledPath = CompileResx(resPath);
                        if (!string.IsNullOrEmpty(logicalName))
                        {
                            processed.Add($"{prefix}{compiledPath},{logicalName}");
                        }
                        else
                        {
                            processed.Add($"{prefix}{compiledPath}");
                        }
                        continue;
                    }
                }
                processed.Add(arg);
            }
            // csc applies -pathmap to the absolute paths it resolves, so `.` never matches. Map the real execroot or sandbox root.
            processed.Add($"-pathmap:{Directory.GetCurrentDirectory()}=/_/");
            return processed.ToArray();
        }

        private static string CompileResx(string resxPath)
        {
            string outPath = Path.ChangeExtension(resxPath, ".resources");
            try
            {
                var doc = XDocument.Load(resxPath);
                using var stream = File.Create(outPath);
                using var rw = new ResourceWriter(stream);
                foreach (var el in doc.Descendants("data"))
                {
                    string? name = (string?)el.Attribute("name");
                    string? value = (string?)el.Element("value");
                    if (name != null && value != null)
                    {
                        rw.AddResource(name, value);
                    }
                }
                rw.Generate();
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Warning: Failed to compile resx '{resxPath}': {ex.Message}");
            }
            return outPath;
        }

        private class WorkRequest
        {
            public int RequestId { get; set; }
            public List<string> Arguments { get; } = new List<string>();
        }

        private static WorkRequest ParseWorkRequest(byte[] bytes)
        {
            var req = new WorkRequest();
            int pos = 0;

            while (pos < bytes.Length)
            {
                ulong tag = ReadVarint(bytes, ref pos);
                uint fieldNumber = (uint)(tag >> 3);
                uint wireType = (uint)(tag & 0x07);

                if (fieldNumber == 1 && wireType == 2) // arguments (string)
                {
                    ulong len = ReadVarint(bytes, ref pos);
                    string arg = Encoding.UTF8.GetString(bytes, pos, (int)len);
                    pos += (int)len;
                    req.Arguments.Add(arg);
                }
                else if (fieldNumber == 3 && wireType == 0) // request_id (varint)
                {
                    req.RequestId = (int)ReadVarint(bytes, ref pos);
                }
                else if (wireType == 0) // varint
                {
                    ReadVarint(bytes, ref pos);
                }
                else if (wireType == 2) // length-delimited
                {
                    ulong len = ReadVarint(bytes, ref pos);
                    pos += (int)len;
                }
                else if (wireType == 1) // 64-bit
                {
                    pos += 8;
                }
                else if (wireType == 5) // 32-bit
                {
                    pos += 4;
                }
                else
                {
                    break;
                }
            }

            return req;
        }

        private static void SendWorkResponse(Stream stream, int requestId, int exitCode, string output)
        {
            using var ms = new MemoryStream();

            // Field 1: exit_code (wire tag 0x08, varint)
            ms.WriteByte(0x08);
            WriteVarint(ms, (ulong)(uint)exitCode);

            // Field 2: output (wire tag 0x12, length-delimited string)
            if (!string.IsNullOrEmpty(output))
            {
                byte[] outBytes = Encoding.UTF8.GetBytes(output);
                ms.WriteByte(0x12);
                WriteVarint(ms, (ulong)outBytes.Length);
                ms.Write(outBytes, 0, outBytes.Length);
            }

            // Field 3: request_id (wire tag 0x18, varint)
            if (requestId != 0)
            {
                ms.WriteByte(0x18);
                WriteVarint(ms, (ulong)(uint)requestId);
            }

            byte[] payload = ms.ToArray();

            lock (_outputLock)
            {
                WriteVarint(stream, (ulong)payload.Length);
                stream.Write(payload, 0, payload.Length);
                stream.Flush();
            }
        }

        private static byte[]? ReadVarintDelimited(Stream stream)
        {
            int length = 0;
            int shift = 0;

            while (true)
            {
                int b = stream.ReadByte();
                if (b == -1)
                {
                    if (shift == 0) return null;
                    throw new EndOfStreamException("Unexpected EOF while reading varint length");
                }

                length |= (b & 0x7F) << shift;
                if ((b & 0x80) == 0) break;
                shift += 7;
            }

            byte[] buffer = new byte[length];
            int totalRead = 0;
            while (totalRead < length)
            {
                int read = stream.Read(buffer, totalRead, length - totalRead);
                if (read <= 0) throw new EndOfStreamException("Unexpected EOF reading frame data");
                totalRead += read;
            }

            return buffer;
        }

        private static ulong ReadVarint(byte[] bytes, ref int pos)
        {
            ulong result = 0;
            int shift = 0;

            while (pos < bytes.Length)
            {
                byte b = bytes[pos++];
                result |= (ulong)(b & 0x7F) << shift;
                if ((b & 0x80) == 0) break;
                shift += 7;
            }

            return result;
        }

        private static void WriteVarint(Stream stream, ulong value)
        {
            while (value >= 0x80)
            {
                stream.WriteByte((byte)((value & 0x7F) | 0x80));
                value >>= 7;
            }
            stream.WriteByte((byte)value);
        }
    }
}
