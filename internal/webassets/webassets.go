// Package webassets embebe los archivos estáticos del cliente web dentro del
// binario, de modo que el servidor no dependa de rutas en disco, permisos ni
// working directory.
//
// El contenido de la carpeta ./dist se rellena en tiempo de build (por el
// Makefile / Dockerfile) copiando ahí el resultado de `npm run build` del
// web-client ANTES de ejecutar `go build`.
//
// Si ./dist está vacío (solo con el .gitkeep), el embed sigue compilando pero
// no habrá panel; por eso el build debe garantizar que los assets están aquí.
package webassets

import (
        "embed"
        "io/fs"
)

//go:embed all:dist
var embedded embed.FS

// FS devuelve el sub-filesystem con la raíz en "dist", listo para servir.
// Si por alguna razón el subdirectorio no existe, devuelve error para que el
// servidor pueda avisar y continuar sin panel.
func FS() (fs.FS, error) {
        return fs.Sub(embedded, "dist")
}

// HasAssets indica si realmente se embebió contenido (más que el placeholder).
func HasAssets() bool {
        sub, err := fs.Sub(embedded, "dist")
        if err != nil {
                return false
        }
        // Consideramos que hay assets si existe index.html
        if _, err := fs.Stat(sub, "index.html"); err == nil {
                return true
        }
        return false
}
