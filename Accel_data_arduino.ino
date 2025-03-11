#include <SPI.h>

#define CS_PIN 10  // Chip Select pin for ADXL375
#define SAMPLE_RATE 3200 // Hz
#define BUFFER_SIZE 16000  // Number of samples

int16_t x_offset = 0, y_offset = 0, z_offset = 0;
float data[BUFFER_SIZE][4]; // Array to store index, X, Y, Z
int sampleIndex = 0;
bool samplingComplete = false;
bool startSampling = false;
unsigned long startTime, endTime;

void writeRegister(byte reg, byte value) {
  digitalWrite(CS_PIN, LOW);
  SPI.transfer(reg);
  SPI.transfer(value);
  digitalWrite(CS_PIN, HIGH);
}

byte readRegister(byte reg) {
  digitalWrite(CS_PIN, LOW);
  SPI.transfer(reg | 0x80);  // Read operation
  byte value = SPI.transfer(0x00);
  digitalWrite(CS_PIN, HIGH);
  return value;
}

void readAccelerometer(int16_t &x, int16_t &y, int16_t &z) {
  digitalWrite(CS_PIN, LOW);
  SPI.transfer(0x32 | 0xC0);  // Burst read starting at DATAX0
  x = SPI.transfer(0x00) | (SPI.transfer(0x00) << 8);
  y = SPI.transfer(0x00) | (SPI.transfer(0x00) << 8);
  z = SPI.transfer(0x00) | (SPI.transfer(0x00) << 8);
  digitalWrite(CS_PIN, HIGH);
}

void calibrateSensor() {
  long x_sum = 0, y_sum = 0, z_sum = 0;
  const int numSamples = 100;

  Serial.println("Calibrating... Keep sensor still.");
  delay(1000);

  for (int i = 0; i < numSamples; i++) {
    int16_t x, y, z;
    readAccelerometer(x, y, z);
    x_sum += x;
    y_sum += y;
    z_sum += z;
    delay(10);
  }

  x_offset = x_sum / numSamples;
  y_offset = y_sum / numSamples;
  z_offset = (z_sum / numSamples) - 20;

  Serial.println("Calibration complete.");
}

void countdown() {
  Serial.println("Starting in...");
  for (int i = 3; i > 0; i--) {
    Serial.print(i);
    Serial.println("...");
    delay(1000);
  }
  Serial.println("Sampling started...");
}

void setup() {
  Serial.begin(230400);
  while (!Serial) { /* Wait for Serial Monitor */ }

  SPI.begin();
  pinMode(CS_PIN, OUTPUT);
  digitalWrite(CS_PIN, HIGH);
  delay(10);

  SPI.beginTransaction(SPISettings(8000000, MSBFIRST, SPI_MODE3)); // Increased to 8MHz for Teensy

  byte deviceID = readRegister(0x00);
  if (deviceID != 0xE5) {
    Serial.println("Error: ADXL375 not detected!");
    while (1);
  }

  writeRegister(0x2C, 0x0F); // 3200Hz data rate
  writeRegister(0x31, 0x0B); // Full resolution, ±200g
  writeRegister(0x2D, 0x08); // Enable measurements

  SPI.endTransaction();

  calibrateSensor();
  Serial.println("Type 'S' to start sampling or 'C' to recalibrate.");
}

void loop() {
  if (Serial.available() > 0) {
    char command = Serial.read();

    if (command == 'S' && !startSampling) {
      countdown();
      startSampling = true;
      sampleIndex = 0;
      samplingComplete = false;
      startTime = millis();
    }

    if (command == 'C') {
      calibrateSensor();
    }
  }

  if (startSampling && !samplingComplete) {
    int16_t x, y, z;
    readAccelerometer(x, y, z);

    x -= x_offset;
    y -= y_offset;
    z -= z_offset;

    data[sampleIndex][0] = sampleIndex;
    data[sampleIndex][1] = x * 0.049;
    data[sampleIndex][2] = y * 0.049;
    data[sampleIndex][3] = z * 0.049;

    sampleIndex++;
    if (sampleIndex >= BUFFER_SIZE) {
      samplingComplete = true;
      endTime = millis();
      startSampling = false;
    }
    delayMicroseconds(312); // Approximate delay for 3200Hz sampling
  }

  if (samplingComplete) {
    Serial.println("Sampling complete. Data:");
    for (int i = 0; i < BUFFER_SIZE; i++) {
      Serial.print((int)data[i][0]); Serial.print(",");
      Serial.print(data[i][1]); Serial.print(",");
      Serial.print(data[i][2]); Serial.print(",");
      Serial.println(data[i][3]);
    }
    Serial.print("Time taken: ");
    Serial.print(endTime - startTime);
    Serial.println(" ms");
    Serial.println("Type 'S' to start another sampling.");
    samplingComplete = false;
  }
}
