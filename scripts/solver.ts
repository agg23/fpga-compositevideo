const bitCount = 3;

// 75 Ohms built into the TV
const seriesResistance = 75;
const voltage = 3.3;

const maxResistor = 2000;
const resistorIncrement = 10;

// Our voltages are 0-1V, and we want to solve for values >0
const voltageLevels = Math.pow(2, 3);

let bestMatchValues: number[] | undefined = undefined;
let bestDiff = Number.MAX_SAFE_INTEGER;

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

const processValues = (values: number[], childrenCount: number) => {
  if (childrenCount === 0) {
    // Base case, evaluate this last level
    const results: number[] = [];

    for (let i = 0; i < voltageLevels; i++) {
      const result = buildActiveBitEquation(values, i);

      results.push(result);
    }

    results.sort((a, b) => a - b);

    let totalDiff = 0;

    for (let i = 0; i < voltageLevels; i++) {
      const result = results[i];

      // Compare result at this index to the intended voltage level at this index
      const expectedLevel = i / (voltageLevels - 1);
      const diff = Math.abs(result - expectedLevel);

      totalDiff += diff;
    }

    if (totalDiff < bestDiff) {
      bestDiff = totalDiff;
      bestMatchValues = values;
    }
  } else {
    // Continue recursing
    for (let i = 0; i < maxResistor; i += resistorIncrement) {
      processValues([...values, i], childrenCount - 1);
    }
  }
};

for (let a = 0; a < maxResistor; a += resistorIncrement) {
  // At least one resistor value
  console.log("Processing step", a);

  processValues([a], bitCount - 1);
}

console.log("Best matches:", bestMatchValues);
console.log("Diff:", bestDiff);

for (let i = 0; i < voltageLevels; i++) {
  const result = buildActiveBitEquation(bestMatchValues, i);
  console.log(`${i}: ${result}`);
}

// console.log(buildActiveBitEquation([450, 900], 1));
// console.log(buildActiveBitEquation([450, 900], 2));
// console.log(buildActiveBitEquation([450, 900], 3));

// console.log(buildActiveBitEquation([450, 900, 1500], 7));

// processValues([350, 540, 270], 0);
