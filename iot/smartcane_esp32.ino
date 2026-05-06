// SmartCane ESP32 Code
// Handles SOS (D12) and HELP (D13) buttons
// Sends events over Serial to the Python bridge

const int pinSOS = 12;
const int pinHELP = 13;

void setup() {
  Serial.begin(115200);
  
  // Use INPUT_PULLUP to avoid external resistors
  // Wire the button between the PIN and GND
  pinMode(pinSOS, INPUT_PULLUP);
  pinMode(pinHELP, INPUT_PULLUP);
  
  Serial.println("SmartCane ESP32 Initialized.");
  Serial.println("Listening for buttons on D12 (SOS) and D13 (HELP)...");
}

void loop() {
  // Read buttons (LOW means pressed because of INPUT_PULLUP)
  if (digitalRead(pinSOS) == LOW) {
    sendEvent("SOS");
    delay(1000); // Debounce and prevent flood
  }
  
  if (digitalRead(pinHELP) == LOW) {
    sendEvent("HELP");
    delay(1000); // Debounce and prevent flood
  }
  
  delay(10); // Small stability delay
}

void sendEvent(String type) {
  // Format: EVENT:TYPE:LAT:LNG:STATUS
  // For prototype, we use hardcoded GPS if sensor is not present
  String lat = "36.8065"; 
  String lng = "10.1815";
  String status = (type == "SOS") ? "SOS_ACTIVE" : "WAITING";
  
  Serial.print("EVENT:");
  Serial.print(type);
  Serial.print(":");
  Serial.print(lat);
  Serial.print(":");
  Serial.print(lng);
  Serial.print(":");
  Serial.println(status);
  
  // Visual feedback
  Serial.println("DEBUG: Alert sent via Serial.");
}
