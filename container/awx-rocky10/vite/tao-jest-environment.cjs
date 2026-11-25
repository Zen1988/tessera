const environment = require('@jest/environment-jsdom-abstract');
const jsdom = require('jsdom');
const BaseEnvironment = environment.default ?? environment;

module.exports = class TaoJestEnvironment extends BaseEnvironment {
  constructor(config, context) {
    super(config, context, jsdom);
  }
};
