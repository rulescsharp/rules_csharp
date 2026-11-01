"""Toolchain definitions and repository rules for rules_csharp."""

load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "read_netrc",
    "read_user_netrc",
    "use_netrc",
)

DOTNET_ARTIFACTS = {
    "8.0.403": {
        "linux-arm64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.AspNetCore.App.Runtime.linux-arm64": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.NETCore.App.Host": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.NETCore.App.Host.linux-arm64": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.NETCore.App.Ref": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.NETCore.App.Runtime": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "Microsoft.NETCore.App.Runtime.linux-arm64": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "sdk": "sha256-5rU53mNLXEDYZjHl41SIr22+aCIp42c3UmHGNa1ejLA=",
            "sha256": "e6b539de634b5c40d86631e5e35488af6dbe682229e367375261c635ad5e8cb0",
        },
        "linux-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.AspNetCore.App.Runtime.linux-x64": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.NETCore.App.Host": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.NETCore.App.Host.linux-x64": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.NETCore.App.Ref": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.NETCore.App.Runtime": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "Microsoft.NETCore.App.Runtime.linux-x64": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "sdk": "sha256-98MfE5dESquRr7742KRuNlMUQ/rO1g+p1AcM8VqBslY=",
            "sha256": "f7c31f1397444aab91afbef8d8a46e36531443faced60fa9d4070cf15a81b256",
        },
        "osx-arm64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.AspNetCore.App.Runtime.osx-arm64": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.NETCore.App.Host": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.NETCore.App.Host.osx-arm64": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.NETCore.App.Ref": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.NETCore.App.Runtime": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "Microsoft.NETCore.App.Runtime.osx-arm64": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "sdk": "sha256-8iVXW0Sx9JrMDFi+kq0/T/bnuPT0NJeUR4wrJtdRywU=",
            "sha256": "f225575b44b1f49acc0c58be92ad3f4ff6e7b8f4f4349794478c2b26d751cb05",
        },
        "osx-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.AspNetCore.App.Runtime.osx-x64": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.NETCore.App.Host": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.NETCore.App.Host.osx-x64": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.NETCore.App.Ref": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.NETCore.App.Runtime": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "Microsoft.NETCore.App.Runtime.osx-x64": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "sdk": "sha256-dMsEfqhP1xfQN5a0nmry4Z5Y2Xb65hVxCYURBs/pnF4=",
            "sha256": "74cb047ea84fd717d03796b49e6af2e19e58d976fae6157109851106cfe99c5e",
        },
        "win-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.AspNetCore.App.Runtime.win-x64": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.NETCore.App.Host": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.NETCore.App.Host.win-x64": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.NETCore.App.Ref": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.NETCore.App.Runtime": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "Microsoft.NETCore.App.Runtime.win-x64": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "sdk": "sha256-xFlVCj3Hfjoq821b+INnRmA/cvyg5sFCy/JT1LwfC8c=",
            "sha256": "c459550a3dc77e3a2af36d5bf8836746603f72fca0e6c142cbf253d4bc1f0bc7",
        },
    },
    "9.0.200": {
        "linux-arm64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.AspNetCore.App.Runtime.linux-arm64": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.NETCore.App.Host": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.NETCore.App.Host.linux-arm64": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.NETCore.App.Ref": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.NETCore.App.Runtime": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "Microsoft.NETCore.App.Runtime.linux-arm64": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "sdk": "sha256-MmYEWpuKU2LcoOFIomM4XprpSSDW8vVoAq0tWZaYi6s=",
            "sha256": "3266045a9b8a5362dca0e148a263385e9ae94920d6f2f56802ad2d5996988bab",
        },
        "linux-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.AspNetCore.App.Runtime.linux-x64": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.NETCore.App.Host": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.NETCore.App.Host.linux-x64": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.NETCore.App.Ref": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.NETCore.App.Runtime": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "Microsoft.NETCore.App.Runtime.linux-x64": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "sdk": "sha256-wHKBoKu9LDIA5w/JTTdLrq37tDycP+kMYDglNVW4QzU=",
            "sha256": "c07281a0abbd2c3200e70fc94d374baeadfbb43c9c3fe90c6038253555b84335",
        },
        "osx-arm64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.AspNetCore.App.Runtime.osx-arm64": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.NETCore.App.Host": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.NETCore.App.Host.osx-arm64": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.NETCore.App.Ref": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.NETCore.App.Runtime": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "Microsoft.NETCore.App.Runtime.osx-arm64": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "sdk": "sha256-Pz7z60V/QIUozjYkwQg6NdMtMKQ+Vw4uzbXyGIw6NXY=",
            "sha256": "3f3ef3eb457f408528ce3624c1083a35d32d30a43e570e2ecdb5f2188c3a3576",
        },
        "osx-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.AspNetCore.App.Runtime.osx-x64": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.NETCore.App.Host": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.NETCore.App.Host.osx-x64": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.NETCore.App.Ref": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.NETCore.App.Runtime": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "Microsoft.NETCore.App.Runtime.osx-x64": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "sdk": "sha256-nHHaP/zJviknMHLK44J8Aci4FCr2oTIvyODhHAky0sQ=",
            "sha256": "9c71da3ffcc9be29273072cae3827c01c8b8142af6a1322fc8e0e11c0932d2c4",
        },
        "win-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.AspNetCore.App.Runtime.win-x64": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.NETCore.App.Host": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.NETCore.App.Host.win-x64": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.NETCore.App.Ref": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.NETCore.App.Runtime": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "Microsoft.NETCore.App.Runtime.win-x64": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "sdk": "sha256-5JPKfoBRdyyrR6++1TgbVe1QAZ0ET5ERyEv26DAGLYg=",
            "sha256": "e493ca7e8051772cab47afbed5381b55ed50019d044f9111c84bf6e830062d88",
        },
    },
    "10.0.100": {
        "linux-arm64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.AspNetCore.App.Runtime.linux-arm64": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.NETCore.App.Host": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.NETCore.App.Host.linux-arm64": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.NETCore.App.Ref": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.NETCore.App.Runtime": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "Microsoft.NETCore.App.Runtime.linux-arm64": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "sdk": "sha256-tkJa7vYAmi1Ce/YAos0C+d1qxgjmutAh/S+C9oWRR5M=",
            "sha256": "b6425aeef6009a2d427bf600a2cd02f9dd6ac608e6bad021fd2f82f685914793",
        },
        "linux-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.AspNetCore.App.Runtime.linux-x64": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.NETCore.App.Host": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.NETCore.App.Host.linux-x64": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.NETCore.App.Ref": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.NETCore.App.Runtime": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "Microsoft.NETCore.App.Runtime.linux-x64": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "sdk": "sha256-qWMcxr+tDvFnODrGVLVCVLrZWm+0tvQwn6ePVYBV5jc=",
            "sha256": "a9631cc6bfad0ef167383ac654b54254bad95a6fb4b6f4309fa78f558055e637",
        },
        "osx-arm64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.AspNetCore.App.Runtime.osx-arm64": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.NETCore.App.Host": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.NETCore.App.Host.osx-arm64": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.NETCore.App.Ref": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.NETCore.App.Runtime": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "Microsoft.NETCore.App.Runtime.osx-arm64": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "sdk": "sha256-cbOBXvjYOmu+v4YnpWY5YAGT8i1OpqbeL3GFXEs+Y/0=",
            "sha256": "71b3815ef8d83a6bbebf8627a56639600193f22d4ea6a6de2f71855c4b3e63fd",
        },
        "osx-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.AspNetCore.App.Runtime.osx-x64": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.NETCore.App.Host": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.NETCore.App.Host.osx-x64": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.NETCore.App.Ref": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.NETCore.App.Runtime": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "Microsoft.NETCore.App.Runtime.osx-x64": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "sdk": "sha256-2P1uPy45PK0wB5TUOuJtAfnbMTVslTgbz7nT1/ZtGH4=",
            "sha256": "d8fd6e3f2e393cad300794d43ae26d01f9db31356c95381bcfb9d3d7f66d187e",
        },
        "win-x64": {
            "Microsoft.AspNetCore.App.Ref": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.AspNetCore.App.Runtime": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.AspNetCore.App.Runtime.win-x64": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.NETCore.App.Host": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.NETCore.App.Host.win-x64": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.NETCore.App.Ref": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.NETCore.App.Runtime": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "Microsoft.NETCore.App.Runtime.win-x64": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "sdk": "sha256-zgm2BjfFJaXM0zaJYtyTbfEBQdOX4wX1QGMY9h2mZwk=",
            "sha256": "ce09b60637c525a5ccd3368962dc936df10141d397e305f5406318f61da66709",
        },
    },
}

