// dpi_impl.cpp
//
// This file provides the C function that SystemVerilog imports via DPI.
//
// Important:
//  - Name must match exactly: dpi_add
//  - Use extern "C" to prevent C++ name mangling

#include <cstdint>

extern "C" int dpi_add(int a, int b) {
    // Put any C++ logic here: logging, models, golden reference, etc.
    return a + b;
}