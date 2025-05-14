// const int MAX_RESULTS = 2048;       // size for store data to be sent
const int MAX_RESULTS = 3000;       // size for store data to be sent
static volatile uint16_t results [MAX_RESULTS]; // data vector
static volatile uint16_t resultNumber; 
static volatile bool comecou = false;
static volatile uint16_t aux = 0;


// ADC complete ISR
ISR (ADC_vect)
{
  if((ADC == 0 || comecou) && resultNumber < MAX_RESULTS)
  {
    results[resultNumber++] = ADC;
     comecou = true;
  }
  else
  {
    while(resultNumber--) Serial.println(results[aux++]);
    //comecou = false;
    resultNumber = 0;
    aux = 0;
  }
}

// ADC configure initialization
void adc_init() {
  ADMUX =  0b01000000; //Set Voltage reference to AREF (5v), select ADC0, Right ajdust result
  ADCSRB = 0b00000000;
  DIDR0  = 0b11111110;
  DIDR2  = 0b11111111; // uncoment this in atmega2560
  ADCSRA = 0b11101111;
}

// Setup and run
void setup()
{
  resultNumber = 0;
  adc_init(); // uncoment this in atmega2560
  Serial.begin(1000000);
  sei();
}

void loop () { }
