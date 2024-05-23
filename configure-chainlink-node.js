const axios = require("axios");

const chainlinkNodeUrl = "NODEURL"; 
const chainlinkNodeAuth = {
  username: "your-username", 
  password: "your-password" 
};

const jobSpec = {
  initiators: [
    {
      type: "web"
    }
  ],
  tasks: [
    {
      type: "httpget",
      params: {
        url: "http://external-adapter:8080" // Replace with your external adapter URL
      }
    },
    {
      type: "jsonparse",
      params: {
        path: "data"
      }
    },
    {
      type: "ethabidecodelog",
      params: {
        abi: "[{\"type\":\"function\",\"name\":\"fulfill\",\"inputs\":[{\"name\":\"_requestId\",\"type\":\"bytes32\"},{\"name\":\"_keys\",\"type\":\"bytes32[]\"},{\"name\":\"_values\",\"type\":\"bytes32[]\"}]}]"
      }
    },
    {
      type: "ethtx"
    }
  ]
};

async function configureChainlinkNode() {
  try {
    const response = await axios.post(
      `${chainlinkNodeUrl}/v2/specs`,
      jobSpec,
      {
        auth: chainlinkNodeAuth,
        headers: {
          "Content-Type": "application/json"
        }
      }
    );

    console.log("Job configured successfully:", response.data);
  } catch (error) {
    console.error("Error configuring job:", error);
  }
}

configureChainlinkNode();
