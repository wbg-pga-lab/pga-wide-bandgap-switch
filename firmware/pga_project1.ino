// ============================================================
//  Nine-state programmable gain amplifier: Si, GaN and SiC switches
//  Arduino Uno R3, MCP6004 op-amp, ADS1115 16-bit ADC, 16x2 LCD
// ============================================================
//
//  What this sketch does
//   A push button steps through states 0 to 9. On each press the
//   sketch turns every switch branch off, turns the selected branch
//   on, waits 50 ms for the amplifier to settle, reads the output
//   with the ADS1115 and shows it on the LCD and the serial monitor.
//   State 0 means all branches are off.
//
//  Gain tiers (gain = 1 + Rf / Ri, Rf = 100 kOhm nominal)
//   Low  tier: Ri = 100 kOhm             gain 2.00   pins Si 12, GaN 11, SiC 10
//   Mid  tier: Ri = 22 k + 2.2 kOhm      gain 5.13   pins Si 9,  GaN 8,  SiC 7
//   High tier: Ri = 10 k + 680 Ohm       gain 10.36  pins Si 6,  GaN 5,  SiC 4
//
//  Gate drive
//   Si branches are driven directly from the Arduino at 5 V:
//     HIGH = switch on, LOW = switch off.
//   GaN and SiC branches need higher gate voltages (10 V and 20 V
//   from a bench supply), so each gate is pulled up to its rail by a
//   10 kOhm resistor and pulled down by a 2N7000 level shifter that
//   the Arduino controls. This inverts the logic:
//     LOW  = 2N7000 off, pull-up charges the gate, switch on
//     HIGH = 2N7000 on, gate pulled to ground, switch off
//
//  Wiring
//   Button  : pin 3 (INPUT_PULLUP, other leg to GND)
//   LCD     : RS=A0, EN=A1, D4=A2, D5=A3, D6=pin 2, D7=pin 13
//   ADS1115 : VCC=5V, GND=GND, SCL=A5, SDA=A4, channel A0 = MCP6004 pin 1
//   MCP6004 : pin 4 = VDD (5 V), pin 11 = VSS (GND),
//             section A used: pin 1 output, pin 2 inverting input,
//             pin 3 non-inverting input
//
//  States
//   0 all off
//   1 Si Low    2 GaN Low    3 SiC Low     (about 0.97 V out)
//   4 Si Mid    5 GaN Mid    6 SiC Mid     (about 2.48 V out)
//   7 Si High   8 GaN High   9 SiC High    (about 4.96 V out)
//   Output values are for the measured 0.485 V input.
// ============================================================

#include <LiquidCrystal.h>
#include <Wire.h>
#include <Adafruit_ADS1X15.h>

// --- Gate pins ---
#define SI_LOW_PIN    12
#define GAN_LOW_PIN   11
#define SIC_LOW_PIN   10

#define SI_MID_PIN    9
#define GAN_MID_PIN   8
#define SIC_MID_PIN   7

#define SI_HIGH_PIN   6
#define GAN_HIGH_PIN  5
#define SIC_HIGH_PIN  4

// --- Button ---
#define BUTTON_PIN    3

// --- LCD: RS, EN, D4, D5, D6, D7 ---
LiquidCrystal lcd(A0, A1, A2, A3, 2, 13);

// --- ADS1115 ---
Adafruit_ADS1115 ads;
// GAIN_TWOTHIRDS = +/-6.144 V input range. Required because the High
// tier output approaches 5 V, which exceeds the +/-4.096 V range of
// GAIN_ONE and would clip.
#define ADS_GAIN GAIN_TWOTHIRDS

// --- Pin lookup (index 0 = state 1) ---
const int FET_PINS[9] = {
  SI_LOW_PIN,  GAN_LOW_PIN,  SIC_LOW_PIN,   // states 1-3
  SI_MID_PIN,  GAN_MID_PIN,  SIC_MID_PIN,   // states 4-6
  SI_HIGH_PIN, GAN_HIGH_PIN, SIC_HIGH_PIN   // states 7-9
};

// --- Polarity per branch: true = normal (HIGH=on), false = inverted (LOW=on) ---
const bool NORMAL_LOGIC[9] = {
  true,  false, false,   // Si, GaN, SiC , low branch
  true,  false, false,   // Si, GaN, SiC , mid branch
  true,  false, false    // Si, GaN, SiC , high branch
};

const char* LCD_LINE1[10] = {
  "   PGA READY    ",
  "Si  Low   100k  ",
  "GaN Low   100k  ",
  "SiC Low   100k  ",
  "Si  Mid  24.2k  ",
  "GaN Mid  24.2k  ",
  "SiC Mid  24.2k  ",
  "Si  High 10.68k ",
  "GaN High 10.68k ",
  "SiC High 10.68k "
};

int gain_state = 0;
bool last_button = HIGH;

// Turn every branch off, respecting each branch's own "off" logic level
void allFetsOff() {
  for (int i = 0; i < 9; i++) {
    if (NORMAL_LOGIC[i]) {
      digitalWrite(FET_PINS[i], LOW);   // Si: LOW = off
    } else {
      digitalWrite(FET_PINS[i], HIGH);  // GaN/SiC driver: HIGH = 2N7000 on = FET off
    }
  }
}

void setBranchOn(int index) {
  if (NORMAL_LOGIC[index]) {
    digitalWrite(FET_PINS[index], HIGH);  // Si: HIGH = on
  } else {
    digitalWrite(FET_PINS[index], LOW);   // GaN/SiC driver: LOW = 2N7000 off = FET on
  }
}

void updateLCD(int state, float vout) {
  lcd.setCursor(0, 0);
  lcd.print(LCD_LINE1[state]);

  lcd.setCursor(0, 1);
  lcd.print("St:");
  lcd.print(state);
  lcd.print(" Vout:");
  lcd.print(vout, 3);
  lcd.print("V   ");
}

float readVout() {
  int16_t raw = ads.readADC_SingleEnded(0);
  return ads.computeVolts(raw);
}

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < 9; i++) {
    pinMode(FET_PINS[i], OUTPUT);
  }
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  allFetsOff();
  lcd.begin(16, 2);
  lcd.clear();

  if (!ads.begin()) {
    Serial.println("ADS1115 not found, check wiring");
    while (1);
  }
  ads.setGain(ADS_GAIN);

  float v0 = readVout();
  updateLCD(0, v0);
  Serial.println("Setup done, state 0");
}

void loop() {
  bool current_button = digitalRead(BUTTON_PIN);

  if (current_button == LOW && last_button == HIGH) {
    delay(20);
    if (digitalRead(BUTTON_PIN) == LOW) {
      gain_state++;
      if (gain_state >= 10) gain_state = 0;

      allFetsOff();
      if (gain_state > 0) {
        setBranchOn(gain_state - 1);
      }

      delay(50);  // let FET/op-amp settle before reading
      float vout = readVout();
      updateLCD(gain_state, vout);

      Serial.print("STATE: ");
      Serial.print(gain_state);
      Serial.print("  Vout: ");
      Serial.print(vout, 4);
      Serial.println(" V");
    }
  }

  last_button = current_button;
}