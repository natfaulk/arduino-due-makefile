#include <Arduino.h>

void setup(void)
{
  Serial.begin(115200);
  Serial.println("hello world!");

  pinMode(13, OUTPUT);
  digitalWrite(13, 1);
}

void loop(void)
{
  digitalWrite(13, 0);
  delay(50);
  digitalWrite(13, 1);
  delay(50);
}
