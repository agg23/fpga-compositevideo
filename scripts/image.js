import getPixels from "get-pixels";
import { argv } from "process";
import { writeFileSync } from "fs";

if (argv.length != 4) {
  console.log(`Received ${argv.length - 2} arguments. Expected 2\n`);
  console.log("Usage: node image.js [input path] [output path]");

  process.exit(1);
}

const inputPath = argv[2];
const outputPath = argv[3];

const dataWidth = 1;

getPixels(inputPath, (err, pixels) => {
  if (err) {
    console.log(`Error loading pixels: ${err}`);
    return;
  }

  const [width, height] = pixels.shape;

  let outputBuffer = Buffer.alloc((width * height * dataWidth) / 2);

  let word = 0;
  let setLow = false;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const red = pixels.get(x, y, 0);
      // const green = pixels.get(x, y, 1);
      // const blue = pixels.get(x, y, 2);
      // const alpha = pixels.get(x, y, 3);

      // Use only red channel
      // outputBuffer[y * width + x] = red;
      if (setLow) {
        word |= red / 16;

        outputBuffer[Math.floor((y * width + x) / 2)] = word;
      } else {
        word = (red / 16) << 4;
      }

      setLow = !setLow;
    }
  }

  writeFileSync(outputPath, outputBuffer, { flag: "w" });
  console.log(`Wrote output file ${outputPath}`);
});