PLATFORMS = {
    "darwin_arm64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:aarch64",
        "os": "@platforms//os:osx",
        "rid": "osx-arm64",
    },
    "darwin_x86_64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:osx",
        "rid": "osx-x64",
    },
    "linux_arm64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:aarch64",
        "os": "@platforms//os:linux",
        "rid": "linux-arm64",
    },
    "linux_x86_64": {
        "apphost_name": "apphost",
        "archive_ext": "tar.gz",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:linux",
        "rid": "linux-x64",
    },
    "windows_x86_64": {
        "apphost_name": "apphost.exe",
        "archive_ext": "zip",
        "cpu": "@platforms//cpu:x86_64",
        "os": "@platforms//os:windows",
        "rid": "win-x64",
    },
}

def version_to_tfm(version):
    """Derives target framework moniker from SDK version."""
    major = version.split(".")[0]
    return "net" + major + ".0"

def _resolve_netrc_auth(repository_ctx, urls):
    if repository_ctx.attr.netrc:
        netrc_data = read_netrc(repository_ctx, repository_ctx.attr.netrc)
    elif "NETRC" in repository_ctx.os.environ:
        netrc_data = read_netrc(repository_ctx, repository_ctx.os.environ["NETRC"])
    else:
        netrc_data = read_user_netrc(repository_ctx)
    auth_patterns = repository_ctx.attr.auth_patterns if hasattr(repository_ctx.attr, "auth_patterns") else {}
    return use_netrc(netrc_data, urls, auth_patterns)

