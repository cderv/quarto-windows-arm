#!/usr/bin/env -S deno run --allow-ffi
// Detect Windows ARM from x64 Deno process
// Uses IsWow64Process2 Windows API to get native architecture

function isWindowsArm(): boolean {
  if (Deno.build.os !== "windows") {
    return false;
  }

  try {
    // Load kernel32.dll
    const kernel32 = Deno.dlopen("kernel32.dll", {
      IsWow64Process2: {
        parameters: ["pointer", "pointer", "pointer"],
        result: "i32",
      },
      GetCurrentProcess: {
        parameters: [],
        result: "pointer",
      },
    });

    // Get current process handle
    const hProcess = kernel32.symbols.GetCurrentProcess();

    // Prepare output parameters - allocate buffer for USHORT (2 bytes each)
    const processMachineBuffer = new Uint16Array(1);
    const nativeMachineBuffer = new Uint16Array(1);

    // Call IsWow64Process2 with pointers to buffers
    const result = kernel32.symbols.IsWow64Process2(
      hProcess,
      Deno.UnsafePointer.of(processMachineBuffer),
      Deno.UnsafePointer.of(nativeMachineBuffer)
    );

    kernel32.close();

    if (result === 0) {
      // Function failed
      return false;
    }

    // IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
    const IMAGE_FILE_MACHINE_ARM64 = 0xAA64;
    return nativeMachineBuffer[0] === IMAGE_FILE_MACHINE_ARM64;
  } catch (error) {
    // IsWow64Process2 not available (Windows < 10) or other error
    console.error("Error detecting Windows ARM:", error);
    return false;
  }
}

// Test and display results
console.log("=== Windows ARM Detection from Deno ===");
console.log("OS:", Deno.build.os);
console.log("Arch:", Deno.build.arch);
console.log("Deno Version:", Deno.version.deno);
console.log("\nIs Windows ARM:", isWindowsArm());

// Additional diagnostic info
if (Deno.build.os === "windows") {
  console.log("\nDiagnostic Info:");
  console.log("- Running on Windows");
  console.log("- Deno reports arch as:", Deno.build.arch);

  try {
    const kernel32 = Deno.dlopen("kernel32.dll", {
      IsWow64Process: {
        parameters: ["pointer", "pointer"],
        result: "i32",
      },
      GetCurrentProcess: {
        parameters: [],
        result: "pointer",
      },
    });

    const hProcess = kernel32.symbols.GetCurrentProcess();
    const isWow64Buffer = new Uint32Array(1);
    kernel32.symbols.IsWow64Process(hProcess, Deno.UnsafePointer.of(isWow64Buffer));

    console.log("- IsWow64Process:", isWow64Buffer[0] === 1);
    kernel32.close();
  } catch (e) {
    console.log("- IsWow64Process check failed:", e);
  }
}
