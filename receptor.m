%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TEC513-MI de PDS-UEFS 2025.1
%Problema 02
% Diego Cerqueira e Carlos Valadão
%Arquivo para teste na captura e conversão do ADC e envio dados pela USB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;                           %limpa a tela do octave
clear all;                     %limpa todas as variáveis do octave
close all;                     %fecha todas as janelas

%%%%%%%%%%%%%%%%%%% CHAMADA DAS BIBLIOTECAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
##pkg load signal                %biblioteca para processamento de sinais
pkg load instrument-control    %biblioteca para comunicação serial

%%%%%%%%%%%%%%%%%%% ALOCAÇÃO DE VARIÁVEIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAX_RESULTS = 3072;            % Mesmo valor definido no Arduino
fs = 10230;                    % Frequência de amostragem do ADC no Arduino
amostras = 3072                % Quantidade de amostras para visualizar
raw = [];                      % Variável para armazenar os dados recebidos pela USB
dados_digitais = [];
dados_digitais_sliced = zeros(1, 200);

% Inicializando variáveis para armazenar DNL e INL
DNL = zeros(1, 200);  % Vetor para armazenar os valores de DNL
INL = zeros(1, 200);  % Vetor para armazenar os valores de INL acumulado

% Definindo os parâmetros
V_ref = 5;          % Tensão de referência (5V)
ADC_bits = 10;      % Resolução do ADC (10 bits)
LSB = 0.0048828125;  % Valor do LSB em V

%%%%%%%%%%%%%%%%%%% ABERTURA DA PORTA SERIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s1 = serial("COM7");           % Porta COM5 conforme solicitado
set(s1, 'baudrate', 1000000);   % Mesma velocidade configurada no Arduino (115200)
set(s1, 'bytesize', 8);        % 8 bits de dados
set(s1, 'parity', 'n');        % Sem paridade ('y' 'n')
set(s1, 'stopbits', 1);        % 1 bit de parada (1 ou 2)
set(s1, 'timeout', 1);         % Tempo ocioso reduzido para 1 segundo
srl_flush(s1);                 % Limpa buffer serial
pause(1);                      % Espera 1 segundo antes de ler dados

fig4 = figure(4);
h4 = axes(fig4);
fig5 = figure(5);
h5 = axes(fig5);
fig6 = figure(6);
h6 = axes(fig6);

%%%%%%%%%%%%%%%%%%% LEITURA DA MENSAGEM INICIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Corrigido: Pré-alocação do array t
t = zeros(1, 100);             % Pré-aloca com tamanho suficiente
i = 1;                         % Primeiro índice de leitura

while(1)                       % Espera para ler a mensagem inicial
    tmp = srl_read(s1, 1);     % Lê um byte
    if (isempty(tmp))          % Verifica se leu algo
        break;
    endif
    t(i) = tmp;                % Armazena o byte
    if (t(i) == 10)            % Se for lido um enter (10 em ASCII)
        break;                 % Sai do loop
    endif
    i = i + 1;                 % Incrementa o índice de leitura
end

t = t(1:i);                    % Ajusta o tamanho final do array
c = char(t);                   % Transformando caracteres recebidos em string
printf('recebido: %s', c);     % Imprime na tela do octave o que foi recebido



data = [];

        % Lê dados disponíveis (até 'amostras' ou até timeout)
        for i = 1:amostras
            % Lê uma linha completa (até encontrar o caractere de nova linha)
            line = '';
            byte = 0;
            try
                % Lê até encontrar nova linha ou timeout
                aux = 0;
                while (byte != 10 && aux < 100)  % ASCII 10 = nova linha
                    tmp = srl_read(s1, 1);
                    if (isempty(tmp))
                        aux++;
                        pause(0.01);     % Pequena pausa para dar tempo ao Arduino
                        continue;
                    endif
                    byte = tmp;
                    if (byte != 10)
                        line = [line, char(byte)];
                    endif
                end

                % Converte a string para número e adiciona ao array de dados
                if (length(line) > 0)
                    num_val = str2num(line);
                    if (!isempty(num_val))
                        data(end+1) = num_val;
                    endif
                endif
            catch
                % Continua se houver erro
                continue;
            end

            % Verifica se já temos amostras suficientes
            if (length(data) >= amostras)
                break;
            endif
        end

         if (length(data) > 0)
            dados_digitais = data;
          endif


dados_digitais_sliced = dados_digitais(15:214);
num_amostras = length(dados_digitais_sliced) - 1;
tensoes_equivalentes = dados_digitais_sliced * LSB;

% Cálculo do DNL
for k = 1:num_amostras
    % Calculando o intervalo real em volts
    delta_x_real = tensoes_equivalentes(k + 1) - tensoes_equivalentes(k);

    % Calculando o DNL (normalizado pelo LSB)
    DNL(k) = (delta_x_real - LSB) / LSB;
end


bar(h4, 1:num_amostras + 1, DNL, 1);  % Adiciona o gráfico aos eixos h4
title(h4, 'Differential Non-Linearity (DNL)');
xlabel(h4, 'Código Digital');
ylabel(h4, 'DNL [LSB]');
grid on;  % Adiciona uma grade ao gráfico
axis tight;  % Ajusta os limites dos eixos para melhor visualização


