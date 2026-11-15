# Bench-Voltage Si, GaN, and SiC Switch Module

An open, low-voltage teaching module in which one amplifier is built nine ways: three gain settings, each switched by a silicon (Si), gallium nitride (GaN) or silicon carbide (SiC) transistor. Everything except the switch stays the same, so students can see for themselves what the switch material changes and what it does not.

This repository holds everything needed to rebuild the module and repeat the measurements: firmware, the circuit schematic, the parts list with prices, the Simulink model, the analysis scripts and the measured data.

Companion repository to the paper *"Learning Where Wide-Bandgap Switches Belong: A Bench-Voltage Si, GaN, and SiC Amplifier Module for Energy-Transition Engineering Education"* (IEEE SusTech 2027, under review). Built at Wentworth Institute of Technology, Boston, MA.

---

## Why this module exists

Gallium nitride and silicon carbide transistors make power converters more efficient, which matters for electric vehicles, solar inverters and the wider move to electric power. They cost more than silicon, so they only pay off in circuits that use their strengths: high voltage, high current and fast switching.

Students rarely get to handle these devices, because most teaching setups that use them are high-voltage power stages. This module runs at bench voltage (20 V at most) and places all three technologies in a circuit students already know, a non-inverting op-amp amplifier. It shows a case where wide-bandgap devices bring no measurable benefit, which is the other half of learning where they belong.

---

## What is in this repository

```
firmware/   Arduino sketch that selects the gain state, drives the gates and reads the output
hardware/   KiCad schematic and the bill of materials with prices (BOM.csv)
matlab/     Simulink model of the circuit and the analysis scripts
data/       Measured resistor values, node voltages and output readings (CSV)
LICENSE     MIT license
```

---

## How the circuit works

**The amplifier.** An MCP6004 op-amp is wired as a non-inverting amplifier. Its gain is set by two resistors:

```
G = 1 + Rf / Ri          Vout = Vin x G
```

Rf is a fixed 100 kOhm feedback resistor. Ri is the input resistor, and each of the nine branches has its own Ri and its own switch. Turning on one switch connects that branch's Ri, which sets the gain.

**The input.** A resistor divider (10 kOhm over 1 kOhm plus 33 Ohm) drops the 5 V supply to about 0.47 V. On the built board it measured 0.485 V.

**The three gain tiers.**

| Tier | Ri (nominal) | Gain | Output at 0.485 V input |
|---|---|---|---|
| Low | 100 kOhm | 2.00 | about 0.97 V |
| Mid | 22 kOhm + 2.2 kOhm = 24.2 kOhm | 5.13 | about 2.48 V |
| High | 10 kOhm + 680 Ohm = 10.68 kOhm | 10.36 | about 4.96 V |

Each tier is built three times, once with each switch:

| Technology | Part | Gate voltage needed |
|---|---|---|
| Silicon | Infineon IRLU024NPBF | 5 V, straight from the Arduino |
| Gallium nitride | Renesas TP65H150G4PS | 10 V from a bench supply |
| Silicon carbide | Microchip MSC750SMA170B | 20 V from a bench supply |

**Why the gate drive matters.** The first version drove every gate from the Arduino at 5 V. The silicon branches worked. The GaN and SiC branches only half turned on, because their datasheets specify operation at 10 V and at 18 to 20 V. The fix gives those gates their own supply rails through a 10 kOhm pull-up resistor, with a 2N7000 transistor that the Arduino uses to pull each gate to ground. This is the most useful hands-on lesson in the build: each technology needs its own drive voltage.

**Why the firmware looks inverted.** Because of the 2N7000, the GaN and SiC branches work the opposite way to silicon:

| Branch | Arduino pin HIGH | Arduino pin LOW |
|---|---|---|
| Si | switch on | switch off |
| GaN, SiC | switch off | switch on |

The firmware keeps a table of which branches are inverted, turns every branch off before turning on the selected one, and never allows two branches on at once. Two branches on together would put their resistors in parallel and give a gain that matches no state.

---

## Rebuilding it

