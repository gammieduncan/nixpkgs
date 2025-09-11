// Empty shared library to force a non-toolchain rpath during link.
int shim_symbol(void) { return 42; }

