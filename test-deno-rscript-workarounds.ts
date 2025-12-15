// Test potential workarounds for Deno subprocess spawning of x64 processes on Windows ARM
// The issue: R x64 executes successfully but crashes during process termination

const rscriptPath = Deno.args[0];
const capabilitiesScript = Deno.args[1];

console.log(`Testing Deno subprocess workarounds...`);
console.log(`Rscript: ${rscriptPath}`);
console.log(`Script: ${capabilitiesScript}`);
console.log();

// Test 1: Spawn through PowerShell as intermediary
console.log("=== Test 1: Spawn through PowerShell intermediary ===");
try {
  const command = new Deno.Command("powershell.exe", {
    args: ["-Command", rscriptPath, capabilitiesScript],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout } = await command.output();
  const decoder = new TextDecoder();

  console.log(`Exit code: ${code}`);
  console.log(`Output: ${decoder.decode(stdout).substring(0, 200)}...`);

  if (code === 0) {
    console.log("✅ PowerShell intermediary: SUCCESS\n");
  } else {
    console.log(`❌ PowerShell intermediary: FAILED (${code})\n`);
  }
} catch (error) {
  console.error(`❌ PowerShell intermediary: EXCEPTION - ${error}\n`);
}

// Test 2: Use "inherit" instead of "piped" for stdio
console.log("=== Test 2: Use inherit instead of piped stdio ===");
try {
  const command = new Deno.Command(rscriptPath, {
    args: [capabilitiesScript],
    stdout: "inherit",
    stderr: "inherit",
  });

  const { code } = await command.output();

  console.log(`Exit code: ${code}`);

  if (code === 0) {
    console.log("✅ Inherit stdio: SUCCESS\n");
  } else {
    console.log(`❌ Inherit stdio: FAILED (${code})\n`);
  }
} catch (error) {
  console.error(`❌ Inherit stdio: EXCEPTION - ${error}\n`);
}

// Test 3: Spawn through cmd.exe as intermediary
console.log("=== Test 3: Spawn through cmd.exe intermediary ===");
try {
  const command = new Deno.Command("cmd.exe", {
    args: ["/C", rscriptPath, capabilitiesScript],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout } = await command.output();
  const decoder = new TextDecoder();

  console.log(`Exit code: ${code}`);
  console.log(`Output: ${decoder.decode(stdout).substring(0, 200)}...`);

  if (code === 0) {
    console.log("✅ cmd.exe intermediary: SUCCESS\n");
  } else {
    console.log(`❌ cmd.exe intermediary: FAILED (${code})\n`);
  }
} catch (error) {
  console.error(`❌ cmd.exe intermediary: EXCEPTION - ${error}\n`);
}

// Test 4: Use spawn() instead of output() to avoid waiting
console.log("=== Test 4: Use spawn() with manual wait ===");
try {
  const command = new Deno.Command(rscriptPath, {
    args: [capabilitiesScript],
    stdout: "piped",
    stderr: "piped",
  });

  const child = command.spawn();
  const status = await child.status;

  console.log(`Exit code: ${status.code}`);

  if (status.code === 0) {
    console.log("✅ spawn() with manual wait: SUCCESS\n");
  } else {
    console.log(`❌ spawn() with manual wait: FAILED (${status.code})\n`);
  }
} catch (error) {
  console.error(`❌ spawn() with manual wait: EXCEPTION - ${error}\n`);
}

// Test 5: Set explicit working directory
console.log("=== Test 5: Explicit working directory ===");
try {
  const command = new Deno.Command(rscriptPath, {
    args: [capabilitiesScript],
    stdout: "piped",
    stderr: "piped",
    cwd: Deno.cwd(),
  });

  const { code, stdout } = await command.output();
  const decoder = new TextDecoder();

  console.log(`Exit code: ${code}`);
  console.log(`Output: ${decoder.decode(stdout).substring(0, 200)}...`);

  if (code === 0) {
    console.log("✅ Explicit cwd: SUCCESS\n");
  } else {
    console.log(`❌ Explicit cwd: FAILED (${code})\n`);
  }
} catch (error) {
  console.error(`❌ Explicit cwd: EXCEPTION - ${error}\n`);
}

console.log("=== Summary ===");
console.log("If any test succeeds, that approach could be a workaround for Quarto.");
