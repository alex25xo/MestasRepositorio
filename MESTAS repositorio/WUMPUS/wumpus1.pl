% --- Ver base de conocimientos
ver_bc :-
    forall(bc((Pos, Per, Cre, Acc, Res)),
        (format('Pos: ~w, Percepciones: ~w, Creencias: ~w, Accion: ~w, Resultado: ~w~n',
            [Pos, Per, Cre, Acc, Res]))).

% --- Resolver con visualización
resolver_visual :-
    mostrar_mundo,
    resolver,
    nl, write('=== RESULTADO FINAL ==='), nl,
    mostrar_mundo,
    mostrar_percepciones,
    ver_bc.

% CONFIGURACIÓN GANADORA - ORO FÁCIL DE ALCANZAR
oro(2,2).
wumpus(3,4).
pozo(4,3).
pozo(1,4).

% --- Reglas del entorno
brisa(X,Y) :- adyacente(X,Y,X1,Y1), pozo(X1,Y1).
hedor(X,Y) :- adyacente(X,Y,X1,Y1), wumpus(X1,Y1).
brillo(X,Y) :- oro(X,Y).

adyacente(X,Y,X1,Y) :- X1 is X+1, X1 =< 4.
adyacente(X,Y,X1,Y) :- X1 is X-1, X1 >= 1.
adyacente(X,Y,X,Y1) :- Y1 is Y+1, Y1 =< 4.
adyacente(X,Y,X,Y1) :- Y1 is Y-1, Y1 >= 1.

% --- Estado del agente
:- dynamic visitado/2, seguro/2, peligroso/2, bc/1.

% --- Resolver e inicializar
resolver :-
    retractall(visitado(_, _)),
    retractall(seguro(_, _)),
    retractall(peligroso(_, _)),
    retractall(bc(_)),
    assert(seguro(1,1)),
    actualizar_bc((1,1), [nada,nada,nada,nada,nada], [seguro(1,1)], iniciar, ok),
    explorar(1,1).

% --- Exploración de una casilla
explorar(X,Y) :-
% Si ya fue visitada, no hacer nada
( visitado(X,Y) ->
true
;
% Si encuentra oro, ganar
( oro(X,Y) ->
assert(visitado(X,Y)),
percibir(X,Y,Percepciones),
write('El agente encontro el oro en ('), write(X), write(','), write(Y), write(')!'), nl,
actualizar_bc((X,Y), Percepciones, [], agarrar, exito)
;
% Si es peligroso, morir
( (pozo(X,Y); wumpus(X,Y)) ->
assert(visitado(X,Y)),
percibir(X,Y,Percepciones),
write('El agente murio en ('), write(X), write(','), write(Y), write(')!'), nl,
actualizar_bc((X,Y), Percepciones, [], mover, muerte)
;
% Si es seguro, explorar
(
assert(visitado(X,Y)),
percibir(X,Y,Percepciones),
deducir_seguridad(X,Y,Creencias),
actualizar_bc((X,Y), Percepciones, Creencias, mover, ok),
explorar_seguro(X,Y)
)))).

% --- Percepción del entorno
percibir(X,Y, [Brisa, Hedor, Brillo, Golpe, Grito]) :-
(brisa(X,Y)  -> Brisa = brisa ; Brisa = nada),
(hedor(X,Y)  -> Hedor = hedor ; Hedor = nada),
(brillo(X,Y) -> Brillo = brillo ; Brillo = nada),

% --- Inferencia lógica sobre seguridad (mejorada)
deducir_seguridad(X,Y, Creencias) :-
findall((X1,Y1), adyacente(X,Y,X1,Y1), Adyacentes),
findall((X1,Y1), (
member((X1,Y1), Adyacentes),
  visitado(X1,Y1),
\+ seguro(X1,Y1),
\+ peligroso(X1,Y1)
), NoConocidas),
(
% Si no hay brisa ni hedor, todas las adyacentes son seguras
(\+ brisa(X,Y), \+ hedor(X,Y)) ->
marcar_seguras(Adyacentes, Creencias)
;
% Si hay peligros pero solo una casilla desconocida, es peligrosa
(length(NoConocidas, 1), (brisa(X,Y); hedor(X,Y))) ->
NoConocidas = [(PX,PY)],
assertz(peligroso(PX,PY)),
% Marcar el resto como seguras si no tienen otros peligros
findall(seguro(X2,Y2), (
member((X2,Y2), Adyacentes),
                X2-Y2 \== PX-PY,
                \+ seguro(X2,Y2),
                assertz(seguro(X2,Y2))
            ), Creencias)
        ;
        % Lógica mas agresiva: si no hay hedor, marcar adyacentes como seguras del wumpus
        (\+ hedor(X,Y)) ->
            findall(seguro(X2,Y2), (
                member((X2,Y2), Adyacentes),
                \+ seguro(X2,Y2),
                \+ brisa_en_vecino(X2,Y2),
                assertz(seguro(X2,Y2))
            ), Creencias)
        ;
            Creencias = []
    ).

