const { Requester, Validator } = require('@chainlink/external-adapter');

const createRequest = (input, callback) => {
  // Validate input
  const url = input.data.get;
  if (!url) {
    return callback(400, { error: 'URL not provided' });
  }

  // Define request options
  const options = {
    method: 'GET',
    url: url,
    headers: {
      'Content-Type': 'application/json'
    }
  };

  // Perform the request
  Requester.request(options, (error, response, body) => {
    if (error) {
      return callback(500, Requester.errored(input.id, error));
    } 

    try {
      const data = JSON.parse(body);
      const flattened = flattenJSON(data);
      
      callback(200, {
        jobRunID: input.id,
        data: {
          keys: Object.keys(flattened),
          values: Object.values(flattened)
        },
        result: flattened
      });
    } catch (parseError) {
      callback(500, { error: 'Failed to parse JSON', details: parseError });
    }
  });
};

// Helper function to flatten JSON objects
const flattenJSON = (data) => {
  const result = {};

  const recurse = (cur, prop) => {
    if (Object(cur) !== cur) {
      result[prop] = cur;
    } else if (Array.isArray(cur)) {
      for (let i = 0, l = cur.length; i < l; i++)
        recurse(cur[i], prop ? `${prop}[${i}]` : `${i}`);
      if (l == 0)
        result[prop] = [];
    } else {
      let isEmpty = true;
      for (const p in cur) {
        isEmpty = false;
        recurse(cur[p], prop ? `${prop}.${p}` : p);
      }
      if (isEmpty && prop)
        result[prop] = {};
    }
  };

  recurse(data, '');
  return result;
};

// Export the function for use by the Chainlink node
module.exports.createRequest = createRequest;

// Exports for testing
module.exports.flattenJSON = flattenJSON;
