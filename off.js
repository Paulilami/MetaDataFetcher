const { Requester, Validator } = require('@chainlink/external-adapter');

const createRequest = (input, callback) => {
  const url = input.data.get;

  Requester.request({ url }, (error, response, body) => {
    if (error) {
      callback(500, Requester.errored(jobRunID, error));
    } else {
      const data = JSON.parse(body);
      const flattened = flattenJSON(data);

      callback(200, {
        jobRunID: input.id,
        data: {
          keys: Object.keys(flattened),
          values: Object.values(flattened)
        }
      });
    }
  });
};

const flattenJSON = (data) => {
  const result = {};

  const recurse = (cur, prop) => {
    if (Object(cur) !== cur) {
      result[prop] = cur;
    } else if (Array.isArray(cur)) {
      for (let i = 0, l = cur.length; i < l; i++)
        recurse(cur[i], prop + '[' + i + ']');
      if (l == 0)
        result[prop] = [];
    } else {
      let isEmpty = true;
      for (const p in cur) {
        isEmpty = false;
        recurse(cur[p], prop ? prop + '.' + p : p);
      }
      if (isEmpty && prop)
        result[prop] = {};
    }
  };

  recurse(data, '');
  return result;
};

module.exports.createRequest = createRequest;
