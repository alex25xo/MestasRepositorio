  const jugador = "X";
  const ia = "O";
  let estadoJuego = Array(9).fill("");
  let juegoTerminado = false;
  let puntuacion = {
    jugador: 0,
    ia: 0,
    empates: 0
  };

  const tablero = document.getElementById("tablero");
  const statusEl = document.getElementById("status");

  function renderizarTablero() {
    tablero.innerHTML = "";
    estadoJuego.forEach((val, i) => {
      const btn = document.createElement("button");
      btn.className = `casilla ${val.toLowerCase()}`;
      btn.textContent = val;
      btn.disabled = val !== "" || juegoTerminado;
      btn.onclick = () => manejarJugada(i);
      tablero.appendChild(btn);
    });
  }

  function manejarJugada(index) {
    if (estadoJuego[index] !== "" || juegoTerminado) return;
    
    // Jugada del jugador
    estadoJuego[index] = jugador;
    renderizarTablero();
    
    let resultado = evaluarJuego(estadoJuego);
    if (resultado !== null) {
      terminarJuego(resultado);
      return;
    }
    
    statusEl.textContent = "IA está pensando...";
    
    // Jugada de la IA con delay para mejor UX
    setTimeout(() => {
      const mejorJugada = minimax(estadoJuego, 0, true);
      estadoJuego[mejorJugada.index] = ia;
      renderizarTablero();
      
      resultado = evaluarJuego(estadoJuego);
      if (resultado !== null) {
        terminarJuego(resultado);
      } else {
        statusEl.textContent = "Tu turno - Juegas con X";
      }
      
      // Generar árbol después de cada jugada
      generarArbolAutomatico();
    }, 500);
  }

  function minimax(board, depth, isMaximizing) {
    const resultado = evaluarJuego(board);
    
    if (resultado !== null) {
      return { score: resultado };
    }
    
    const jugadasDisponibles = [];
    for (let i = 0; i < 9; i++) {
      if (board[i] === "") {
        jugadasDisponibles.push(i);
      }
    }
    
    if (isMaximizing) {
      let mejorScore = -Infinity;
      let mejorJugada = null;
      
      for (let i of jugadasDisponibles) {
        board[i] = ia;
        const score = minimax(board, depth + 1, false).score;
        board[i] = "";
        
        if (score > mejorScore) {
          mejorScore = score;
          mejorJugada = i;
        }
      }
      
      return { score: mejorScore, index: mejorJugada };
    } else {
      let mejorScore = Infinity;
      let mejorJugada = null;
      
      for (let i of jugadasDisponibles) {
        board[i] = jugador;
        const score = minimax(board, depth + 1, true).score;
        board[i] = "";
        
        if (score < mejorScore) {
          mejorScore = score;
          mejorJugada = i;
        }
      }
      
      return { score: mejorScore, index: mejorJugada };
    }
  }

  function evaluarJuego(board) {
    const lineasGanadoras = [
      [0,1,2], [3,4,5], [6,7,8], // Horizontales
      [0,3,6], [1,4,7], [2,5,8], // Verticales
      [0,4,8], [2,4,6]           // Diagonales
    ];
    
    // Verificar si hay ganador
    for (let linea of lineasGanadoras) {
      if (linea.every(i => board[i] === ia)) return 1;  // IA gana
      if (linea.every(i => board[i] === jugador)) return -1; // Jugador gana
    }
    
    // Verificar empate
    if (board.every(casilla => casilla !== "")) return 0;
    
    // Juego continúa
    return null;
  }

  function terminarJuego(resultado) {
    juegoTerminado = true;
    
    if (resultado === 1) {
      statusEl.textContent = "🤖 ¡La IA gana!";
      puntuacion.ia++;
    } else if (resultado === -1) {
      statusEl.textContent = "🎉 ¡Ganaste!";
      puntuacion.jugador++;
    } else {
      statusEl.textContent = "🤝 ¡Empate!";
      puntuacion.empates++;
    }
    
    actualizarPuntuacion();
  }

  function actualizarPuntuacion() {
    document.getElementById("playerScore").textContent = puntuacion.jugador;
    document.getElementById("aiScore").textContent = puntuacion.ia;
    document.getElementById("tieScore").textContent = puntuacion.empates;
  }

  function reiniciarJuego() {
    estadoJuego = Array(9).fill("");
    juegoTerminado = false;
    statusEl.textContent = "Tu turno - Juegas con X";
    renderizarTablero();
    generarArbolAutomatico();
  }

  function reiniciarPuntuacion() {
    puntuacion = { jugador: 0, ia: 0, empates: 0 };
    actualizarPuntuacion();
  }

  function generarArbolAutomatico() {
    const treeData = construirArbolCompleto(estadoJuego.slice(), 0, true);
    mostrarArbol(treeData);
  }

  let nodoId = 0;
  function construirArbolCompleto(board, depth, isMaximizing) {
    const nodo = {
      id: nodoId++,
      board: board.slice(),
      hijos: [],
      score: evaluarJuego(board),
      depth,
      isMaximizing
    };

    // Limitar profundidad para mejor visualización
    if (nodo.score !== null || depth >= 3) {
      return nodo;
    }

    let mejorScore = isMaximizing ? -Infinity : Infinity;
    let mejorHijo = null;

    for (let i = 0; i < 9; i++) {
      if (board[i] === "") {
        board[i] = isMaximizing ? ia : jugador;
        const hijo = construirArbolCompleto(board, depth + 1, !isMaximizing);
        nodo.hijos.push(hijo);
        board[i] = "";

        // Determinar mejor jugada
        if (isMaximizing && hijo.score > mejorScore) {
          mejorScore = hijo.score;
          mejorHijo = hijo;
        } else if (!isMaximizing && hijo.score < mejorScore) {
          mejorScore = hijo.score;
          mejorHijo = hijo;
        }
      }
    }

    // Marcar mejor jugada
    if (mejorHijo) {
      mejorHijo.esMejorJugada = true;
    }

    return nodo;
  }

  function mostrarArbol(root) {
    const niveles = {};
    
    function recorrerNodos(nodo) {
      if (!niveles[nodo.depth]) niveles[nodo.depth] = [];
      niveles[nodo.depth].push(nodo);
      nodo.hijos.forEach(hijo => recorrerNodos(hijo));
    }
    
    recorrerNodos(root);

    const treeDiv = document.getElementById("tree");
    treeDiv.innerHTML = "";

    Object.keys(niveles).forEach(profundidad => {
      // Etiqueta del nivel
      const labelDiv = document.createElement("div");
      labelDiv.className = "nivel-label";
      labelDiv.textContent = `Nivel ${profundidad} - ${profundidad % 2 === 0 ? 'Turno IA' : 'Turno Jugador'}`;
      treeDiv.appendChild(labelDiv);

      const nivelDiv = document.createElement("div");
      nivelDiv.className = "nivel";
      
      niveles[profundidad].forEach(nodo => {
        const nodoDiv = document.createElement("div");
        nodoDiv.className = `nodo profundidad-${nodo.depth}`;
        
        if (nodo.esMejorJugada) {
          nodoDiv.classList.add("mejor-jugada");
        }

        const grid = document.createElement("div");
        grid.className = "grid";
        
        nodo.board.forEach(casilla => {
          const celda = document.createElement("div");
          celda.className = `celda ${casilla.toLowerCase()}`;
          celda.textContent = casilla || "";
          grid.appendChild(celda);
        });

        const info = document.createElement("div");
        info.className = "info";
        
        let scoreText = nodo.score !== null ? nodo.score : "...";
        let statusText = nodo.esMejorJugada ? "⭐ MEJOR" : "";
        
        info.innerHTML = `
          ID: ${nodo.id}<br>
          Score: ${scoreText}<br>
          ${statusText}
        `;

        nodoDiv.appendChild(grid);
        nodoDiv.appendChild(info);
        nivelDiv.appendChild(nodoDiv);
      });
      
      treeDiv.appendChild(nivelDiv);
    });
  }

  // Inicializar el juego
  renderizarTablero();
  actualizarPuntuacion();
  generarArbolAutomatico();