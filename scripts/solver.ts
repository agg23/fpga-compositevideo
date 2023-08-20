const munkres = require("munkres-js");

const bitCount = 3;
const voltage = 3.3;
// const voltage = 5;

// 75 Ohms built into the TV
const seriesResistance = 75;
// This is incorrect, black voltage is 0.3. However with 3 bits, it's hard to solve for output values between 0.3-1.0,
// so we calculate from 0.0-1.0
// const blackVoltage = 0.0;
const blackVoltage = 0.3;
const whiteVoltage = 1.0;

const colorRangeTolerance = 0.1;

const maxResistor = 2000;
// const resistorIncrement = 10;

type ResistorConfig =
  | {
      type: "allValues";
      increment: number;
    }
  | {
      type: "setValues";
      values: number[];
    };

// Do a full search over the searchspace (stepping by 10)
// const config: ResistorConfig = {
//   type: "allValues",
//   increment: 10,
// } as ResistorConfig;

// Search for specific resistor values
const config: ResistorConfig = {
  type: "setValues",
  values: [
    10, 22, 47, 100, 150, 200, 220, 270, 330, 470, 510, 680, 1000, 2000, 2200,
    3300, 4700, 5100,
  ],
} as ResistorConfig;

const numberOfVoltageLevels = Math.pow(2, bitCount);

const voltageLevels: number[] = [];

const voltageRange = whiteVoltage - blackVoltage;
const voltageStepSize = voltageRange / (numberOfVoltageLevels - 1);
for (let i = 0; i < numberOfVoltageLevels; i++) {
  // Take the steps between 0-0.7 and shift them to be 0.3-1.0
  voltageLevels.push(voltageStepSize * i + blackVoltage);
}

let bestMatchValues: number[] | undefined = undefined;
let bestDiff = Number.MAX_SAFE_INTEGER;

const resistorIterator = (
  variableValues: number[],
  closure: (variableValues: number[]) => void
) => {
  switch (config.type) {
    case "allValues": {
      for (let i = config.increment; i < maxResistor; i += config.increment) {
        closure([...variableValues, i]);
      }

      break;
    }
    case "setValues": {
      for (const resistorValue of config.values) {
        closure([...variableValues, resistorValue]);
      }

      break;
    }
  }
};

const buildActiveBitEquation = (values: number[], activeBits: number) => {
  const activeValues: number[] = [];
  const groundedValues: number[] = [];

  for (let i = 0; i < values.length; i++) {
    const value = values[i];
    const active = activeBits & (1 << i);

    if (active) {
      activeValues.push(value);
    } else {
      groundedValues.push(value);
    }
  }

  let groundedPath = 0;

  // All grounded resistors are in parallel
  let groundedParallel = 1 / 75;
  for (const value of groundedValues) {
    groundedParallel += 1 / value;
  }

  groundedPath += 1 / groundedParallel;

  // All active resistors are in parallel
  let activeParallel = 0;

  for (const value of activeValues) {
    activeParallel += 1 / value;
  }

  activeParallel = 1 / activeParallel;

  return (groundedPath / (groundedPath + activeParallel)) * voltage;
};

const distributedExpectedPointsWithinRange = (
  pointCount: number,
  range: { min: number; max: number }
): number[] => {
  const points: number[] = [];

  const diff = range.max - range.min;
  const segmentSize = diff / (pointCount + 1);

  for (let i = 0; i <= pointCount + 1; i++) {
    points.push(segmentSize * i + range.min);
  }

  return points;
};

const processValues = (variableValues: number[], childrenCount: number) => {
  if (childrenCount !== 0) {
    // Continue recursing
    resistorIterator(variableValues, (values) => {
      processValues(values, childrenCount - 1);
    });

    return;
  }

  // Base case, evaluate this last level
  const results: number[] = [];

  // Ignore the off case
  for (let i = 1; i < numberOfVoltageLevels; i++) {
    const result = buildActiveBitEquation(variableValues, i);

    results.push(result);
  }

  results.sort((a, b) => a - b);

  let processBestActiveBits: number[] | undefined = undefined;
  let processBestDiff = Number.MAX_SAFE_INTEGER;

  const m = new munkres.Munkres();

  // Attempt matching with a different number of usable elements
  // There must be at least 1 element in the result, and 2 matches must be black and white voltages
  for (
    let pointCount = 1;
    pointCount < numberOfVoltageLevels - 2;
    pointCount++
  ) {
    const points = distributedExpectedPointsWithinRange(pointCount, {
      min: blackVoltage,
      max: whiteVoltage,
    });

    // Find the best match for each of these evenly distributed points in the resistor results
    const selectedActiveBits: number[] = [];
    let selectedDiff = 0;

    // Build cost matrix. Munkres-JS will automatically 0 pad to make it square
    const matrix: Array<number[]> = [];

    for (const point of points) {
      const row: number[] = [];

      for (const voltageResult of results) {
        // Drift with this resistor combination to our target voltage
        const distance = Math.abs(point - voltageResult);

        row.push(distance);
      }

      matrix.push(row);
    }

    const result = m.compute(matrix);

    for (const tuple of result) {
      const [row, column] = tuple;

      const diff = matrix[row][column];
      selectedDiff += diff;

      // Push selected variable values. These are offset active bits because of 0
      const variableActiveBits = column + 1;
      selectedActiveBits.push(variableActiveBits);
    }

    // TODO: This should check all possible allocations of point to generated resistor value to prevent local maxima

    // Compare average diff so that more variables selected doesn't mean more diff
    selectedDiff = selectedDiff / pointCount;

    if (selectedDiff < processBestDiff) {
      processBestActiveBits = selectedActiveBits;
      processBestDiff = selectedDiff;
    }
  }

  if (processBestDiff < bestDiff) {
    bestDiff = processBestDiff;
    bestMatchValues = variableValues;
  }
};

// processValues([450, 900], 0);

resistorIterator([], (values) => {
  // At least one resistor value
  console.log("Processing step", values[0]);

  processValues(values, bitCount - 1);
});

console.log("Best matches:", bestMatchValues);
console.log("Diff:", bestDiff);

if (bestMatchValues === undefined) {
  console.log("No match found");

  process.exit();
}

for (let i = 0; i < numberOfVoltageLevels; i++) {
  const result = buildActiveBitEquation(bestMatchValues, i);

  const activeResistors = bestMatchValues.filter((_, index) => {
    return (i & (1 << index)) != 0;
  });

  const resistorString =
    activeResistors.length > 0 ? `${activeResistors.join(", ")}` : "None";

  console.log(`${resistorString}: ${result}`);
}
