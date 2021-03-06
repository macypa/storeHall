const path = require('path');
const glob = require('glob');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const minifyJsPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const globImporter = require('node-sass-glob-importer');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new minifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
    'app': ['./js/app.js'].concat(glob.sync('./vendor/**/*.js'))
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.(sa|sc|c)ss$/,
        use: [
          MiniCssExtractPlugin.loader,
          "css-loader",
          {
            loader: 'postcss-loader',
            options: {
              plugins: () => [require('autoprefixer')({
                // 'grid': "autoplace"
              })],
            }
          },
          {
            loader: "sass-loader",
            options: {
              sassOptions: {
                importer: globImporter()
              }
            }
          }
        ]
      },
      {
        test: /\.(png|eot|svg|ttf|woff|woff2)$/,
        exclude: /node_modules/,
        use: [{
          loader: 'file-loader',
          options: {
            outputPath: '../css/'
          }
        }],
      },
      {
        test: /\.hbs$/,
        exclude: /node_modules/,
        loader: "handlebars-loader"
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      jquery: "jquery",
      "window.jQuery": "jquery",
      "window.jquery": "jquery",
      "window.$": "jquery"
    })
  ]
});
