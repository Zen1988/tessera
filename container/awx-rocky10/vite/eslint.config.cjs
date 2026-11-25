const { resolve } = require('node:path');
const globals = require('globals');
const { fixupPluginRules } = require('@eslint/compat');
const policy = require('./tao-eslint-policy.json');

// Keep the original rule IDs while passing resolver settings to import-x.
const settings = Object.fromEntries(
  Object.entries(policy.settings).map(([name, value]) => [
    name.replace(/^import\//, 'import-x/'),
    value,
  ])
);
const nodeResolver = policy.settings['import/resolver'].node;
settings['import-x/resolver'] = {
  node: {
    ...nodeResolver,
    paths: nodeResolver.paths.map(path => resolve(__dirname, path)),
  },
};

const pluginModules = {
  import: require('eslint-plugin-import'),
  react: require('eslint-plugin-react'),
  i18next: require('eslint-plugin-i18next'),
  'jsx-a11y': require('eslint-plugin-jsx-a11y'),
  'react-hooks': require('eslint-plugin-react-hooks'),
};

const plugins = Object.fromEntries(
  Object.entries(pluginModules).map(([name, module]) => {
    const plugin = module.rules ? module : module.default;
    if (!plugin?.rules) {
      throw new Error(`ESLint plugin ${name} did not export a rule map`);
    }
    return [name, fixupPluginRules(plugin)];
  })
);

module.exports = [
  { ignores: [
    '**/{node_modules,etc,coverage,build,dist,images,instrumented}/**',
    '**/jest.*.js', '**/webpack.*.js', '**/*test*.js',
  ] },
  {
    files: ['**/*.{js,jsx}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parserOptions: { ecmaFeatures: { jsx: true } },
      globals: { ...globals.browser, ...globals.node, ...globals.jest, ...policy.globals },
    },
    plugins,
    settings,
    rules: {
      ...policy.rules,
      // Vite's styled-components Babel plugin compiles this JSX prop.
      'react/no-unknown-property': [
        ...policy.rules['react/no-unknown-property'],
        { ignore: ['css'] },
      ],
    },
  },
];