% Para INL em relação à linha ideal (método end-point)
% Adaptado para as amostras disponíveis
% Cálculo do INL pelo método end-point
% Criando a linha ideal entre o primeiro e o último ponto
% Calculando a linha ideal
primeira_tensao = tensoes_equivalentes(1);
ultima_tensao = tensoes_equivalentes(end);
indices = 1:length(tensoes_equivalentes);
linha_ideal = primeira_tensao + (ultima_tensao - primeira_tensao) * (indices - 1) / (length(indices) - 1);

% Calculando o INL
INL_endpoint = zeros(1, length(tensoes_equivalentes));
for k = 1:length(tensoes_equivalentes)
    INL_endpoint(k) = (tensoes_equivalentes(k) - linha_ideal(k)) / LSB;
end

% Plotando o INL na figura 5, utilizando o handle h5
bar(h5, 1:num_amostras + 1, INL_endpoint, 'LineWidth', 1);  % Adiciona o gráfico aos eixos h5
xlabel(h5, 'Índice da Amostra');
ylabel(h5, 'INL (LSB)');
title(h5, 'Cálculo do INL');
grid on;
axis tight;


missing_codes = [];

for i = 1:199
    missing_codes = [missing_codes, dados_digitais_sliced(i)];
    % O código após o atual terá probabilidade zero de ocorrer
    if(dados_digitais_sliced(i + 1) - dados_digitais_sliced(i) > 1)
      missing_codes = [missing_codes, NaN];
    end
end

fig7 = figure(7);
h = axes(fig7);
stairs(missing_codes);


%%%%%%%%%%%%%%%%%%% CRIAÇÃO DA FIGURA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1);                     % Cria uma figura para plotagem
h1 = subplot(3,1,1);           % Cria o primeiro subplot e guarda o handle
h2 = subplot(3,1,2);           % Cria o segundo subplot e guarda o handle
h3 = subplot(3,1,3);           % Cria o terceiro subplot e guarda o handle

%%%%%%%%%%%%%%%%%%% LOOP PRINCIPAL COM ATUALIZAÇÃO A CADA SEGUNDO %%%%%%%%%%%%%
try
    while (1)                   % Loop infinito (até Ctrl+C)
        tic;                    % Inicia contador de tempo

        % Limpa dados anteriores
        data = [];

        % Lê dados disponíveis (até 'amostras' ou até timeout)
        for i = 1:amostras
            % Lê uma linha completa (até encontrar o caractere de nova linha)
            line = '';
            byte = 0;
            try
                % Lê até encontrar nova linha ou timeout
                timeout_count = 0;
                while (byte != 10 && timeout_count < 100)  % ASCII 10 = nova linha
                    tmp = srl_read(s1, 1);
                    if (isempty(tmp))
                        timeout_count++;
                        pause(0.01);     % Pequena pausa para dar tempo ao Arduino
                        continue;
                    endif
                    byte = tmp;
                    if (byte != 10)
                        line = [line, char(byte)];
                    endif
                end

                % Converte a string para número e adiciona ao array de dados
                if (length(line) > 0)
                    num_val = str2num(line);
                    if (!isempty(num_val))
                        data(end+1) = num_val;
                    endif
                endif
            catch
                % Continua se houver erro
                continue;
            end

            % Verifica se já temos amostras suficientes
##            if (length(data) >= amostras)
##                break;
##            endif
        end

        % Se recebeu dados, atualiza os gráficos
        if (length(data) > 0)
            raw = data;                  % Armazena os dados brutos
            time = (0:length(raw)-1)/fs; % Vetor de tempo normalizado (em segundos)

            % Atualiza o primeiro subplot
            subplot(h1);
            plot(time, raw*5/1023);      % Converte os valores ADC para tensão (0-5V)
            xlabel('t(s)');
            ylabel('Tensão (V)');
            title('Sinal gerado x(t)');
            grid on;

            % Atualiza o segundo subplot
            subplot(h2);
            stem(raw,'.');                   % Plota amostras discretas
            xlabel('n');
            ylabel('Valor ADC');
            title('x[n]');
            grid on;

            % Atualiza o terceiro subplot
            subplot(h3);
            stairs(raw);                 % Plota amostras regulares em forma de escada
            xlabel('n');
            ylabel('Valor ADC');
            title('x[n] segurado');
            grid on;

            % Força atualização da figura
            drawnow;
        else
            printf("Nenhum dado recebido nesta iteração\n");
        end

        % Calcula tempo restante para completar 1 segundo
        elapsed = toc;
        if (elapsed < 1)
            pause(1 - elapsed);  % Pausa para completar 1 segundo
        end

        % Exibe a taxa de amostragem atual
        printf('Amostras coletadas: %d, Tempo: %.2f s\n', length(data), elapsed);
    end
catch err
    % Captura exceções (como Ctrl+C)
    printf('Programa interrompido: %s\n', err.message);
end

%%%%%%%%%%%%%%%%%%% FECHA A PORTA DE COMUNICAÇÃO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fclose(s1);
printf('Porta serial fechada.\n');