using System;
using System.IO;
using RulesCsharp.Runfiles;
using RunfilesLib;

// The library lives in runfiles_lib and names runfiles_data by its repo_name, mydata.
var path = DataReader.PayloadPath();
if (path == null || File.ReadAllText(path).Trim() != "from-data-module")
{
    Console.WriteLine($"FAILED: runfiles_lib could not read mydata/payload.txt, got {path ?? "null"}");
    return 1;
}

// The main repository has no mydata, so the same path must not resolve from here.
var fromMain = Runfiles.Create().Rlocation("mydata/payload.txt");
if (fromMain != null)
{
    Console.WriteLine($"FAILED: mydata/payload.txt resolved from the main repository to {fromMain}");
    return 1;
}

Console.WriteLine("PASSED: a library in another module resolved its own dependency by repo_name.");
return 0;
