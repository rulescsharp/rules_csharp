int mul(int a, int b);

#ifdef _WIN32
__declspec(dllexport)
#endif
int muladd(int a, int b, int c) { return mul(a, b) + c; }
