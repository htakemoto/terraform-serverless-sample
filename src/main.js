const moment = require("moment");

exports.handler = function (event, context, callback) {
  const payload = {
    message: 'Hello world!!',
    currentTime: moment().format()
  }
  const response = {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  }
  callback(null, response)
}