const int MAX_RESULTS = 2048;       // size for store data to be sent

static volatile uint16_t results [MAX_RESULTS]; // data vector
static volatile uint16_t resultNumber; 
static volatile bool comecou = false;
static volatile uint16_t aux = 0;

// ADC complete ISR
ISR (ADC_vect)
{
  if((ADC == 0 || comecou) && resultNumber < 2048){
    //resultNumber = 0;
    results[resultNumber++] = ADC;
     comecou = true;
  }
  //if(resultNumber == 2048)
  else
  {
    // resultNumber++;
    while(resultNumber--) Serial.println(results[aux++]);
    //ADCSRA = 0x0;
    comecou = false;
    resultNumber = 0;
    aux = 0;
  }
  //if(results[resultNumber] >= ADC)
    //results[resultNumber++] = ADC;
}

// ADC configure initialization
void ADC_init() {
  ADMUX =  0b01000000; //Set Voltage reference to AREF (5v), select ADC0, Right ajdust result
  ADCSRB = 0b00000000;
  DIDR0  = 0b11111110;
  DIDR2  = 0b11111111;
  ADCSRA = 0b11101111;
}

// Setup and run
void setup()
{
  resultNumber = 0;
  Serial.begin (115200);
  sei();
  ADC_init();
}

void loop () { }