def _sdk_exec_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

    urls = list(repository_ctx.attr.urls)
    if not urls:
        urls = ["https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive)]

    auth = _resolve_netrc_auth(repository_ctx, urls)
    type_ext = "zip" if ext == "zip" else "tar.gz"

    integrity = repository_ctx.attr.integrity if hasattr(repository_ctx.attr, "integrity") and repository_ctx.attr.integrity else ""
    sha256 = repository_ctx.attr.sha256 if hasattr(repository_ctx.attr, "sha256") and repository_ctx.attr.sha256 else ""

    if not integrity and not sha256:
        if version in DOTNET_ARTIFACTS and rid in DOTNET_ARTIFACTS[version]:
            integrity = DOTNET_ARTIFACTS[version][rid].get("sdk", "")

    if not integrity and not sha256:
        fail("Missing sha256 or integrity parameter for sdk_exec repository '{}'".format(repository_ctx.name))

    download_kwargs = {
        "auth": auth,
        "type": type_ext,
        "url": urls,
    }
    if integrity:
        download_kwargs["integrity"] = integrity
    elif sha256:
        download_kwargs["sha256"] = sha256

    repository_ctx.download_and_extract(**download_kwargs)

    is_windows = "win" in rid
    dotnet_bin = "dotnet.exe" if is_windows else "dotnet"
    worker_name = "CscWorker.bat" if is_windows else "CscWorker"

    worker_src = repository_ctx.path(Label("//csharp/private/tools:CscWorker.cs"))
    repository_ctx.file("CscWorker.runtimeconfig.json", """{
  "runtimeOptions": {
    "tfm": "net8.0",
    "rollForward": "LatestMajor",
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "8.0.0"
    }
  }
}""")

    csc_candidates = []
    sdk_dir = repository_ctx.path("sdk")
    if sdk_dir.exists:
        for v_dir in sdk_dir.readdir():
            cand = v_dir.get_child("Roslyn").get_child("bincore").get_child("csc.dll")
            if cand.exists:
                csc_candidates.append(cand)

    ref_dlls = []
    packs_dir = repository_ctx.path("packs/Microsoft.NETCore.App.Ref")
    if packs_dir.exists:
        for v_dir in packs_dir.readdir():
            ref_sub = v_dir.get_child("ref")
            if ref_sub.exists:
                for tfm_dir in ref_sub.readdir():
                    for f in tfm_dir.readdir():
                        if f.basename.endswith(".dll"):
                            ref_dlls.append("-r:" + str(f))

    if csc_candidates and ref_dlls:
        csc_path = str(csc_candidates[0])
        dotnet_path = str(repository_ctx.path(dotnet_bin))
        compile_cmd = [
            dotnet_path,
            "exec",
            csc_path,
            "-target:exe",
            "-out:CscWorker.dll",
            "-noconfig",
            "-nostdlib+",
        ] + ref_dlls + [str(worker_src)]
        repository_ctx.execute(compile_cmd)

    if is_windows:
        repository_ctx.file(
            worker_name,
            content = """@echo off
setlocal enabledelayedexpansion
set SCRIPT_DIR=%~dp0
set DOTNET_ROOT=%SCRIPT_DIR%
set DOTNET_MULTILEVEL_LOOKUP=0
set DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
set DOTNET_CLI_TELEMETRY_OPTOUT=1
set DOTNET_NOLOGO=1
set VBCSCOMPILER_TTL=0
set MSBUILDDISABLENODEREUSE=1
set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
set SCRATCH=%TEMP%\\.dotnet_scratch_%RANDOM%
if not exist "%SCRATCH%" mkdir "%SCRATCH%"
set DOTNET_CLI_HOME=%SCRATCH%
set HOME=%SCRATCH%
set USERPROFILE=%SCRATCH%
set APPDATA=%SCRATCH%

if exist "%SCRIPT_DIR%CscWorker.dll" (
    "%SCRIPT_DIR%dotnet.exe" exec "%SCRIPT_DIR%CscWorker.dll" %*
    set EXIT_CODE=!ERRORLEVEL!
    rmdir /s /q "%SCRATCH%" 2>nul
    exit /b !EXIT_CODE!
)
set CSC_DLL=
for /f "delims=" %%f in ('dir /b /s "%SCRIPT_DIR%sdk\\*\\Roslyn\\bincore\\csc.dll" 2^>nul') do (
    set CSC_DLL=%%f
    goto :found_csc
)
:found_csc
set ARGS=
:loop
if "%~1"=="" goto :done
if "%~1"=="--persistent_worker" goto :next
set ARGS=%ARGS% "%~1"
:next
shift
goto :loop
:done
"%SCRIPT_DIR%dotnet.exe" exec "%CSC_DLL%" %ARGS%
set EXIT_CODE=%ERRORLEVEL%
rmdir /s /q "%SCRATCH%" 2>nul
exit /b %EXIT_CODE%
""",
            executable = True,
        )
    else:
        repository_ctx.file(
            worker_name,
            content = """#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTNET_ROOT="$SCRIPT_DIR"
export DOTNET_MULTILEVEL_LOOKUP=0
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export VBCSCOMPILER_TTL=0
export MSBUILDDISABLENODEREUSE=1
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
SCRATCH="${TMPDIR:-/tmp}/.dotnet_scratch_$$"
mkdir -p "$SCRATCH"
export DOTNET_CLI_HOME="$SCRATCH"
export HOME="$SCRATCH"
export USERPROFILE="$SCRATCH"
export APPDATA="$SCRATCH"

cleanup() {
    rm -rf "$SCRATCH"
}
trap cleanup EXIT

if [ -f "$SCRIPT_DIR/CscWorker.dll" ]; then
    exec "$SCRIPT_DIR/dotnet" exec "$SCRIPT_DIR/CscWorker.dll" "$@"
fi
CSC_DLL="$(ls "$SCRIPT_DIR"/sdk/*/Roslyn/bincore/csc.dll 2>/dev/null | head -n 1)"
NEW_ARGS=()
for arg in "$@"; do
    if [ "$arg" != "--persistent_worker" ]; then
        NEW_ARGS+=("$arg")
    fi
done
exec "$SCRIPT_DIR/dotnet" exec "$CSC_DLL" "${NEW_ARGS[@]}"
""",
            executable = True,
        )

    build_content = """package(default_visibility = ["//visibility:public"])

exports_files(["{dotnet_bin}", "{worker_name}", "CscWorker.dll", "CscWorker.runtimeconfig.json"])

filegroup(
    name = "dotnet_muxer",
    srcs = ["{dotnet_bin}"],
)

filegroup(
    name = "csc_worker",
    srcs = ["{worker_name}"],
)

filegroup(
    name = "csc_worker_files",
    srcs = glob([
        "CscWorker.dll",
        "CscWorker.runtimeconfig.json",
        "{dotnet_bin}",
        "host/**",
        "shared/**",
        "sdk/*/Roslyn/bincore/**",
    ], allow_empty = True),
)

filegroup(
    name = "csc_dll",
    srcs = glob(["sdk/*/Roslyn/bincore/csc.dll"]),
)

filegroup(
    name = "vstest_dll",
    srcs = glob(["sdk/*/vstest.console.dll"]),
)

filegroup(
    name = "sdk_files",
    srcs = glob(["**/*"]),
)
""".format(dotnet_bin = dotnet_bin, worker_name = worker_name)

    repository_ctx.file("BUILD.bazel", build_content)

sdk_exec = repository_rule(
    doc = "Downloads and extracts host .NET SDK binaries.",
    implementation = _sdk_exec_impl,
    attrs = {
        "archive_ext": attr.string(
            default = "tar.gz",
            doc = "Archive file extension string.",
        ),
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_version": attr.string(
            doc = ".NET SDK version string.",
            mandatory = True,
        ),
        "integrity": attr.string(
            doc = "Expected Subresource Integrity hash string.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "platform": attr.string(
            doc = "Platform moniker string.",
            mandatory = True,
        ),
        "rid": attr.string(
            doc = "Runtime identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 integrity hash string.",
        ),
        "urls": attr.string_list(
            doc = "Ordered candidate download URL list.",
        ),
    },
)

