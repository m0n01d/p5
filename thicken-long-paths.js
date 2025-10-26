#!/usr/bin/env node

/**
 * SVG Path Thickener
 *
 * Takes an SVG file and duplicates longer paths with slight offsets
 * to make them appear thicker when pen plotting.
 *
 * Usage: node thicken-long-paths.js input.svg output.svg [options]
 *
 * Options:
 *   --threshold <number>  Minimum path length to thicken (default: 100)
 *   --offset <number>     Distance to offset duplicate paths (default: 0.5)
 *   --copies <number>     Number of duplicate paths to create (default: 2)
 */

const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length < 2 || args.includes('--help') || args.includes('-h')) {
  console.log(`
SVG Path Thickener

Takes an SVG file and duplicates longer paths with slight offsets
to make them appear thicker when pen plotting.

Usage: node thicken-long-paths.js input.svg output.svg [options]

Options:
  --threshold <number>  Minimum path length to thicken (default: 100)
  --offset <number>     Distance to offset duplicate paths (default: 0.5)
  --copies <number>     Number of duplicate paths to create (default: 2)
  --help, -h           Show this help message

Example:
  node thicken-long-paths.js input.svg output.svg --threshold 150 --offset 0.8
  `);
  process.exit(0);
}

const inputFile = args[0];
const outputFile = args[1];

// Parse options
let threshold = 100;
let offset = 0.5;
let copies = 2;

for (let i = 2; i < args.length; i += 2) {
  const option = args[i];
  const value = parseFloat(args[i + 1]);

  if (option === '--threshold') threshold = value;
  else if (option === '--offset') offset = value;
  else if (option === '--copies') copies = Math.floor(value);
}

console.log(`Processing SVG with settings:`);
console.log(`  Threshold: ${threshold}`);
console.log(`  Offset: ${offset}`);
console.log(`  Copies: ${copies}`);

// Read the input SVG
if (!fs.existsSync(inputFile)) {
  console.error(`Error: Input file "${inputFile}" not found`);
  process.exit(1);
}

const svgContent = fs.readFileSync(inputFile, 'utf8');

/**
 * Calculate the approximate length of an SVG path
 * This is a simplified calculation that works for lines and basic curves
 */
function calculatePathLength(pathData) {
  const commands = parsePath(pathData);
  let length = 0;
  let currentX = 0;
  let currentY = 0;

  for (const cmd of commands) {
    const type = cmd.type;
    const values = cmd.values;

    switch (type.toUpperCase()) {
      case 'M': // Move to
        currentX = values[0];
        currentY = values[1];
        break;

      case 'L': // Line to
        const dx = values[0] - currentX;
        const dy = values[1] - currentY;
        length += Math.sqrt(dx * dx + dy * dy);
        currentX = values[0];
        currentY = values[1];
        break;

      case 'H': // Horizontal line
        length += Math.abs(values[0] - currentX);
        currentX = values[0];
        break;

      case 'V': // Vertical line
        length += Math.abs(values[0] - currentY);
        currentY = values[0];
        break;

      case 'C': // Cubic bezier
        // Approximate cubic bezier length
        const c1x = values[0], c1y = values[1];
        const c2x = values[2], c2y = values[3];
        const endX = values[4], endY = values[5];

        // Simple approximation: sum of control polygon edges
        length += Math.sqrt((c1x - currentX) ** 2 + (c1y - currentY) ** 2);
        length += Math.sqrt((c2x - c1x) ** 2 + (c2y - c1y) ** 2);
        length += Math.sqrt((endX - c2x) ** 2 + (endY - c2y) ** 2);

        currentX = endX;
        currentY = endY;
        break;

      case 'Q': // Quadratic bezier
        const qcx = values[0], qcy = values[1];
        const qendX = values[2], qendY = values[3];

        length += Math.sqrt((qcx - currentX) ** 2 + (qcy - currentY) ** 2);
        length += Math.sqrt((qendX - qcx) ** 2 + (qendY - qcy) ** 2);

        currentX = qendX;
        currentY = qendY;
        break;
    }
  }

  return length;
}

