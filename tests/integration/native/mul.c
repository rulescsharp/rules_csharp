#ifdef _WIN32
__declspec(dllexport)
#endif
int mul(int a, int b) { return a * b; }
