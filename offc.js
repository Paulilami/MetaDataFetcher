const { Requester, Validator } = require('@chainlink/external-adapter');
const crypto = require('crypto');
const axios = require('axios');

const createRequest = async (input, callback) => {
  const url = input.data.get;
  const queryKey = input.data.queryKey || "";

  if (!url) {
    return callback(400, { error: 'URL not provided' });
  }

  try {
    const response = await axios.get(url);
    const data = response.data;
    const flattenedData = flattenJSON(data);

    const keys = Object.keys(flattenedData);
    const values = Object.values(flattenedData).map(value => {
      if (typeof value === 'object' || isEncrypted(value)) {
        return hashData(JSON.stringify(value));
      }
      return value;
    });

    if (queryKey) {
      const filteredData = filterDataByKey(flattenedData, queryKey);
      const filteredKeys = Object.keys(filteredData);
      const filteredValues = Object.values(filteredData).map(value => {
        if (typeof value === 'object' || isEncrypted(value)) {
          return hashData(JSON.stringify(value));
        }
        return value;
      });

      return callback(200, {
        jobRunID: input.id,
        data: { keys: filteredKeys, values: filteredValues },
        result: filteredData
      });
    }

    callback(200, {
      jobRunID: input.id,
      data: { keys, values },
      result: flattenedData
    });
  } catch (error) {
    callback(500, Requester.errored(input.id, error));
  }
};

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

const isEncrypted = (value) => {
  //...current placeholder -Paul
  return false;
};

const hashData = (data) => {
  return crypto.createHash('sha256').update(data).digest('hex');
};

const filterDataByKey = (data, queryKey) => {
  const result = {};
  for (const key in data) {
    if (key.includes(queryKey)) {
      result[key] = data[key];
    }
  }
  return result;
};

module.exports.createRequest = createRequest;
module.exports.flattenJSON = flattenJSON;
module.exports.hashData = hashData;
module.exports.filterDataByKey = filterDataByKey;
module.exports.isEncrypted = isEncrypted;

