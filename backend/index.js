const express = require("express");
const cors = require("cors");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand, PutCommand, UpdateCommand, DeleteCommand } = require("@aws-sdk/lib-dynamodb");
require("dotenv").config();

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

const region = process.env.AWS_REGION || "ap-southeast-1";
const tableName = process.env.DYNAMODB_TABLE_NAME || "shop-microservice-tasks";

// Khởi tạo DynamoDB client
const client = new DynamoDBClient({ region });
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Health check route cho ALB
app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", timestamp: new Date() });
});

// GET /tasks: Lấy toàn bộ danh sách task
app.get("/tasks", async (req, res) => {
  try {
    const params = {
      TableName: tableName,
    };
    const data = await ddbDocClient.send(new ScanCommand(params));
    const items = data.Items || [];
    res.json(items);
  } catch (error) {
    console.error("Error fetching tasks:", error);
    res.status(500).json({ error: "Could not fetch tasks", details: error.message });
  }
});

// POST /tasks: Thêm mới task
app.post("/tasks", async (req, res) => {
  const { ID, Name, Description, DueDate, Status } = req.body;
  if (!Name) {
    return res.status(400).json({ error: "Name is required" });
  }
  
  const item = {
    ID: Number(ID) || Math.floor(Math.random() * 10000),
    Name,
    Description: Description || "",
    DueDate: DueDate || "",
    Status: Status || "Pending",
    CreatedAt: new Date().toISOString()
  };

  try {
    const params = {
      TableName: tableName,
      Item: item,
    };
    await ddbDocClient.send(new PutCommand(params));
    res.status(201).json(item);
  } catch (error) {
    console.error("Error creating task:", error);
    res.status(500).json({ error: "Could not create task", details: error.message });
  }
});

// PUT /tasks/:id: Cập nhật task
app.put("/tasks/:id", async (req, res) => {
  const id = Number(req.params.id);
  const { Name, Description, DueDate, Status } = req.body;
  
  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid task ID" });
  }

  try {
    const params = {
      TableName: tableName,
      Key: { ID: id },
      UpdateExpression: "set #n = :name, #d = :desc, #dd = :due, #s = :status",
      ExpressionAttributeNames: {
        "#n": "Name",
        "#d": "Description",
        "#dd": "DueDate",
        "#s": "Status"
      },
      ExpressionAttributeValues: {
        ":name": Name,
        ":desc": Description || "",
        ":due": DueDate || "",
        ":status": Status || "Pending"
      },
      ReturnValues: "ALL_NEW"
    };

    const data = await ddbDocClient.send(new UpdateCommand(params));
    res.json(data.Attributes);
  } catch (error) {
    console.error("Error updating task:", error);
    res.status(500).json({ error: "Could not update task", details: error.message });
  }
});

// DELETE /tasks/:id: Xóa task
app.delete("/tasks/:id", async (req, res) => {
  const id = Number(req.params.id);
  
  if (isNaN(id)) {
    return res.status(400).json({ error: "Invalid task ID" });
  }

  try {
    const params = {
      TableName: tableName,
      Key: { ID: id }
    };
    await ddbDocClient.send(new DeleteCommand(params));
    res.json({ message: `Task with ID ${id} deleted successfully` });
  } catch (error) {
    console.error("Error deleting task:", error);
    res.status(500).json({ error: "Could not delete task", details: error.message });
  }
});

// Khởi chạy server
app.listen(port, () => {
  console.log(`Backend server is running on port ${port}`);
});
