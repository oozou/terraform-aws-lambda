var http = require('http')

exports.handler = (event, context, callback) => {
  const options = {
    hostname: event.Host,
    port: event.Port
  }

  const response = {};

  http.get(options, (res) => {
    response.httpStatus = res.statusCode
    callback(null, response)
  }).on('error', (err) => {
    callback(null, err.message);
  })

};
