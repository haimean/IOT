#include <Arduino_FreeRTOS.h>
#include <LiquidCrystal.h> // includes the LiquidCrystal Library
#include <Keypad.h>

// Khai báo nhiệm vụ:
void TaskBlink(void *pvParameters);
void TaskAnalogRead(void *pvParameters);

#define buzzer 4
#define trigPin 3
#define echoPin 2

long duration;
int distance, initialDistance, currentDistance, i;
int screenOffMsg = 0;
String password = "1234";
String tempPassword;
// boolean activated = false; // State of the alarm
boolean isActivated;
boolean activateAlarm = false;
boolean alarmActivated = false;
boolean enteredPassword; // State of the entered password to stop the alarm
boolean passChangeMode = false;
boolean passChanged = false;
boolean inputPass = false;
const byte ROWS = 4; // four rows
const byte COLS = 4; // four columns
char keypressed;
// define the cymbols on the buttons of the keypads
char keyMap[ROWS][COLS] = {
    {'1', '2', '3', 'A'},
    {'4', '5', '6', 'B'},
    {'7', '8', '9', 'C'},
    {'*', '0', '#', 'D'}};
byte rowPins[ROWS] = {8, 7, 6, 5};     // Row pinouts of the keypad
byte colPins[COLS] = {A3, A2, A1, A0}; // Column pinouts of the keypad

Keypad myKeypad = Keypad(makeKeymap(keyMap), rowPins, colPins, ROWS, COLS);
LiquidCrystal lcd(0, 1, 9, 10, 11, 12); // Creates an LC object. Parameters: (rs, enable, d4, d5, d6, d7)

// the setup function runs once when you press reset or power the board
void setup()
{

  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
  while (!Serial)
  {
    ; // wait for serial port to connect. Needed for native USB, on LEONARDO, MICRO, YUN, and other 32u4 based boards.
  }
  // Thiết lập nhiệm vụ để chạy độc lập
  xTaskCreate(
      TaskBlink, (const portCHAR *)"Blink" // A name just for humans
      ,
      128 // Bộ nhớ RAM để cho tiến trình hoạt động >= 64byte
      ,
      NULL, 1 // Mức độ ưu tiên
      ,
      NULL);

  xTaskCreate(
      TaskAnalogRead, "AnalogRead", 128 // Stack size
      ,
      NULL, 2 // Priority
      ,
      NULL);

  // Now the task scheduler, which takes over control of scheduling individual tasks, is automatically started.
}

void loop()
{
  // Chương trình chính đã được thực hiện trong các Task nên loop() trống
}

/*--------------------------------------------------*/
/*---------------------- Tasks ---------------------*/
/*--------------------------------------------------*/

void TaskBlink(void *pvParameters) // This is a task.
{
  (void)pvParameters;
  // Code được đặt ở đây sẽ chạy 1 lần giống void setup()
  for (;;)
  {
    if (inputPass == true && alarmActivated == true)
    {
      if (checkNguoi())
      {
        for (size_t i = 10; i < count; i++)
        {
          delay(1000);
          if (checkNguoi())
          {
            continue;
          }
          else
          {
            break;
          }
        }
        inputPass = false;
        coTrom();
      }
      if (!checkNguoi() && alarmActivated == true)
      {
        for (size_t i = 3; i < count; i++)
        {
          delay(1000);
          if (checkNguoi())
          {
            continue;
          }
          else
          {
            break;
          }
        }
        inputPass = false;
        chongTrom();
      }
    }
  }
}
void TaskAnalogRead(void *pvParameters) // This is a task.
{
  (void)pvParameters;
  lcd.begin(16, 2);
  pinMode(buzzer, OUTPUT);  // Set buzzer as an output
  pinMode(trigPin, OUTPUT); // Sets the trigPin as an Output
  pinMode(echoPin, INPUT);  // Sets the echoPin as an Input
  for (;;)
  {

    if (activateAlarm)
    {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Alert will be");
      lcd.setCursor(0, 1);
      lcd.print("activated in");

      int countdown = 3; // 9 seconds count down before activating the alarm
      while (countdown != 0)
      {
        tone(buzzer, 700, 100);

        lcd.setCursor(13, 1);
        lcd.print(countdown);
        countdown--;
        delay(1000);
      }
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Alarm Activated!");
      initialDistance = getDistance();
      activateAlarm = false;
      alarmActivated = true;
    }

    if (alarmActivated == true)
    {
      currentDistance = getDistance() + 10;
      // if (currentDistance < initialDistance)
      if (checkNguoi(currentDistance, initialDistance))
      {
        inputPass = true;
        lcd.clear();
        enterPassword();
      }
    }
    if (!alarmActivated)
    {
      home();
    }
  }
}

