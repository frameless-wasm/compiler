/// <reference types="cypress" />
const util = require('util');
const exec = util.promisify(require('child_process').exec);

const fileRegex = /\.sly$/

function strictlyPlugin() {
  return {
    name: 'strictly',

    async transform(_src, id) {
      if (fileRegex.test(id)) {

        const { stdout, stderror } = await exec(`cabal v2-run --verbose=silent strictly-compiler ${id}`);
        if (stderror) {
          throw stderror;
        }

        return {
          code: stdout,
          map: null // provide source map if available
        }
      }
    }
  }
}

module.exports = (on, config) => {
  if (config.testingType === 'component') {
    const { startDevServer } = require('@cypress/vite-dev-server')

    on('dev-server:start', (options) =>
      startDevServer({ options, viteConfig: { plugins: [strictlyPlugin()] } })
    )
  }

  return config
}