/**
 * Parse SVG path data into commands
 */
function parsePath(pathData) {
  const commands = [];
  const regex = /([MLHVCSQTAZmlhvcsqtaz])([^MLHVCSQTAZmlhvcsqtaz]*)/g;
  let match;

  while ((match = regex.exec(pathData)) !== null) {
    const type = match[1];
    const valueString = match[2].trim();
    const values = valueString
      .split(/[\s,]+/)
      .filter(v => v.length > 0)
      .map(v => parseFloat(v));

    commands.push({ type, values });
  }

  return commands;
}

/**
 * Offset a path by a given amount
 * This creates a parallel path offset perpendicular to the original
 */
function offsetPath(pathData, offsetAmount, direction = 1) {
  const commands = parsePath(pathData);
  const newCommands = [];

  for (let i = 0; i < commands.length; i++) {
    const cmd = commands[i];
    const type = cmd.type;
    const values = [...cmd.values];

    // For simplicity, we'll offset all points perpendicular to the general direction
    // This is a simplified approach - a full implementation would calculate normals

    if (type.toUpperCase() === 'M' || type.toUpperCase() === 'L') {
      // Simple offset: add perpendicular offset
      // We'll use a simple random offset for now to create variation
      const angle = Math.random() * Math.PI * 2;
      values[0] += Math.cos(angle) * offsetAmount * direction;
      values[1] += Math.sin(angle) * offsetAmount * direction;
    } else if (type.toUpperCase() === 'C') {
      // Offset all control points
      const angle = Math.random() * Math.PI * 2;
      const dx = Math.cos(angle) * offsetAmount * direction;
      const dy = Math.sin(angle) * offsetAmount * direction;

      for (let j = 0; j < values.length; j += 2) {
        values[j] += dx;
        values[j + 1] += dy;
      }
    }

    newCommands.push({ type, values });
  }

  // Reconstruct path string
  return newCommands.map(cmd => {
    return cmd.type + cmd.values.join(',');
  }).join('');
}

/**
 * Process the SVG and thicken long paths
 */
function processSVG(svgContent) {
  // Match all path elements
  const pathRegex = /<path([^>]*)d="([^"]*)"([^>]*)>/g;
  let match;
  const pathsToAdd = [];

  while ((match = pathRegex.exec(svgContent)) !== null) {
    const beforeD = match[1];
    const pathData = match[2];
    const afterD = match[3];
    const fullMatch = match[0];

    // Calculate path length
    const length = calculatePathLength(pathData);

    console.log(`Path length: ${length.toFixed(2)}`);

    if (length >= threshold) {
      console.log(`  -> Thickening this path (${copies} copies)`);

      // Create offset copies
      for (let i = 1; i <= copies; i++) {
        const direction = i % 2 === 0 ? 1 : -1;
        const currentOffset = offset * Math.ceil(i / 2);
        const offsetPathData = offsetPath(pathData, currentOffset, direction);

        // Create new path element with same attributes
        const newPath = `<path${beforeD}d="${offsetPathData}"${afterD}>`;
        pathsToAdd.push({ after: fullMatch, path: newPath });
      }
    }
  }

  // Insert new paths after their originals
  let result = svgContent;

  // Process in reverse to maintain correct positions
  for (let i = pathsToAdd.length - 1; i >= 0; i--) {
    const { after, path } = pathsToAdd[i];
    const index = result.lastIndexOf(after);
    if (index !== -1) {
      result = result.slice(0, index + after.length) + '\n' + path + result.slice(index + after.length);
    }
  }

  return result;
}

// Process the SVG
console.log(`\nReading ${inputFile}...`);
const processedSVG = processSVG(svgContent);

// Write output
fs.writeFileSync(outputFile, processedSVG);
console.log(`\nWrote processed SVG to ${outputFile}`);
console.log('Done!');