void enterPassword()
{
  int k = 5;
  tempPassword = "";
  inputPass = true;
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(" *** ALARM *** ");
  lcd.setCursor(0, 1);
  lcd.print("Pass>");
  for (size_t i = 0; i < 3; i++)
  {
    keypressed = myKeypad.getKey();
    if (keypressed != NO_KEY)
    {
      if (keypressed == '0' || keypressed == '1' || keypressed == '2' || keypressed == '3' ||
          keypressed == '4' || keypressed == '5' || keypressed == '6' || keypressed == '7' ||
          keypressed == '8' || keypressed == '9')
      {
        tempPassword += keypressed;
        lcd.setCursor(k, 1);
        lcd.print("*");
        k++;
      }
    }
    if (k > 9 || keypressed == '#')
    {
      tempPassword = "";
      k = 5;
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print(" *** ALARM *** ");
      lcd.setCursor(0, 1);
      lcd.print("Pass>");
    }
    if (keypressed == '*')
    {

      if (tempPassword == password)
      {
        inputPass = false;
        alarmActivated = false;
        noTone(buzzer);
        screenOffMsg = 0;
        inputPass = false;
      }
      else
        (tempPassword != password)
        {
          lcd.setCursor(0, 1);
          lcd.print("Wrong! Try Again");
          delay(2000);
          lcd.clear();
        }
    }
  }
}
// Custom function for the Ultrasonic sensor
long getDistance()
{
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;
  return distance;
}
bool checkNguoi(int currentDistance, int initialDistance)
{
  if (currentDistance < initialDistance)
  {
    return true;
  }
  else
  {
    return false;
  }
}
void coTrom()
{
  tone(buzzer, 1000); // loa kêu
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Trom Trom Trom ");
}
void home()
{
  if (screenOffMsg == 0)
  {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("A - Activate");
    lcd.setCursor(0, 1);
    lcd.print("B - Change Pass");
    screenOffMsg = 1;
  }
  keypressed = myKeypad.getKey();
  if (keypressed == 'A')
  { // If A is pressed, activate the alarm
    tone(buzzer, 1000, 200);
    activateAlarm = true;
  }
  else if (keypressed == 'B')
  {
    lcd.clear();
    int i = 1;
    tone(buzzer, 2000, 100);
    tempPassword = "";
    lcd.setCursor(0, 0);
    lcd.print("Current Password");
    lcd.setCursor(0, 1);
    lcd.print(">");
    passChangeMode = true;
    passChanged = true;
    while (passChanged)
    {
      keypressed = myKeypad.getKey();
      if (keypressed != NO_KEY)
      {
        if (keypressed == '0' || keypressed == '1' || keypressed == '2' || keypressed == '3' ||
            keypressed == '4' || keypressed == '5' || keypressed == '6' || keypressed == '7' ||
            keypressed == '8' || keypressed == '9')
        {
          tempPassword += keypressed;
          lcd.setCursor(i, 1);
          lcd.print("*");
          i++;
          tone(buzzer, 2000, 100);
        }
      }
      if (i > 5 || keypressed == '#')
      {
        tempPassword = "";
        i = 1;
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Current Password");
        lcd.setCursor(0, 1);
        lcd.print(">");
      }
      if (keypressed == '*')
      {
        i = 1;
        tone(buzzer, 2000, 100);
        if (password == tempPassword)
        {
          tempPassword = "";
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Set New Password");
          lcd.setCursor(0, 1);
          lcd.print(">");
          while (passChangeMode)
          {
            keypressed = myKeypad.getKey();
            if (keypressed != NO_KEY)
            {
              if (keypressed == '0' || keypressed == '1' || keypressed == '2' || keypressed == '3' ||
                  keypressed == '4' || keypressed == '5' || keypressed == '6' || keypressed == '7' ||
                  keypressed == '8' || keypressed == '9')
              {
                tempPassword += keypressed;
                lcd.setCursor(i, 1);
                lcd.print("*");
                i++;
                tone(buzzer, 2000, 100);
              }
            }
            if (i > 5 || keypressed == '#')
            {
              tempPassword = "";
              i = 1;
              tone(buzzer, 2000, 100);
              lcd.clear();
              lcd.setCursor(0, 0);
              lcd.print("Set New Password");
              lcd.setCursor(0, 1);
              lcd.print(">");
            }
            if (keypressed == '*')
            {
              i = 1;
              tone(buzzer, 2000, 100);
              password = tempPassword;
              passChangeMode = false;
              passChanged = false;
              screenOffMsg = 0;
            }
          }
        }
      }
    }
  }
}
void chongTrom()
{
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Alert will be");
  lcd.setCursor(0, 1);
  lcd.print("activated in");

  int countdown = 3; // 9 seconds count down before activating the alarm
  while (countdown != 0)
  {
    tone(buzzer, 700, 100);

    lcd.setCursor(13, 1);
    lcd.print(countdown);
    countdown--;
    delay(1000);
  }
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Alarm Activated!");
  initialDistance = getDistance();
  activateAlarm = false;
  alarmActivated = true;
}