%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TEC513-MI de PDS-UEFS 2025.1
%Problema 02
%Arquivo para teste na recepção de dados pela USB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% LIMPA E FECHA TUDO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;							%limpa a tela do octave
clear;				%limpa todas as variáveis do octave
close all;				%fecha todas as janelas

%%%%%%%%%%%%%%%%%%% CHAMADA DAS BIBLIOTECAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pkg load signal					%biblioteca para processamento de sinais
pkg load instrument-control		%biblioteca para comunicação serial

%%%%%%%%%%%%%%%%%%% ALOCAÇÃO DE VARIÁVEIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PORT = "COM9";
BAUD_RATE = 115200;
MAX_RESULTS = 2048;
fs = 10320;    % Aqui ajusta a frequência de amostragem usada no processo na ADC
amostras = 2048;  % Quantidade a amostras que irá usar para visualizar na tela
raw = [];				 % variavel para armazenar os dados cru recebido pela USB (raw)

%%%%%%%%%%%%%%%%%%% ABERTURA DA PORTA SERIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s1 = serial(PORT); 	    		%Abre a porta serial que esta no microcontrolador
set(s1,'baudrate', BAUD_RATE);		%velocidade de transmissão 2Mbps
set(s1,'bytesize', 8); 			  %8 bits de dados
set(s1,'parity', 'n'); 			  %sem paridade ('y' 'n')
set(s1,'stopbits', 1); 			  %1 bit de parada (1 ou 2)
set(s1,'timeout', 20);			  %tempo ocioso sem conecção 20.0 segundos
srl_flush(s1);
pause(1);				          		%espera 1 segundo antes de ler dado

%%%%%%%%%%%%%%%%%%% LEITURA DA MENSAGEM INICIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i = 1;							%primeiro índice de leitura
while(1)						%espera para ler a mensagem inicial
  [tmp, ~] = fread(s1, 1);
  display(tmp);
  if(isempty(tmp))
    break;
  endif
	% t(i) = fread(s1,1);			%le as amostras de uma em uma
  t(i) = tmp;
	if (t(i)==10)				%se for lido um enter (10 em ASC2)
		break;					%sai do loop
	endif
	i = i+1;					%incrementa o índice de leitura
end
c = char(t); 					%transformando caracteres recebidos em string
printf('recebido: %c', c);		%imprime na tela do octave o que foi recebido

pause();

%%%%%%%%%%%%%%%%%%% CAPTURA DAS AMOSTRAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1);						%cria uma figura
tic;							    %captura do tempo inicial
	data = fread(s1,amostras,'uint8');	%captura das amostras
  raw = cat(2,raw,data);			  %armazena o dado bruto (raw = sem processamento)
  x=char(raw);                  %converte em carateres os dados recebidos
  d=str2num(x);                 %string de carateres em números
  x=double(d);                  %os números inteiros em double se necessário paras a próximas etapas
  time=[(0:1:length(d)-1)/fs];  %tamanhos do dominio normalizado

  subplot(3,1,1);           %plotando as figuras
  plot(time,d*5/1023)   %plota as amostras interpoladas
  xlabel('t(s)');
  title('Sinal gerado x(t)');
  subplot(3,1,2);
  stem(d);		          %plota a janela de amostras
  xlabel('n');
  title('x[n]');
  subplot(3,1,3);
  stairs(d);	        	%plota a janela de amostras reguradas
  xlabel('n');
  title('x[n] segurado');
	hold on;							%mantem as amostras anteriores
toc;							  %captura do tempo final

%%%%%%%%%%%%%%%%%%% FECHA A PORTA DE COMUNICAÇÃO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fclose(s1);
