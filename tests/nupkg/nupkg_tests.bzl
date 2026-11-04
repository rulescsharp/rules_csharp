"""Unit tests for the NuGet package helpers."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//csharp/private:nupkg.bzl", "base64_to_hex", "build_references", "file_url", "strip_signature")

# Stored zips written by Python's zipfile. UNSIGNED holds lib/a.txt and
# lib/b.txt. The signed ones add a .signature.p7s entry after or between them,
# the way NuGet signs a package.
_UNSIGNED = "\120\113\003\004\024\000\000\000\000\000\000\000\041\120\152\071\340\320\005\000\000\000\005\000\000\000\011\000\000\000\154\151\142\057\141\056\164\170\164\141\154\160\150\141\120\113\003\004\024\000\000\000\000\000\000\000\041\120\211\270\233\011\005\000\000\000\005\000\000\000\011\000\000\000\154\151\142\057\142\056\164\170\164\142\162\141\166\157\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\152\071\340\320\005\000\000\000\005\000\000\000\011\000\000\000\000\000\000\000\000\000\000\000\200\001\000\000\000\000\154\151\142\057\141\056\164\170\164\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\211\270\233\011\005\000\000\000\005\000\000\000\011\000\000\000\000\000\000\000\000\000\000\000\200\001\054\000\000\000\154\151\142\057\142\056\164\170\164\120\113\005\006\000\000\000\000\002\000\002\000\156\000\000\000\130\000\000\000\000\000"

_SIGNED_LAST = "\120\113\003\004\024\000\000\000\000\000\000\000\041\120\152\071\340\320\005\000\000\000\005\000\000\000\011\000\000\000\154\151\142\057\141\056\164\170\164\141\154\160\150\141\120\113\003\004\024\000\000\000\000\000\000\000\041\120\211\270\233\011\005\000\000\000\005\000\000\000\011\000\000\000\154\151\142\057\142\056\164\170\164\142\162\141\166\157\120\113\003\004\024\000\000\000\000\000\000\000\041\120\312\134\145\033\017\000\000\000\017\000\000\000\016\000\000\000\056\163\151\147\156\141\164\165\162\145\056\160\067\163\123\111\107\116\101\124\125\122\105\055\102\131\124\105\123\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\152\071\340\320\005\000\000\000\005\000\000\000\011\000\000\000\000\000\000\000\000\000\000\000\200\001\000\000\000\000\154\151\142\057\141\056\164\170\164\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\211\270\233\011\005\000\000\000\005\000\000\000\011\000\000\000\000\000\000\000\000\000\000\000\200\001\054\000\000\000\154\151\142\057\142\056\164\170\164\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\312\134\145\033\017\000\000\000\017\000\000\000\016\000\000\000\000\000\000\000\000\000\000\000\200\001\130\000\000\000\056\163\151\147\156\141\164\165\162\145\056\160\067\163\120\113\005\006\000\000\000\000\003\000\003\000\252\000\000\000\223\000\000\000\000\000"

_SIGNED_MIDDLE = "\120\113\003\004\024\000\000\000\000\000\000\000\041\120\152\071\340\320\005\000\000\000\005\000\000\000\011\000\000\000\154\151\142\057\141\056\164\170\164\141\154\160\150\141\120\113\003\004\024\000\000\000\000\000\000\000\041\120\312\134\145\033\017\000\000\000\017\000\000\000\016\000\000\000\056\163\151\147\156\141\164\165\162\145\056\160\067\163\123\111\107\116\101\124\125\122\105\055\102\131\124\105\123\120\113\003\004\024\000\000\000\000\000\000\000\041\120\211\270\233\011\005\000\000\000\005\000\000\000\011\000\000\000\154\151\142\057\142\056\164\170\164\142\162\141\166\157\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\152\071\340\320\005\000\000\000\005\000\000\000\011\000\000\000\000\000\000\000\000\000\000\000\200\001\000\000\000\000\154\151\142\057\141\056\164\170\164\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\312\134\145\033\017\000\000\000\017\000\000\000\016\000\000\000\000\000\000\000\000\000\000\000\200\001\054\000\000\000\056\163\151\147\156\141\164\165\162\145\056\160\067\163\120\113\001\002\024\003\024\000\000\000\000\000\000\000\041\120\211\270\233\011\005\000\000\000\005\000\000\000\011\000\000\000\000\000\000\000\000\000\000\000\200\001\147\000\000\000\154\151\142\057\142\056\164\170\164\120\113\005\006\000\000\000\000\003\000\003\000\252\000\000\000\223\000\000\000\000\000"

def _unsigned_unchanged_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _UNSIGNED, strip_signature(_UNSIGNED))
    return unittest.end(env)

unsigned_unchanged_test = unittest.make(_unsigned_unchanged_impl)

def _signature_last_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _UNSIGNED, strip_signature(_SIGNED_LAST))
    return unittest.end(env)

signature_last_test = unittest.make(_signature_last_impl)

def _signature_middle_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _UNSIGNED, strip_signature(_SIGNED_MIDDLE))
    return unittest.end(env)

signature_middle_test = unittest.make(_signature_middle_impl)

# An archive comment that holds the end record signature itself.
_COMMENT = "\007\000PK\005\006abc"

def _with_comment(data):
    return data[:-2] + _COMMENT

def _archive_comment_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _with_comment(_UNSIGNED), strip_signature(_with_comment(_SIGNED_LAST)))
    return unittest.end(env)

archive_comment_test = unittest.make(_archive_comment_impl)

def _base64_to_hex_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "000102ff", base64_to_hex("AAEC/w=="))
    asserts.equals(env, "fbff", base64_to_hex("+/8="))
    return unittest.end(env)

base64_to_hex_test = unittest.make(_base64_to_hex_impl)

def _file_url_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "file:///tmp/a%20b%25/feed", file_url("/tmp/a b%/feed"))
    asserts.equals(env, "file:///C:/Users/a%20b/feed", file_url("C:\\Users\\a b\\feed"))
    return unittest.end(env)

file_url_test = unittest.make(_file_url_impl)

# Trimmed from MSTest.TestFramework 3.6.4 and MSTest.TestAdapter 3.6.4 build/net8.0.
_FRAMEWORK_TARGETS = """<Project>
  <PropertyGroup Condition=" '$(UseWinUI)' == 'true' ">
    <_TestFrameworkExtensionsRoot>$(MSBuildThisFileDirectory)../net6.0/winui/</_TestFrameworkExtensionsRoot>
  </PropertyGroup>
  <!-- <Reference Include="Commented.Out" /> -->
  <ItemGroup>
    <Reference Include="Microsoft.VisualStudio.TestPlatform.TestFramework.Extensions">
      <HintPath>$(_TestFrameworkExtensionsRoot)Microsoft.VisualStudio.TestPlatform.TestFramework.Extensions.dll</HintPath>
    </Reference>
    <Reference Include='Strong.Named, Version=1.0.0.0' />
    <Reference Include="Only.When.Set" Condition=" '$(X)' == 'true' " />
  </ItemGroup>
  <ItemGroup Condition=" '$(Y)' == 'true' ">
    <Reference Include="Conditioned.Group" />
  </ItemGroup>
  <Choose>
    <When Condition=" '$(EnableMSTestRunner)' == 'true' ">
      <ItemGroup>
        <Reference Include="Microsoft.VisualStudio.TestPlatform.MSTest.TestAdapter" />
      </ItemGroup>
    </When>
  </Choose>
  <ItemGroup>
    <Reference Include="After.Choose" />
  </ItemGroup>
</Project>
"""

def _build_references_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        ["Microsoft.VisualStudio.TestPlatform.TestFramework.Extensions", "Strong.Named", "After.Choose"],
        build_references(_FRAMEWORK_TARGETS),
    )
    asserts.equals(env, [], build_references("<Project />"))
    return unittest.end(env)

build_references_test = unittest.make(_build_references_impl)

def nupkg_test_suite(name):
    unittest.suite(
        name,
        unsigned_unchanged_test,
        signature_last_test,
        signature_middle_test,
        archive_comment_test,
        base64_to_hex_test,
        file_url_test,
        build_references_test,
    )
