const int MAX_RESULTS = 2048;       // size for store data to be sent
static volatile uint16_t results [MAX_RESULTS]; // data vector
static volatile uint16_t resultNumber; 
static volatile bool comecou = false;
static volatile uint16_t aux = 0;

ISR(USART_TX_vect)
{
  if(aux < 2048)
  {
    return; // TO DO
  }
}

// ADC complete ISR
ISR (ADC_vect)
{
  if((ADC == 0 || comecou) && resultNumber < 2048)
  {
    results[resultNumber++] = ADC;
     comecou = true;
  }
  else
  {
    while(resultNumber--) Serial.println(results[aux++]);
    comecou = false;
    resultNumber = 0;
    aux = 0;
  }
}

void usart_init()
{
  UCSRB = 0b01001000; // TX enable and TX complete interrupt enable
  UCSRC = 0b00000011; // Asynchronous USART; Parity disabled; 1 Stop-bit; 8bit data size
  UBRR0H = 0x00; // 1M de baud rate; 0% de erro
  UBRR0L = 0x00;
}

void usart_send_byte(uint8_t data)
{
  return; //TO DO
}

// ADC configure initialization
void adc_init() {
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
  //Serial.begin (115200);
  adc_init();
  usart_init();
  sei();
}

void loop () { }