% Marcar casillas como seguras
marcar_seguras([], []).
marcar_seguras([(X1,Y1)|Resto], [seguro(X1,Y1)|CreenciasResto]) :-
    \+ seguro(X1,Y1),
    assertz(seguro(X1,Y1)),
    marcar_seguras(Resto, CreenciasResto).
marcar_seguras([(X1,Y1)|Resto], Creencias) :-
    seguro(X1,Y1),
    marcar_seguras(Resto, Creencias).

% Verificar si una casilla tiene brisa en vecinos visitados
brisa_en_vecino(X,Y) :-
    adyacente(X,Y,X1,Y1),
    visitado(X1,Y1),
    brisa(X1,Y1).

% --- Registro en base de conocimientos
actualizar_bc(Pos, Percepciones, Creencias, Accion, Resultado) :-
    assertz(bc((Pos, Percepciones, Creencias, Accion, Resultado))).

% --- Mostrar el mundo visualmente
mostrar_mundo :-
    nl, write('=== ESTADO DEL MUNDO ==='), nl,
    write('O=Oro, W=Wumpus, P=Pozo, A=Agente, .=Vacio, X=Visitado'), nl, nl,
    mostrar_fila(4),
    mostrar_fila(3), 
    mostrar_fila(2),
    mostrar_fila(1),
    nl.

mostrar_fila(Y) :-
    write(Y), write(' |'),
    mostrar_casilla(1,Y),
    mostrar_casilla(2,Y),
    mostrar_casilla(3,Y), 
    mostrar_casilla(4,Y),
    write('|'), nl.

mostrar_casilla(X,Y) :-
    write(' '),
    ( oro(X,Y) -> write('O')
    ; wumpus(X,Y) -> write('W') 
    ; pozo(X,Y) -> write('P')
    ; (X=1, Y=1) -> write('A')
    ; visitado(X,Y) -> write('X')
    ; write('.')
    ),
    write(' ').

% --- Mostrar percepciones en matriz
mostrar_percepciones :-
    nl, write('=== PERCEPCIONES ==='), nl,
    write('B=Brisa, H=Hedor, G=Brillo, .=Nada'), nl, nl,
    mostrar_fila_percepciones(4),
    mostrar_fila_percepciones(3),
    mostrar_fila_percepciones(2), 
    mostrar_fila_percepciones(1),
    nl.

mostrar_fila_percepciones(Y) :-
    write(Y), write(' |'),
    mostrar_percepciones_casilla(1,Y),
    mostrar_percepciones_casilla(2,Y),
    mostrar_percepciones_casilla(3,Y),
    mostrar_percepciones_casilla(4,Y),
    write('|'), nl.

mostrar_percepciones_casilla(X,Y) :-
    ( visitado(X,Y) ->
        ( brisa(X,Y) -> write(' B')
        ; hedor(X,Y) -> write(' H') 
        ; brillo(X,Y) -> write(' G')
        ; write(' .')
        )
    ;
        write(' ?')
    ),
    write(' ').

% --- Exploración de casillas marcadas como seguras (mejorada)
explorar_seguro(X,Y) :-
    % Primero buscar adyacentes seguras
    findall((X1,Y1), (adyacente(X,Y,X1,Y1), seguro(X1,Y1), \+ visitado(X1,Y1)), Adyacentes),
    ( Adyacentes \= [] ->
        explorar_casillas(Adyacentes)
    ;
        % Buscar cualquier casilla segura no visitada
        buscar_no_visitado_seguro(Todas),
        ( Todas \= [] ->
            explorar_casillas(Todas)
        ;
            % Si no hay seguras, buscar casillas no exploradas sin peligros conocidos
            buscar_casillas_arriesgadas(Arriesgadas),
            ( Arriesgadas \= [] ->
                write('Tomando riesgo calculado...'), nl,
                explorar_casillas(Arriesgadas)
            ;
                write('No hay más movimientos posibles. El agente se detiene.'), nl
            )
        )
    ).

% Buscar casillas seguras no visitadas
buscar_no_visitado_seguro(Mas) :-
    findall((X,Y), (seguro(X,Y), \+ visitado(X,Y)), Mas).

% Buscar casillas arriesgadas pero posibles
buscar_casillas_arriesgadas(Casillas) :-
    findall((X,Y), (
        between(1,4,X), between(1,4,Y),
        \+ visitado(X,Y),
        \+ peligroso(X,Y),
        adyacente_a_visitada(X,Y)
    ), Casillas).

% Verificar si es adyacente a una casilla visitada
adyacente_a_visitada(X,Y) :-
    adyacente(X,Y,X1,Y1),
    visitado(X1,Y1).

% --- Recorrido por la lista de casillas
explorar_casillas([]).
explorar_casillas([(X,Y)|Resto]) :-
    % Solo explorar si no ha sido visitada
    ( visitado(X,Y) ->
        explorar_casillas(Resto)
    ;
        explorar(X,Y),
        % Si encontró oro, terminar
        (oro(X,Y) -> true ; explorar_casillas(Resto))
    ).