1. **Get the parts** in `hardware/BOM.csv`. Single-unit prices (Digi-Key, Adafruit and the Arduino store, November 2026), not counting the bench supply and meters most labs already have:

   | Build | Cost |
   |---|---|
   | Platform: Arduino, ADC module, LCD | $44.22 |
   | Full nine-branch build, including platform | $102.32 |
   | Simplified three-branch silicon build, including platform | $63.61 |

2. **Measure before you build.** Measure the 5 V supply and every resistor before placing it, and write the measured values down. The gain depends on a ratio of resistors, so a resistor that is off by 1 percent shifts the output by about the same amount as the differences you are trying to see. In this project, the single input voltage mattered more than all the resistors together.
3. **Wire the circuit** from `hardware/researchPGA.kicad_sch` (open with KiCad 7 or later). Note: the op-amp symbol in the schematic shows single op-amp pin numbers. On the MCP6004, section A uses pin 1 (output), pin 2 (inverting input) and pin 3 (non-inverting input), with 5 V on pin 4 and ground on pin 11.
4. **Connect the gate rails:** 10 V for the GaN pull-ups, 20 V for the SiC pull-ups. Silicon gates need no extra supply.
5. **Load the firmware** `firmware/pga_project1.ino` with the Arduino IDE. It needs the Adafruit ADS1X15 and LiquidCrystal libraries. The ADC is set to its plus or minus 6.144 V range, because the High tier output is close to 5 V.
6. **Run the states.** Each button press moves to the next state (0 is all off, 1 to 9 are the branches). The firmware waits 50 ms for the output to settle, then shows the reading on the LCD and the serial monitor. Take several readings per state.
7. **Compare with the expected values** in the table above, or in `data/vout_trials.csv` for the values measured on the original board.

**Safety.** The highest voltage on the board is 20 V. The pull-up resistors carry about 2 mA on the 20 V rail and 1 mA on the 10 V rail, and the amplifier signals are in the microampere range. Still, turn the bench supply off before rewiring the gate rails.

---

## The Simulink model

`matlab/PGA_twin.slx` models the circuit with one branch whose values change for each state, instead of nine copies. All nine states share the same circuit and differ only in component values, so one branch is enough and leaves only one place for a wiring mistake.

The op-amp block limits its output to 5.125 V, which is 25 mV below the 5.15 V logic-high level measured on the board. The switch block uses gate threshold and conduction values taken from each part's datasheet.

| Script | What it does |
|---|---|
| `demo_twin_vs_measured.m` | Runs the model for all nine states and compares it with the measured board |
| `deliverable4.m` | Plots the predicted, simulated and measured output for all nine states |
| `deliverable2_monte_carlo.m` | Monte Carlo check: repeats the gain calculation 20,000 times per state with resistors randomly varied within 1 percent, to show how far the output can spread from resistor tolerance alone |
| `deliverable1_bandgap_comparison.m` | Bar charts of bandgap energy and critical field for Si, GaN and SiC (literature values) |
| `make_paper_figures.m` | Produces the error-budget and residual figures used in the paper |

Requires MATLAB with Simulink and Simscape Electrical (available through student licenses). The model is a single amplifier stage, so a free circuit simulator can reproduce the same comparison.

---

## The data

| File | Contents |
|---|---|
| `data/resistors_measured.csv` | Input divider and feedback resistor, nominal and measured |
| `data/branches_measured.csv` | Measured resistors and pull-ups for each of the nine branches |
| `data/node_voltages.csv` | Input and gate voltages measured at each state |
| `data/vout_trials.csv` | Five output readings per state, their mean and sample standard deviation |

Resistors were measured with a GW Instek LCR-817 meter and voltages with an Agilent bench digital multimeter. Output readings were taken from the ADS1115 through the firmware and recorded to the nearest millivolt.

---

## Ideas for extending it

- **Simplify it:** keep only the three silicon branches for a first-year amplifier lab.
- **Add a fourth technology:** each tier accepts any switch the existing gate drive can turn on. Measure it with the same steps and add it to the model.
- **Find where wide-bandgap pays off:** build a switching stage (for example a small converter) where switching speed and losses matter, and compare the same three technologies there.

---

## Citing

Citation details will be added once the paper is published.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgments

Schematic drawn in KiCad. The authors thank Siddharth Jawahar, Application Engineer at MathWorks, for his guidance on the Simulink model.
