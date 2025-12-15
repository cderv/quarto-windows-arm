// Test script to verify Deno can spawn Rscript on Windows ARM
// This isolates whether the issue is Deno's subprocess spawning or Quarto-specific

const rscriptPath = Deno.args[0];
const capabilitiesScript = Deno.args[1];

console.log(`Testing Deno subprocess spawning of Rscript...`);
console.log(`Rscript: ${rscriptPath}`);
console.log(`Script: ${capabilitiesScript}`);
console.log();

try {
  const command = new Deno.Command(rscriptPath, {
    args: [capabilitiesScript],
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout, stderr } = await command.output();

  const decoder = new TextDecoder();
  const stdoutText = decoder.decode(stdout);
  const stderrText = decoder.decode(stderr);

  console.log(`Exit code: ${code}`);
  console.log(`Stdout:`);
  console.log(stdoutText);

  if (stderrText) {
    console.log(`Stderr:`);
    console.log(stderrText);
  }

  if (code !== 0) {
    console.error(`\nDeno subprocess spawn FAILED with exit code ${code}`);
    Deno.exit(1);
  } else {
    console.log(`\nDeno subprocess spawn SUCCEEDED`);
    Deno.exit(0);
  }
} catch (error) {
  console.error(`\nDeno subprocess spawn threw exception:`);
  console.error(error);
  Deno.exit(1);
}