def _runtime_pack_impl(repository_ctx):
    version = repository_ctx.attr.dotnet_version
    rid = repository_ctx.attr.rid
    ext = repository_ctx.attr.archive_ext
    archive = "dotnet-sdk-{}-{}.{}".format(version, rid, ext)

    urls = list(repository_ctx.attr.urls)
    if not urls:
        urls = ["https://dotnetcli.azureedge.net/dotnet/Sdk/{}/{}".format(version, archive)]

    auth = _resolve_netrc_auth(repository_ctx, urls)
    type_ext = "zip" if ext == "zip" else "tar.gz"

    integrity = repository_ctx.attr.integrity if hasattr(repository_ctx.attr, "integrity") and repository_ctx.attr.integrity else ""
    sha256 = repository_ctx.attr.sha256 if hasattr(repository_ctx.attr, "sha256") and repository_ctx.attr.sha256 else ""

    if not integrity and not sha256:
        if version in DOTNET_ARTIFACTS and rid in DOTNET_ARTIFACTS[version]:
            integrity = DOTNET_ARTIFACTS[version][rid].get("sdk", "")

    if not integrity and not sha256:
        fail("Missing sha256 or integrity parameter for runtime_pack repository '{}'".format(repository_ctx.name))

    download_kwargs = {
        "auth": auth,
        "type": type_ext,
        "url": urls,
    }
    if integrity:
        download_kwargs["integrity"] = integrity
    elif sha256:
        download_kwargs["sha256"] = sha256

    repository_ctx.download_and_extract(**download_kwargs)

    is_windows = "win" in rid
    apphost_name = "apphost.exe" if is_windows else "apphost"

    build_content = """package(default_visibility = ["//visibility:public"])

filegroup(
    name = "ref_pack",
    srcs = glob(["packs/Microsoft.NETCore.App.Ref/*/ref/*/*.dll"]),
)

filegroup(
    name = "aspnetcore_ref_pack",
    srcs = glob(["packs/Microsoft.AspNetCore.App.Ref/*/ref/*/*.dll"]),
)

filegroup(
    name = "host_pack",
    srcs = glob(["packs/Microsoft.NETCore.App.Host.{rid}/*/runtimes/{rid}/native/{apphost_name}"], allow_empty = True),
)

filegroup(
    name = "runtime_pack",
    srcs = glob([
        "shared/Microsoft.NETCore.App/**",
        "shared/Microsoft.AspNetCore.App/**",
        "host/fxr/**",
    ], allow_empty = True),
)

filegroup(
    name = "all_files",
    srcs = glob(["**/*"]),
)
""".format(apphost_name = apphost_name, rid = rid)

    repository_ctx.file("BUILD.bazel", build_content)

