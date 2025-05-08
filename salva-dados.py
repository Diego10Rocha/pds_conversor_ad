import serial
import time

# Parâmetros da serial
porta_serial = 'COM5'   # ⚠️ Altere para a porta correta do seu Arduino
baud_rate = 115200     # Igual ao definido no Serial.begin()

arquivo_saida = "dados_adc.txt"
quantidade_amostras = 2048

# Abre a serial
ser = serial.Serial(porta_serial, baud_rate)
time.sleep(2)  # Aguarda o Arduino resetar

print("Lendo dados...")

dados = []
while len(dados) < quantidade_amostras:
    linha = ser.readline().decode('utf-8').strip()
    print(linha)
    if linha.isdigit():
        dados.append(linha)

# Salva no arquivo
with open(arquivo_saida, "w") as f:
    for valor in dados:
        f.write(valor + "\n")

print(f"Coleta concluída. {len(dados)} amostras salvas em '{arquivo_saida}'.")
ser.close()
