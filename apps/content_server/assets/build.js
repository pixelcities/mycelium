'use-strict'

const path = require('path')
const fs = require('fs')
const esbuild = require('esbuild')
const wasm = require('esbuild-plugin-wasm')

const args = process.argv.slice(2)
const watch = args.includes('--watch')
const deploy = args.includes('--deploy')

const loader = {}
const plugins = [
  wasm.wasmLoader({
    mode: 'embedded'
  })
]

let opts = {
  entryPoints: [
    'js/app.js',
    'js/vendor.js',
    'js/worker.js'
  ],
  bundle: true,
  target: 'esnext',
  format: 'esm',
  outdir: '../priv/static/assets',
  logLevel: 'info',
  loader,
  plugins
}

if (watch) {
  opts = {
    ...opts,
    watch,
    sourcemap: 'inline'
  }
}

if (deploy) {
  opts = {
    ...opts,
    minify: true
  }
}

const promise = esbuild.build(opts)

if (watch) {
  promise.then(_result => {
    process.stdin.on('close', () => {
      process.exit(0)
    })

    process.stdin.resume()
  })
}