runtime_pack = repository_rule(
    doc = "Downloads and extracts target platform reference and runtime packs.",
    implementation = _runtime_pack_impl,
    attrs = {
        "archive_ext": attr.string(
            default = "tar.gz",
            doc = "Archive file extension string.",
        ),
        "auth_patterns": attr.string_dict(
            doc = "Host to authentication pattern mappings.",
        ),
        "dotnet_version": attr.string(
            doc = ".NET SDK version string.",
            mandatory = True,
        ),
        "integrity": attr.string(
            doc = "Expected Subresource Integrity hash string.",
        ),
        "netrc": attr.label(
            doc = "Authentication netrc configuration file label.",
        ),
        "platform": attr.string(
            doc = "Platform moniker string.",
            mandatory = True,
        ),
        "rid": attr.string(
            doc = "Runtime identifier string.",
            mandatory = True,
        ),
        "sha256": attr.string(
            doc = "Expected SHA-256 integrity hash string.",
        ),
        "urls": attr.string_list(
            doc = "Ordered candidate download URL list.",
        ),
    },
)

def _csharp_toolchains_hub_impl(repository_ctx):
    lines = [
        "load(\"@rules_csharp//csharp/private:toolchain_impl.bzl\", \"csharp_toolchain\")",
        "package(default_visibility = [\"//visibility:public\"])",
        "",
    ]

    versions = repository_ctx.attr.dotnet_versions
    newest = max(versions, key = lambda v: [int(p) for p in v.split(".")])
    for tfm in [""] + [version_to_tfm(v) for v in versions]:
        lines.append("""config_setting(
    name = "target_framework_{name}",
    flag_values = {{"@rules_csharp//csharp/settings:target_framework": "{tfm}"}},
)
""".format(name = tfm or "default", tfm = tfm))

    for version in versions:
        v_slug = version.replace(".", "_")
        tfm = version_to_tfm(version)
        target_settings = [tfm] + (["default"] if version == newest else [])

        for exec_p, exec_info in PLATFORMS.items():
            worker_name = "CscWorker.bat" if "win" in exec_info["rid"] else "CscWorker"
            for target_p, target_info in PLATFORMS.items():
                impl_name = "csharp_toolchain_{}_{}_{}".format(v_slug, exec_p, target_p)
                tc_name = "toolchain_{}_{}_{}".format(v_slug, exec_p, target_p)

                lines.append("""csharp_toolchain(
    name = "{impl_name}",
    dotnet_muxer = "@dotnet_sdk_{v_slug}_{exec_p}//:dotnet_muxer",
    csc_dll = "@dotnet_sdk_{v_slug}_{exec_p}//:csc_dll",
    csc_worker = "@dotnet_sdk_{v_slug}_{exec_p}//:{worker_name}",
    csc_worker_files = ["@dotnet_sdk_{v_slug}_{exec_p}//:csc_worker_files"],
    ref_pack = ["@csharp_pack_{v_slug}_{target_p}//:ref_pack"],
    aspnetcore_ref_pack = ["@csharp_pack_{v_slug}_{target_p}//:aspnetcore_ref_pack"],
    host_pack = "@csharp_pack_{v_slug}_{target_p}//:host_pack",
    runtime_pack = ["@csharp_pack_{v_slug}_{target_p}//:runtime_pack"],
    target_framework = "{tfm}",
    target_rid = "{target_rid}",
    host_rid = "{host_rid}",
    vstest_dll = "@dotnet_sdk_{v_slug}_{exec_p}//:vstest_dll",
)
""".format(
                    exec_p = exec_p,
                    host_rid = exec_info["rid"],
                    impl_name = impl_name,
                    target_p = target_p,
                    target_rid = target_info["rid"],
                    tfm = tfm,
                    v_slug = v_slug,
                    worker_name = worker_name,
                ))

                for setting in target_settings:
                    lines.append("""toolchain(
    name = "{tc_name}",
    toolchain_type = "@rules_csharp//csharp:toolchain_type",
    toolchain = ":{impl_name}",
    exec_compatible_with = [
        "{exec_os}",
        "{exec_cpu}",
    ],
    target_compatible_with = [
        "{target_os}",
        "{target_cpu}",
    ],
    target_settings = [":target_framework_{setting}"],
)
""".format(
                        exec_cpu = exec_info["cpu"],
                        exec_os = exec_info["os"],
                        impl_name = impl_name,
                        setting = setting,
                        target_cpu = target_info["cpu"],
                        target_os = target_info["os"],
                        tc_name = tc_name if setting == tfm else tc_name + "_default",
                    ))

    repository_ctx.file("BUILD.bazel", "\n".join(lines))

csharp_toolchains_hub = repository_rule(
    doc = "Generates toolchain target declarations for all platform combinations.",
    implementation = _csharp_toolchains_hub_impl,
    attrs = {
        "dotnet_versions": attr.string_list(
            default = ["8.0.403", "9.0.200", "10.0.100"],
            doc = "Supported .NET SDK version strings.",
        ),
    },
)
