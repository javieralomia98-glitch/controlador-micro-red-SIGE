%% CONTROLADOR SIGE: Sistema Inteligente de Gestion Energetica.
% controlador de una micro-red regional durante 24 horas.
% Estudiante: Junior Javier Alomia Rivera
% Curso: sofware para ingenieria - UNAD

clc;                  % limpia la ventana de comandos
clear;                % elimina las variables  almacenadas
close all;            % cierra las ventanas de las graficas

%% DATOS DEL RETO 2

%% Generacion solar (kW)
% La produccion solar es cero durante la noche.
% El pico maximo de 25 kW se alcanza a las 12:00.
% se crea un vector fila de 24 elementos.
generacion_solar = [ ...
    0 0 0 0 0 ...       % Horas 1 a 5
    3 6 10 15 20 24 ... % Horas 6 a 11
    25 ...               % Hora 12: pico solar
    24 20 15 10 6 3 ... % Horas 13 a 18
    0 0 0 0 0 0];        % Horas 19 a 24

%% Generacion eolica de 4 aerogeneradores (kW)
% Se simulan variaciones irregulares del viento.
% La potencia total no supera los 15 kW.

generacion_eolica = [ ...
    8 10 7 12 9 6 ...
    11 13 8 10 14 9 ...
    12 7 11 15 10 8 ...
    13 9 6 12 10 7];

%% Generacion hibrida total (kW)
% Se suman los vectores solar y eolico.
% Cada posicion representa la misma hora del dia.

generacion_total = generacion_solar + generacion_eolica;

%% Demanda electrica de la comunidad (kW)
% Horas 1 a 5 y 22 a 24: consumo nocturno entre 2 y 4 kW.
% Horas 6 a 17: consumo diurno entre 6 y 10 kW.
% Horas 18 a 21: pico de demanda de 15 kW.

demanda_comunidad = [ ...
    3 2 4 3 2 ...        % Horas 1 a 5
    6 7 8 9 8 10 9 8 ... % Horas 6 a 13
    7 8 9 10 ...         % Horas 14 a 17
    15 15 15 15 ...      % Horas 18 a 21
    4 3 2];              % Horas 22 a 24

%% CONFIGURACION DE LA BATERIA

% Capacidad total de la bateria
capacidad_bateria = 100;       % kWh

% Estado inicial de carga
SOC = 50;                      % %

% Limites de seguridad
SOC_max = 100;                 % %
SOC_min = 0;                   % %

% Vector para almacenar el SOC de cada hora
SOC_hora = zeros(1,24);

% Vector para almacenar el balance energetico
balance_hora = zeros(1,24);

%% VECTORES PARA REGISTRAR EL ESTADO DE LAS CARGAS

estado_escuela = strings(1,24);
estado_bombeo = strings(1,24);
estado_alumbrado = strings(1,24);

% Vector para identificar si existe superavit o deficit
estado_energia = strings(1,24);

%% SIMULACION DE LAS 24 HORAS

