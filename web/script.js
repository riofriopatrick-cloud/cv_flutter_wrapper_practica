(function () {
  "use strict";

  var raiz = document.documentElement;
  var btnTema = document.getElementById("btnTema");

  /* ---------- Tema claro / oscuro ----------
     setTheme() es global para que la app Flutter pueda llamarla
     con runJavaScript("setTheme('dark')"). */
  function setTheme(tema) {
    raiz.setAttribute("data-theme", tema);
    btnTema.textContent = tema === "dark" ? "Tema claro" : "Tema oscuro";
    try { localStorage.setItem("tema", tema); } catch (e) { /* sin almacenamiento */ }
  }
  window.setTheme = setTheme;

  var guardado = null;
  try { guardado = localStorage.getItem("tema"); } catch (e) { /* ignorar */ }
  var inicial = guardado ||
    (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  setTheme(inicial);

  btnTema.addEventListener("click", function () {
    var nuevo = raiz.getAttribute("data-theme") === "dark" ? "light" : "dark";
    setTheme(nuevo);
    // Si la página corre dentro de Flutter, avisa al lado nativo.
    if (window.FlutterTema && typeof window.FlutterTema.postMessage === "function") {
      window.FlutterTema.postMessage(nuevo);
    }
  });

  /* ---------- Acordeón de experiencia ---------- */
  document.querySelectorAll(".acordeon").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var abierto = btn.getAttribute("aria-expanded") === "true";
      var panel = document.getElementById(btn.getAttribute("aria-controls"));
      btn.setAttribute("aria-expanded", String(!abierto));
      panel.hidden = abierto;
    });
  });

  /* ---------- Filtro de habilidades ---------- */
  var filtros = document.querySelectorAll(".filtro");
  var habilidades = document.querySelectorAll("#listaHabilidades li");

  filtros.forEach(function (btn) {
    btn.addEventListener("click", function () {
      var categoria = btn.getAttribute("data-filtro");
      filtros.forEach(function (f) {
        var activo = f === btn;
        f.classList.toggle("activo", activo);
        f.setAttribute("aria-pressed", String(activo));
      });
      habilidades.forEach(function (li) {
        li.hidden = categoria !== "todas" && li.getAttribute("data-cat") !== categoria;
      });
    });
  });

  /* ---------- Validación del formulario de contacto ---------- */
  var form = document.getElementById("formContacto");
  var exito = document.getElementById("exito");

  function mostrarError(id, mensaje) {
    var campo = document.getElementById(id);
    document.getElementById("e-" + id).textContent = mensaje;
    campo.classList.toggle("invalido", mensaje !== "");
    campo.setAttribute("aria-invalid", mensaje !== "" ? "true" : "false");
    return mensaje === "";
  }

  function validar() {
    var nombre = form.nombre.value.trim();
    var correo = form.correo.value.trim();
    var mensaje = form.mensaje.value.trim();
    var correoValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo);

    var okNombre = mostrarError("nombre", nombre.length >= 3 ? "" : "Escribe tu nombre (mínimo 3 letras).");
    var okCorreo = mostrarError("correo", correoValido ? "" : "Escribe un correo válido, por ejemplo nombre@dominio.com.");
    var okMensaje = mostrarError("mensaje", mensaje.length >= 10 ? "" : "El mensaje debe tener al menos 10 caracteres.");
    return okNombre && okCorreo && okMensaje;
  }

  form.addEventListener("submit", function (evento) {
    evento.preventDefault();
    exito.hidden = true;
    if (validar()) {
      exito.textContent = "Mensaje enviado. Gracias, " + form.nombre.value.trim() + ".";
      exito.hidden = false;
      form.reset();
    }
  });

  ["nombre", "correo", "mensaje"].forEach(function (id) {
    document.getElementById(id).addEventListener("input", function () {
      if (document.getElementById("e-" + id).textContent) { validar(); }
    });
  });
})();
