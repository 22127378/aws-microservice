import React, { useState, useEffect } from "react";
import axios from "axios";
import "bootstrap/dist/css/bootstrap.min.css";

const API_URL = "/api/tasks";

const MOCK_DATA = [
  {
    ID: 1,
    Name: "Frontend React ",
    Description: "Done UI for Task App using Bootstrap 5",
    DueDate: "2024-05-20T00:00:00.000Z",
    Status: "Completed"
  },
  {
    ID: 2,
    Name: "Backend API",
    Description: "Done API with Node.js and Express",
    DueDate: "2024-05-25T00:00:00.000Z",
    Status: "In Progress"
  },
  {
    ID: 3,
    Name: "Dockerize App",
    Description: "Create Dockerfile and docker-compose for the app",
    DueDate: "2024-06-01T00:00:00.000Z",
    Status: "Pending"
  }
];

function App() {
  // 2. Khởi tạo state với dữ liệu mẫu
  const [Tasks, setTasks] = useState(MOCK_DATA);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [status, setStatus] = useState("Pending");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [editMode, setEditMode] = useState(false);
  const [editTaskID, setEditTaskID] = useState(null);

  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    try {
      setLoading(true);
      const response = await axios.get(API_URL);
      if (response.data && response.data.length > 0) {
        setTasks(response.data);
      }
    } catch (err) {
      console.log("Sử dụng dữ liệu mẫu vì không kết nối được API.");
    } finally {
      setLoading(false);
    }
  };

  const addTask = async () => {
    if (!name.trim()) return;
    try {
      setLoading(true);
      const newTask = {
        ID: Math.floor(Math.random() * 1000),
        Name: name,
        Description: description,
        DueDate: dueDate,
        Status: status
      };
      const response = await axios.post(API_URL, newTask);
      setTasks([...Tasks, response.data]);
      resetForm();
    } catch (err) {
      setError("Không thể thêm task!");
    } finally {
      setLoading(false);
    }
  };

  const updateTask = async () => {
    if (!name.trim() || !editTaskID) return;
    try {
      setLoading(true);
      const updatedTask = {
        Name: name,
        Description: description,
        DueDate: dueDate,
        Status: status
      };
      const response = await axios.put(`${API_URL}/${editTaskID}`, updatedTask);
      const updatedTasks = Tasks.map(task =>
        task.ID === editTaskID ? response.data : task
      );
      setTasks(updatedTasks);
      resetForm();
      setEditMode(false);
      setEditTaskID(null);
    } catch (err) {
      setError("Không thể cập nhật!");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (editMode) {
      updateTask();
    } else {
      addTask();
    }
  };

  const resetForm = () => {
    setName("");
    setDescription("");
    setDueDate("");
    setStatus("Pending");
  };

  const editTask = (task) => {
    setName(task.Name);
    setDescription(task.Description || "");
    setDueDate(task.DueDate ? task.DueDate.split('T')[0] : "");
    setStatus(task.Status);
    setEditMode(true);
    setEditTaskID(task.ID);
  };

  const cancelEdit = () => {
    resetForm();
    setEditMode(false);
    setEditTaskID(null);
  };

  const deleteTask = async (taskID) => {
    // Filter local trước để UI mượt mà
    setTasks(Tasks.filter(task => task.ID !== taskID));
    try {
      await axios.delete(`${API_URL}/${taskID}`);
    } catch (err) {
      console.error("Lỗi xóa trên server, nhưng UI đã cập nhật.");
    }
  };

  const getStatusClass = (status) => {
    const classes = {
      "Pending": "badge bg-secondary",
      "In Progress": "badge bg-primary",
      "Completed": "badge bg-success"
    };
    return classes[status] || "badge bg-secondary";
  };

  return (
    <div className="task-manager bg-light min-vh-100">
      <div className="container py-5">
        <div className="card shadow-sm">
          <div className="card-header bg-primary text-white">
            <h2 className="mb-0 h4">Quản lý công việc</h2>
          </div>
          
          <div className="card-body">
            <form onSubmit={handleSubmit} className="mb-4">
              <div className="row g-3">
                <div className="col-md-3">
                  <label className="form-label small fw-bold">Tên task</label>
                  <input type="text" className="form-control" value={name} onChange={(e) => setName(e.target.value)} required />
                </div>
                <div className="col-md-3">
                  <label className="form-label small fw-bold">Mô tả</label>
                  <input type="text" className="form-control" value={description} onChange={(e) => setDescription(e.target.value)} />
                </div>
                <div className="col-md-2">
                  <label className="form-label small fw-bold">Hạn chót</label>
                  <input type="date" className="form-control" value={dueDate} onChange={(e) => setDueDate(e.target.value)} />
                </div>
                <div className="col-md-2">
                  <label className="form-label small fw-bold">Trạng thái</label>
                  <select className="form-select" value={status} onChange={(e) => setStatus(e.target.value)}>
                    <option value="Pending">Pending</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Completed">Completed</option>
                  </select>
                </div>
                <div className="col-md-2 d-flex align-items-end gap-2">
                  <button type="submit" className={`btn ${editMode ? 'btn-success' : 'btn-primary'} w-100`}>
                    {editMode ? 'Lưu' : 'Thêm'}
                  </button>
                  {editMode && <button type="button" className="btn btn-outline-secondary" onClick={cancelEdit}>Hủy</button>}
                </div>
              </div>
            </form>

            <hr />

            <div className="table-responsive">
              <table className="table table-hover align-middle">
                <thead className="table-light">
                  <tr>
                    <th>ID</th>
                    <th>Công việc</th>
                    <th>Hạn chót</th>
                    <th>Trạng thái</th>
                    <th className="text-end">Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  {Tasks.map((task) => (
                    <tr key={task.ID}>
                      <td><span className="text-muted small">#{task.ID}</span></td>
                      <td>
                        <div className="fw-bold">{task.Name}</div>
                        <div className="small text-muted">{task.Description}</div>
                      </td>
                      <td>{task.DueDate ? new Date(task.DueDate).toLocaleDateString('vi-VN') : '-'}</td>
                      <td><span className={getStatusClass(task.Status)}>{task.Status}</span></td>
                      <td className="text-end">
                        <button className="btn btn-sm btn-outline-warning me-2" onClick={() => editTask(task)}>Sửa</button>
                        <button className="btn btn-sm btn-outline-danger" onClick={() => deleteTask(task.ID)}>Xóa</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;