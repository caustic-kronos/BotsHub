# BotsHub Copilot Instructions

## Project Overview

BotsHub is an AutoIt-based automation hub for Guild Wars.

The project provides:
- a unified framework and UI for multiple bots
- shared inventory, loot, farm, and title tracking systems
- configurable item handling systems
- modular plug-and-play bot support

The codebase prioritizes:
- reliability
- explicit logic
- maintainability
- low overhead
- predictable runtime behavior
- minimal unnecessary memory reads

This is primarily an AutoIt project with:
- `.au3` source files
- JSON configuration files
- supporting documentation

The project is performance-sensitive due to heavy interaction with the Guild Wars client and GWA2 memory reading APIs.

Game updates frequently break memory reads and offsets. Reviewers should recognize that temporary instability after game patches is expected behavior and not necessarily a regression caused by the PR itself.

Material merchant handling is historically fragile and should receive extra attention during reviews.


# Coding Standards

## Naming

Use camelCase identifiers.

Avoid Hungarian notation.

Global constants:
```autoit
Global Const $GLOBAL_CONSTANT_VALUE
```

Global variables:
```autoit
Global $global_value
```

Local variables:
```autoit
Local $localValue
```

## Formatting

- tabs only
- avoid trailing whitespace
- avoid overly compact expressions
- keep control flow visually clear

## Comments

- no inline comments
- prefer self-documenting code
- use comments only for non-obvious reasoning or important context

## Functions

- prefer focused functions
- avoid deep nesting
- prefer early returns
- avoid unnecessary wrappers
- avoid splitting simple logic into excessive helper functions

## Variables and Data Structures

- minimize mutable shared state
- avoid repeated array resizing
- avoid unnecessary temporary allocations
- prefer maps over repeated array searching where appropriate
- prefer direct indexed array assignment over `ArrayAdd`

## Performance Rules

Performance is a major priority.

When reviewing code:
- minimize GWA2 API calls whenever possible
- reduce unnecessary memory reads
- avoid polling-heavy patterns
- avoid excessive `AdlibRegister` usage
- avoid low interval `AdlibRegister` timers unless absolutely necessary
- avoid repeated linear array searches in hot paths
- avoid unnecessary loops in frequently executed code
- avoid excessive allocations and resizing operations

Prefer:
- cached values where safe
- maps/dictionaries for lookup-heavy logic
- predictable control flow
- lightweight operations in loops and timers

Do not recommend abstractions that reduce performance clarity.


# Review Priorities

Focus reviews on:
1. correctness
2. regressions
3. edge cases
4. performance
5. resource leaks
6. maintainability
7. clarity

Prioritize:
- runtime stability
- predictable behavior
- low-overhead implementations
- readability of control flow

Do NOT focus on:
- trivial formatting
- subjective style preferences
- unnecessary abstractions
- "modernization" without measurable benefit
- replacing stable logic with more abstract patterns
- theoretical improvements that increase complexity


# Architecture Constraints

- avoid hidden global dependencies
- avoid circular module coupling
- avoid unnecessary abstraction layers
- avoid generic wrappers with single call sites
- preserve consistency with existing framework patterns
- maintain modular plug-and-play bot compatibility


# Testing Expectations

When reviewing changes:
- identify missing edge case handling
- identify regression risks
- verify cleanup behavior
- verify invalid input handling
- verify behavior during failed memory reads
- verify behavior when game state changes unexpectedly
- verify timer/adlib behavior under extended runtime conditions


# Reliability Rules

Flag:
- silent failures
- swallowed errors
- unchecked return values
- unsafe file operations
- unbounded retries
- resource leaks
- inconsistent cleanup behavior
- excessive memory reads
- unnecessary GWA2 calls
- polling-heavy implementations


# AutoIt-Specific Guidance

Prefer:
- explicit control flow
- defensive validation
- stable runtime behavior
- simple predictable logic

Avoid suggesting:
- OOP-style overengineering
- excessive indirection
- callback-heavy architectures
- unnecessary async/event complexity
- wrapper proliferation
- generic utility abstractions with little reuse value
- rewrites without measurable benefit

Code suggestions should align with the existing BotsHub architecture and conventions rather than generic enterprise patterns.
