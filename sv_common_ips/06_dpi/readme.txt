This is the most useful “systems” bridge: call C++ from SV.

Important: Verilator needs the DPI C++ file compiled into the executable. Your run.sh currently only compiles sim.cpp. So in this lesson, update the verilator line to include dpi_impl.cpp too.