for h = 1:24

    % Obtener generacion y demanda de la hora actual

    Egen = generacion_total(h);
    Edem = demanda_comunidad(h);


    % Calcular balance energetico

    balance = Egen - Edem;

    balance_hora(h) = balance;



    % ESCENARIO 1: SUPERAVIT
    % Egen >= Edem

    if Egen >= Edem

        % Existe energia sobrante
        excedente = Egen - Edem;

        % Convertir el excedente de kWh a porcentaje de SOC
        aumento_SOC = (excedente / capacidad_bateria) * 100;

        % Cargar la bateria
        SOC = SOC + aumento_SOC;

        % Evitar superar el 100 %
        if SOC > SOC_max
            SOC = SOC_max;
        end

        % Todos los servicios permanecen activos
        estado_escuela(h) = "ACTIVA";
        estado_bombeo(h) = "ACTIVO";
        estado_alumbrado(h) = "ACTIVO";

        estado_energia(h) = "SUPERAVIT";


    % ESCENARIO 2: DEFICIT
    % Egen < Edem

    else

        % Existe energia faltante
        faltante = Edem - Egen;

        % Convertir el faltante de kWh a porcentaje de SOC
        disminucion_SOC = (faltante / capacidad_bateria) * 100;

        % Descargar la bateria
        SOC = SOC - disminucion_SOC;

        % Evitar que la bateria quede por debajo de 0 %
        if SOC < SOC_min
            SOC = SOC_min;
        end

        estado_energia(h) = "DEFICIT";


        % CONTROL DE CARGAS SEGUN EL NIVEL DE SOC

        % RUTA SEGURA
        % SOC > 40 %

        if SOC > 40

            estado_escuela(h) = "ACTIVA";
            estado_bombeo(h) = "ACTIVO";
            estado_alumbrado(h) = "ACTIVO";


        % RUTA DE ALERTA
        % 20 % < SOC <= 40 %

        elseif SOC > 20

            estado_escuela(h) = "ACTIVA";
            estado_bombeo(h) = "ACTIVO";
            estado_alumbrado(h) = "DESCONECTADO";


        % RUTA DE EMERGENCIA
        % SOC <= 20 %

        else

            estado_escuela(h) = "ACTIVA";
            estado_bombeo(h) = "DESCONECTADO";
            estado_alumbrado(h) = "DESCONECTADO";

        end

    end


    % GUARDAR EL SOC DE LA HORA

    SOC_hora(h) = SOC;


    %% REPORTE EN LA CONSOLA DE MATLAB

    fprintf('\n=============================================\n');
    fprintf('             HORA %02d\n', h);
    fprintf('=============================================\n');

    fprintf('Generacion solar   : %.2f kW\n', ...
        generacion_solar(h));

    fprintf('Generacion eolica  : %.2f kW\n', ...
        generacion_eolica(h));

    fprintf('Generacion total   : %.2f kW\n', ...
        Egen);

    fprintf('Demanda comunidad  : %.2f kW\n', ...
        Edem);

    fprintf('Balance energetico : %.2f kW\n', ...
        balance);

    fprintf('Estado energetico  : %s\n', ...
        estado_energia(h));

    fprintf('SOC bateria        : %.2f %%\n', ...
        SOC);

    fprintf('Escuela            : %s\n', ...
        estado_escuela(h));

    fprintf('Bombeo             : %s\n', ...
        estado_bombeo(h));

    fprintf('Alumbrado          : %s\n', ...
        estado_alumbrado(h));

end


%% CREAR TABLA FINAL DE RESULTADOS

Hora = (1:24)';

Resultados = table( ...
    Hora, ...
    generacion_solar', ...
    generacion_eolica', ...
    generacion_total', ...
    demanda_comunidad', ...
    balance_hora', ...
    SOC_hora', ...
    estado_energia', ...
    estado_escuela', ...
    estado_bombeo', ...
    estado_alumbrado', ...
    'VariableNames', { ...
    'Hora', ...
    'Solar_kW', ...
    'Eolica_kW', ...
    'GeneracionTotal_kW', ...
    'Demanda_kW', ...
    'Balance_kW', ...
    'SOC_porcentaje', ...
    'EstadoEnergia', ...
    'Escuela', ...
    'Bombeo', ...
    'Alumbrado'});


%% MOSTRAR TABLA FINAL

disp(' ');
disp('==========================================================');
disp('             RESULTADOS DE LA SIMULACION');
disp('==========================================================');

disp(Resultados);


%% GRAFICA DE GENERACION Y DEMANDA

figure;

plot(Hora, generacion_solar, '-o');
hold on;

plot(Hora, generacion_eolica, '-o');

plot(Hora, generacion_total, '-o');

plot(Hora, demanda_comunidad, '-o');

grid on;

xlabel('Hora del dia');
ylabel('Potencia (kW)');

title('Generacion y demanda de la microred');

legend('Generacion solar', ...
       'Generacion eolica', ...
       'Generacion hibrida total', ...
       'Demanda de la comunidad', ...
       'Location', 'best');

hold off;


%% GRAFICA DEL ESTADO DE CARGA DE LA BATERIA

figure;

plot(Hora, SOC_hora, '-o');

hold on;

yline(40, '--');
yline(20, '--');

grid on;

xlabel('Hora del dia');
ylabel('Estado de carga SOC (%)');

title('Estado de carga de la bateria durante 24 horas');

legend('SOC de la bateria', ...
       'Limite de 40 %', ...
       'Limite de 20 %', ...
       'Location', 'best');

hold off;


%% MENSAJE FINAL

fprintf('\n\n=============================================\n');
fprintf('      SIMULACION FINALIZADA CORRECTAMENTE\n');
fprintf('=============================================\n');
fprintf('SOC inicial de la bateria: 50 %%\n');
fprintf('SOC final de la bateria  : %.2f %%\n', SOC);
fprintf('Capacidad de bateria     : %.2f kWh\n', ...
        capacidad_bateria);
fprintf('=============================================\n');