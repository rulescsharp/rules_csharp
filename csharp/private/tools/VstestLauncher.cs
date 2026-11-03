using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;

namespace RulesCsharp.Tools
{
    // Runs a library csharp_test under vstest.console: splits the tests across Bazel's shards
    // and turns vstest's TRX report into the JUnit XML that Bazel reads from XML_OUTPUT_FILE.
    // Usage: vstest_launcher <vstest.console.dll> <test dll> <filter or ""> [vstest args...]
    public static class VstestLauncher
    {
        static readonly XNamespace Trx = "http://microsoft.com/schemas/VisualStudio/TeamTest/2010";

        public static int Main(string[] args)
        {
            if (args.Length < 3)
            {
                Console.Error.WriteLine("usage: vstest_launcher <vstest.console.dll> <test dll> <filter> [vstest args...]");
                return 2;
            }
            string vstest = args[0], testDll = args[1], filter = args[2];
            var extra = args.Skip(3).ToList();

            // Telling Bazel we shard has to happen even when this shard ends up with nothing to run.
            string? statusFile = Environment.GetEnvironmentVariable("TEST_SHARD_STATUS_FILE");
            if (!string.IsNullOrEmpty(statusFile))
                File.WriteAllText(statusFile, "");

            string tmp = Environment.GetEnvironmentVariable("TEST_TMPDIR") is { Length: > 0 } t ? t : Path.GetTempPath();
            string work = Path.Combine(tmp, "vstest_launcher_" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(work);
            try
            {
                return Run(vstest, testDll, filter, extra, work);
            }
            finally
            {
                Directory.Delete(work, true);
            }
        }

        static int Run(string vstest, string testDll, string filter, List<string> extra, string work)
        {
            int total = EnvInt("TEST_TOTAL_SHARDS", 1);
            int index = EnvInt("TEST_SHARD_INDEX", 0);
            string? xmlOutput = Environment.GetEnvironmentVariable("XML_OUTPUT_FILE");

            bool requireTests = true;
            if (total > 1)
            {
                var names = List(vstest, testDll, filter, work, out int code);
                if (code != 0)
                    return code;
                // xUnit v2 matches traits only while running, not while listing, so its filtered list
                // comes back empty. Split every test then and let the run apply the filter. No shard
                // sees the others, so a trait filter that matches nothing passes. Drop this once
                // xunit.runner.visualstudio applies traits while listing.
                bool xunit = File.Exists(Path.Combine(Path.GetDirectoryName(Path.GetFullPath(testDll))!, "xunit.runner.visualstudio.testadapter.dll"));
                if (names.Count == 0 && filter.Length > 0 && xunit)
                {
                    names = List(vstest, testDll, "", work, out code);
                    if (code != 0)
                        return code;
                    requireTests = names.Count == 0;
                }
                if (names.Count == 0)
                {
                    Console.Error.WriteLine(filter.Length > 0 ? "No test matches the given testcase filter `" + filter + "`" : "No test is available in " + testDll);
                    return 1;
                }
                var mine = names.Where((_, i) => i % total == index).ToList();
                if (mine.Count == 0)
                {
                    Console.WriteLine("Shard " + index + " of " + total + " has no tests to run.");
                    if (!string.IsNullOrEmpty(xmlOutput))
                        new XDocument(new XElement("testsuites")).Save(xmlOutput);
                    return 0;
                }
                string names_filter = string.Join("|", mine.Select(n => "FullyQualifiedName=" + Escape(n)));
                filter = filter.Length > 0 ? "(" + filter + ")&(" + names_filter + ")" : names_filter;
            }

            // Bazel keeps undeclared outputs, so the TRX report stays around for tools that read it.
            string results = Environment.GetEnvironmentVariable("TEST_UNDECLARED_OUTPUTS_DIR") is { Length: > 0 } u ? u : work;
            string trx = Path.Combine(results, Path.GetFileNameWithoutExtension(testDll) + ".trx");
            var run = new List<string> { vstest, testDll, "--logger:console", "--logger:trx;LogFileName=" + trx, "--ResultsDirectory:" + work };
            if (filter.Length > 0)
                run.Add(Rsp(work, "run.rsp", "--TestCaseFilter:" + filter));
            run.AddRange(extra);
            // vstest exits 0 when it finds no tests, so a missing adapter or a filter that matches nothing would pass.
            run.Add("--");
            run.Add("RunConfiguration.TreatNoTestsAsError=" + (requireTests ? "true" : "false"));
            int exit = Vstest(run);

            // Without a TRX, vstest crashed, so leave test.xml to Bazel, which keeps the log.
            if (!string.IsNullOrEmpty(xmlOutput) && File.Exists(trx))
                ToJUnit(XDocument.Load(trx), Path.GetFileNameWithoutExtension(testDll)).Save(xmlOutput);
            return exit;
        }

        // Data rows and theory cases share a name, so they stay in one shard. Names that differ
        // only by case count once, since vstest matches FullyQualifiedName ignoring case.
        static List<string> List(string vstest, string testDll, string filter, string work, out int code)
        {
            string listFile = Path.Combine(work, "tests.txt");
            File.Delete(listFile);
            var list = new List<string> { vstest, testDll, "--ListFullyQualifiedTests", "--ListTestsTargetPath:" + listFile };
            if (filter.Length > 0)
                list.Add(Rsp(work, "list.rsp", "--TestCaseFilter:" + filter));
            code = Vstest(list);
            if (code != 0 || !File.Exists(listFile))
                return new List<string>();
            return File.ReadAllLines(listFile).Where(n => n.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(n => n, StringComparer.OrdinalIgnoreCase).ThenBy(n => n, StringComparer.Ordinal).ToList();
        }

        static int EnvInt(string name, int fallback) =>
            int.TryParse(Environment.GetEnvironmentVariable(name), out int v) ? v : fallback;

        // A response file keeps a long filter clear of the Windows command line limit. vstest reads
        // \\ as \ and \" as " in it.
        static string Rsp(string work, string name, string line)
        {
            string path = Path.Combine(work, name);
            File.WriteAllText(path, "\"" + line.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"" + Environment.NewLine);
            return "@" + path;
        }

        // vstest filter values escape these characters with a backslash.
        internal static string Escape(string value)
        {
            var sb = new StringBuilder();
            foreach (char c in value)
            {
                if ("\\()&|=!~".IndexOf(c) >= 0)
                    sb.Append('\\');
                sb.Append(c);
            }
            return sb.ToString();
        }

        static int Vstest(List<string> args)
        {
            var psi = new ProcessStartInfo(Environment.ProcessPath!) { UseShellExecute = false };
            psi.ArgumentList.Add("exec");
            foreach (string a in args)
                psi.ArgumentList.Add(a);
            using var p = Process.Start(psi)!;
            p.WaitForExit();
            return p.ExitCode;
        }

        internal static XDocument ToJUnit(XDocument trx, string suiteName)
        {
            var classes = trx.Descendants(Trx + "UnitTest").ToDictionary(
                t => (string?)t.Attribute("id") ?? "",
                t => (string?)t.Element(Trx + "TestMethod")?.Attribute("className") ?? "");
            var suite = new XElement("testsuite", new XAttribute("name", suiteName));
            int tests = 0, failures = 0, skipped = 0;
            double time = 0;
            foreach (var r in trx.Root!.Element(Trx + "Results")?.Elements(Trx + "UnitTestResult") ?? Enumerable.Empty<XElement>())
            {
                double seconds = TimeSpan.TryParse((string?)r.Attribute("duration"), out var d) ? d.TotalSeconds : 0;
                classes.TryGetValue((string?)r.Attribute("testId") ?? "", out string? className);
                var tc = new XElement("testcase",
                    new XAttribute("name", (string?)r.Attribute("testName") ?? ""),
                    new XAttribute("classname", className ?? ""),
                    new XAttribute("time", seconds.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture)));
                var output = r.Element(Trx + "Output");
                var error = output?.Element(Trx + "ErrorInfo");
                switch ((string?)r.Attribute("outcome"))
                {
                    case "Passed":
                        break;
                    case "NotExecuted":
                    case "Inconclusive":
                        skipped++;
                        tc.Add(new XElement("skipped"));
                        break;
                    default:
                        failures++;
                        tc.Add(new XElement("failure",
                            new XAttribute("message", (string?)error?.Element(Trx + "Message") ?? (string?)r.Attribute("outcome") ?? ""),
                            (string?)error?.Element(Trx + "StackTrace") ?? ""));
                        break;
                }
                string? stdout = (string?)output?.Element(Trx + "StdOut");
                if (!string.IsNullOrEmpty(stdout))
                    tc.Add(new XElement("system-out", stdout));
                suite.Add(tc);
                tests++;
                time += seconds;
            }
            suite.Add(new XAttribute("tests", tests), new XAttribute("failures", failures), new XAttribute("errors", 0),
                new XAttribute("skipped", skipped), new XAttribute("time", time.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture)));
            return new XDocument(new XElement("testsuites", suite));
        }
    }
}
